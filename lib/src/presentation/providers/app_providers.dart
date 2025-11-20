import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../domain/entities/voice_note.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/scheduled_task.dart';
import '../../core/constants/app_constants.dart';
import '../../data/datasources/hive_voice_note_datasource.dart';
import '../../data/datasources/hive_category_datasource.dart';
import '../../data/repositories/voice_note_repository.dart';
import '../../data/repositories/category_repository.dart';
import '../../application/services/audio_recorder_service.dart';
import '../../application/services/audio_recording_state.dart';
import '../../application/services/transcription_service.dart';
import '../../application/services/transcription_state.dart';
import '../../data/services/ollama_transcription_backend.dart';

// Hive providers
final hiveBoxProvider = Provider<Box<VoiceNote>>((ref) {
  return Hive.box<VoiceNote>(AppConstants.hiveBoxName);
});

final tasksBoxProvider = Provider<Box<ScheduledTask>>((ref) {
  return Hive.box<ScheduledTask>('tasks_box');
});

// Voice notes providers
final voiceNotesProvider = StateNotifierProvider<VoiceNotesNotifier, List<VoiceNote>>((ref) {
  final box = ref.watch(hiveBoxProvider);
  return VoiceNotesNotifier(box);
});

final voiceNoteProvider = Provider.family<VoiceNote?, String>((ref, id) {
  final voiceNotes = ref.watch(voiceNotesProvider);
  try {
    return voiceNotes.firstWhere((note) => note.id == id);
  } catch (e) {
    return null;
  }
});

// Tasks providers
final tasksProvider = StateNotifierProvider<TasksNotifier, List<ScheduledTask>>((ref) {
  final box = ref.watch(tasksBoxProvider);
  return TasksNotifier(box);
});

final taskProvider = Provider.family<ScheduledTask?, String>((ref, id) {
  final tasks = ref.watch(tasksProvider);
  try {
    return tasks.firstWhere((task) => task.id == id);
  } catch (e) {
    return null;
  }
});

// Notifiers
class VoiceNotesNotifier extends StateNotifier<List<VoiceNote>> {
  final Box<VoiceNote> _box;

  VoiceNotesNotifier(this._box) : super(_box.values.toList()) {
    _box.watch().listen((event) {
      state = _box.values.toList();
    });
  }

  Future<void> addVoiceNote(VoiceNote note) async {
    await _box.put(note.id, note);
  }

  Future<void> updateVoiceNote(VoiceNote note) async {
    await _box.put(note.id, note);
  }

  Future<void> deleteVoiceNote(String id) async {
    await _box.delete(id);
  }

  Future<VoiceNote?> getVoiceNote(String id) async {
    return _box.get(id);
  }
}

class TasksNotifier extends StateNotifier<List<ScheduledTask>> {
  final Box<ScheduledTask> _box;

  TasksNotifier(this._box) : super(_box.values.toList()) {
    _box.watch().listen((event) {
      state = _box.values.toList();
    });
  }

  Future<void> addTask(ScheduledTask task) async {
    await _box.put(task.id, task);
  }

  Future<void> updateTask(ScheduledTask task) async {
    await _box.put(task.id, task);
  }

  Future<void> deleteTask(String id) async {
    await _box.delete(id);
  }

  Future<ScheduledTask?> getTask(String id) async {
    return _box.get(id);
  }

  List<ScheduledTask> getTasksByStatus(TaskStatus status) {
    return state.where((task) => task.status == status).toList();
  }

  List<ScheduledTask> getUpcomingTasks() {
    final now = DateTime.now();
    return state
        .where((task) => 
            task.scheduledFor.isAfter(now) && 
            task.status != TaskStatus.completed && 
            task.status != TaskStatus.cancelled)
        .toList()
      ..sort((a, b) => a.scheduledFor.compareTo(b.scheduledFor));
  }
}

// Repository providers
final voiceNoteDatasourceProvider = Provider<VoiceNoteDatasource>((ref) {
  return HiveVoiceNoteDatasource();
});

final categoryDatasourceProvider = Provider<CategoryDatasource>((ref) {
  return HiveCategoryDatasource();
});

final voiceNoteRepositoryProvider = Provider<VoiceNoteRepository>((ref) {
  final datasource = ref.watch(voiceNoteDatasourceProvider);
  return VoiceNoteRepositoryImpl(datasource);
});

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  final datasource = ref.watch(categoryDatasourceProvider);
  return CategoryRepositoryImpl(datasource);
});

// Audio Recorder Service providers
final audioRecorderServiceProvider = Provider<AudioRecorderService>((ref) {
  final voiceNoteRepository = ref.watch(voiceNoteRepositoryProvider);
  final categoryRepository = ref.watch(categoryRepositoryProvider);
  
  final service = AudioRecorderServiceImpl(
    voiceNoteRepository: voiceNoteRepository,
    categoryRepository: categoryRepository,
  );
  
  ref.onDispose(service.dispose);
  return service;
});

final audioRecordingStateProvider = StreamProvider<AudioRecordingState>((ref) {
  final service = ref.watch(audioRecorderServiceProvider);
  return service.stateStream;
});

// Transcription Service providers
final transcriptionServiceProvider = Provider<TranscriptionService>((ref) {
  final backend = OllamaTranscriptionBackend();
  final service = TranscriptionServiceImpl(backend: backend);
  ref.onDispose(service.dispose);
  return service;
});

final transcriptionStateProvider = StreamProvider<TranscriptionProgress>((ref) {
  final service = ref.watch(transcriptionServiceProvider);
  service.ensureModelReady();
  return service.progressStream;
});
