import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:voice_note_scheduler/src/application/services/transcription_service.dart';
import 'package:voice_note_scheduler/src/application/services/transcription_state.dart';

import 'mock_transcription_backend.dart';

void main() {
  late Directory tempDir;
  late File tempFile;
  late TranscriptionServiceImpl service;
  late MockTranscriptionBackend backend;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('transcription_test');
    tempFile = File('${tempDir.path}/test_audio.m4a');
    await tempFile.writeAsBytes(List<int>.generate(2048, (index) => Random().nextInt(256)));

    backend = MockTranscriptionBackend();
    service = TranscriptionServiceImpl(backend: backend);
  });

  tearDown(() async {
    service.dispose();
    await backend.dispose();
    if (await tempFile.exists()) {
      await tempFile.delete();
    }
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('ensureModelReady downloads model when missing', () async {
    backend.setModelAvailable(false);

    await service.ensureModelReady();

    expect(service.currentProgress.status, equals(TranscriptionStatus.modelReady));
  });

  test('transcribe emits progress and completes with result', () async {
    backend.setMockChunks([
      BackendTranscriptionChunk(
        text: 'Partial text',
        isFinal: false,
        confidence: 0.5,
        metadata: {'progress': 0.5},
      ),
      BackendTranscriptionChunk(
        text: 'Final transcription text',
        isFinal: true,
        confidence: 0.93,
        metadata: {'progress': 1.0},
      ),
    ]);

    final progressUpdates = <TranscriptionProgress>[];
    final subscription = service.progressStream.listen(progressUpdates.add);

    final result = await service.transcribe(tempFile.path);

    await subscription.cancel();

    expect(result.text, equals('Final transcription text'));
    expect(result.confidence, equals(0.93));
    expect(progressUpdates.any((p) => p.partialText == 'Partial text'), isTrue);
    expect(progressUpdates.last.status, equals(TranscriptionStatus.completed));
    expect(progressUpdates.last.result, equals(result));
  });

  test('transcribe throws when file missing', () async {
    expect(() => service.transcribe('${tempDir.path}/missing.m4a'), throwsArgumentError);
  });

  test('transcription can be cancelled mid-stream', () async {
    backend.setMockChunks([
      BackendTranscriptionChunk(
        text: 'partial',
        isFinal: false,
        metadata: const {'progress': 0.2},
      ),
      BackendTranscriptionChunk(
        text: 'final',
        isFinal: true,
        metadata: const {'progress': 1.0},
      ),
    ]);

    final token = TranscriptionCancellationToken();

    final future = service.transcribe(tempFile.path, cancellationToken: token);

    await Future.delayed(const Duration(milliseconds: 50));
    await service.cancelCurrentTranscription();

    expect(future, throwsA(isA<StateError>()));
    expect(service.currentProgress.status, equals(TranscriptionStatus.cancelled));
  });

  test('transcription fails gracefully on backend error', () async {
    backend.setThrowOnTranscribe(true);

    expect(() => service.transcribe(tempFile.path), throwsA(isA<StateError>()));
    expect(service.currentProgress.status, equals(TranscriptionStatus.failed));
  });
}
