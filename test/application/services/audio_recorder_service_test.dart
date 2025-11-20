import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:voice_note_scheduler/src/application/services/audio_recorder_service.dart';
import 'package:voice_note_scheduler/src/application/services/audio_recording_state.dart';
import 'package:voice_note_scheduler/src/application/services/recorder.dart';
import 'package:voice_note_scheduler/src/data/repositories/category_repository.dart';
import 'package:voice_note_scheduler/src/data/repositories/voice_note_repository.dart';
import 'package:voice_note_scheduler/src/domain/entities/category.dart';
import 'package:voice_note_scheduler/src/domain/entities/voice_note.dart';

import 'fake_audio_recorder.dart';

void main() {
  late FakeAudioRecorder fakeRecorder;
  late StubVoiceNoteRepository voiceNoteRepository;
  late StubCategoryRepository categoryRepository;
  late TestableAudioRecorderService service;

  setUp(() {
    fakeRecorder = FakeAudioRecorder();
    voiceNoteRepository = StubVoiceNoteRepository();
    categoryRepository = StubCategoryRepository(
      Category(
        name: 'General',
        color: 0xFF2196F3,
        isDefault: true,
        createdAt: DateTime.now(),
      ),
    );

    service = TestableAudioRecorderService(
      recorder: fakeRecorder,
      voiceNoteRepository: voiceNoteRepository,
      categoryRepository: categoryRepository,
    );
  });

  tearDown(() {
    service.dispose();
    voiceNoteRepository.dispose();
  });

  group('AudioRecorderServiceImpl', () {
    test('startRecording should move state to recording', () async {
      await service.startRecording();

      expect(service.currentState.status, RecordingStatus.recording);
      expect(service.currentState.audioFilePath, isNotNull);
    });

    test('pause and resume should update status accordingly', () async {
      await service.startRecording();
      await service.pauseRecording();
      expect(service.currentState.status, RecordingStatus.paused);

      await service.resumeRecording();
      expect(service.currentState.status, RecordingStatus.recording);
    });

    test('stopRecording should return metadata with duration and size', () async {
      await service.startRecording();
      await Future.delayed(const Duration(milliseconds: 120));
      final metadata = await service.stopRecording();

      expect(metadata, isNotNull);
      expect(metadata!.duration.inMilliseconds, greaterThan(0));
      expect(metadata.fileSizeBytes, greaterThanOrEqualTo(0));
      expect(metadata.audioFilePath, service.currentState.audioFilePath);
      expect(service.currentState.status, RecordingStatus.stopped);
    });

    test('cancelRecording should delete file and reset state', () async {
      await service.startRecording();
      final path = service.currentState.audioFilePath;

      await service.cancelRecording();

      expect(service.currentState.status, RecordingStatus.idle);
      expect(service.currentState.audioFilePath, isNull);
      expect(voiceNoteRepository.deletedPaths.contains(path), isTrue);
    });

    test('elapsed time increments while recording and pauses when paused', () async {
      await service.startRecording();
      await Future.delayed(const Duration(milliseconds: 150));
      final elapsedWhileRecording = service.currentState.elapsedTime;
      expect(elapsedWhileRecording.inMilliseconds, greaterThan(0));

      await service.pauseRecording();
      final elapsedAtPause = service.currentState.elapsedTime;
      await Future.delayed(const Duration(milliseconds: 200));

      expect(service.currentState.elapsedTime, elapsedAtPause);
    });

    test('stopRecording from paused state uses accumulated duration', () async {
      await service.startRecording();
      await Future.delayed(const Duration(milliseconds: 80));
      await service.pauseRecording();
      await Future.delayed(const Duration(milliseconds: 120));
      final metadata = await service.stopRecording();

      expect(metadata, isNotNull);
      expect(metadata!.duration.inMilliseconds, greaterThan(40));
    });

    test('cannot start recording twice without stopping', () async {
      await service.startRecording();
      expect(service.startRecording, throwsA(isA<StateError>()));
    });

    test('permission denial surfaces readable error state', () async {
      service.hasPermission = false;
      service.requestPermissionResult = false;

      await service.startRecording();

      expect(service.currentState.status, RecordingStatus.permissionDenied);
      expect(service.currentState.errorMessage, isNotEmpty);
    });

    test('state stream emits updates for UI consumption', () async {
      final emittedStates = <RecordingStatus>[];
      final sub = service.stateStream.listen((state) {
        emittedStates.add(state.status);
      });

      await service.startRecording();
      await Future.delayed(const Duration(milliseconds: 50));
      await service.pauseRecording();
      await Future.delayed(const Duration(milliseconds: 50));
      await service.stopRecording();
      await Future.delayed(const Duration(milliseconds: 20));
      await sub.cancel();

      expect(emittedStates.first, RecordingStatus.idle);
      expect(emittedStates.contains(RecordingStatus.recording), isTrue);
      expect(emittedStates.contains(RecordingStatus.paused), isTrue);
      expect(emittedStates.last, RecordingStatus.stopped);
    });
  });

  group('AudioRecordingState', () {
    test('convenience getters reflect status correctly', () {
      const idleState = AudioRecordingState.initial();
      expect(idleState.isIdle, isTrue);
      expect(idleState.canRecord, isTrue);

      const recordingState = AudioRecordingState(
        status: RecordingStatus.recording,
        elapsedTime: Duration(seconds: 1),
      );
      expect(recordingState.isRecording, isTrue);
      expect(recordingState.canPause, isTrue);
    });

    test('copyWith and equality behave as expected', () {
      const base = AudioRecordingState.initial();
      final updated = base.copyWith(
        status: RecordingStatus.error,
        errorMessage: 'failure',
      );

      expect(updated.status, RecordingStatus.error);
      expect(updated.errorMessage, 'failure');
      expect(updated == base, isFalse);

      final clone = updated.copyWith();
      expect(clone, updated);
    });
  });

  group('RecordingMetadata', () {
    test('contains essential information', () {
      final timestamp = DateTime.now();
      final metadata = RecordingMetadata(
        audioFilePath: '/tmp/test.m4a',
        duration: const Duration(seconds: 3),
        fileSizeBytes: 2048,
        timestamp: timestamp,
      );

      expect(metadata.audioFilePath, '/tmp/test.m4a');
      expect(metadata.duration.inSeconds, 3);
      expect(metadata.fileSizeBytes, 2048);
      expect(metadata.timestamp, timestamp);
    });
  });
}

class TestableAudioRecorderService extends AudioRecorderServiceImpl {
  TestableAudioRecorderService({
    required Recorder recorder,
    required VoiceNoteRepository voiceNoteRepository,
    required CategoryRepository categoryRepository,
  }) : super(
          recorder: recorder,
          voiceNoteRepository: voiceNoteRepository,
          categoryRepository: categoryRepository,
        );

  bool hasPermission = true;
  bool requestPermissionResult = true;

  @override
  Future<bool> hasPermissions() async {
    return hasPermission;
  }

  @override
  Future<bool> requestPermissions() async {
    return requestPermissionResult;
  }
}

class StubVoiceNoteRepository implements VoiceNoteRepository {
  StubVoiceNoteRepository() {
    _root = Directory.systemTemp.createTempSync('audio_recorder_service_test');
  }

  late final Directory _root;
  final List<String> deletedPaths = [];

  void dispose() {
    if (_root.existsSync()) {
      _root.deleteSync(recursive: true);
    }
  }

  @override
  Future<String> generateAudioPath(String categoryId, {String? filename}) async {
    final safeName = filename ?? '${DateTime.now().millisecondsSinceEpoch}.m4a';
    final dir = Directory(p.join(_root.path, categoryId));
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    final filePath = p.join(dir.path, safeName);
    final file = File(filePath);
    if (!file.existsSync()) {
      await file.create(recursive: true);
    }
    return filePath;
  }

  @override
  Future<void> deleteAudioFile(String audioPath) async {
    deletedPaths.add(audioPath);
    final file = File(audioPath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  // The remaining repository methods are not needed for these tests.
  @override
  Future<void> createVoiceNote(VoiceNote voiceNote) =>
      throw UnimplementedError();
  @override
  Future<void> updateVoiceNote(VoiceNote voiceNote) =>
      throw UnimplementedError();
  @override
  Future<void> deleteVoiceNote(String id) => throw UnimplementedError();
  @override
  Future<VoiceNote?> getVoiceNoteById(String id) =>
      throw UnimplementedError();
  @override
  Future<List<VoiceNote>> getAllVoiceNotes() => throw UnimplementedError();
  @override
  Future<List<VoiceNote>> getVoiceNotesByCategory(String categoryId) =>
      throw UnimplementedError();
  @override
  Stream<List<VoiceNote>> watchAllVoiceNotes() => const Stream.empty();
  @override
  Stream<List<VoiceNote>> watchVoiceNotesByCategory(String categoryId) =>
      const Stream.empty();
  @override
  Future<void> moveAudioFile(String oldPath, String newPath) =>
      throw UnimplementedError();
}

class StubCategoryRepository implements CategoryRepository {
  StubCategoryRepository(this.defaultCategory);

  final Category defaultCategory;

  @override
  Future<Category> ensureDefaultCategory() async => defaultCategory;

  @override
  Future<Category?> getCategoryById(String id) async => defaultCategory;

  @override
  Future<Category?> getDefaultCategory() async => defaultCategory;

  @override
  Stream<List<Category>> watchAllCategories() => const Stream.empty();

  // Remaining methods are not required for these tests.
  @override
  Future<void> createCategory(Category category) =>
      throw UnimplementedError();
  @override
  Future<void> updateCategory(Category category) =>
      throw UnimplementedError();
  @override
  Future<void> deleteCategory(String id) => throw UnimplementedError();
  @override
  Future<List<Category>> getAllCategories() => throw UnimplementedError();
  @override
  Future<void> setDefaultCategory(String categoryId) =>
      throw UnimplementedError();
}
