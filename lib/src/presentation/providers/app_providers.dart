import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../domain/entities/voice_note.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/scheduled_task.dart';
import '../../core/constants/app_constants.dart';
import '../../data/datasources/hive_voice_note_datasource.dart';
import '../../data/datasources/hive_category_datasource.dart';
import '../../data/datasources/hive_scheduled_task_datasource.dart';
import '../../data/repositories/voice_note_repository.dart';
import '../../data/repositories/category_repository.dart';
import '../../data/repositories/scheduled_task_repository.dart';
import '../../application/repositories/voice_note_repository.dart' as app_repo;
import '../../application/repositories/category_repository.dart' as app_repo;
import '../../application/repositories/scheduled_task_repository.dart' as app_repo;
import '../../application/use_cases/create_voice_note_use_case.dart';
import '../../application/use_cases/transcribe_voice_note_use_case.dart';
import '../../application/use_cases/schedule_tasks_from_voice_note_use_case.dart';
import '../../application/services/audio_recorder_service.dart';
import '../../application/services/audio_recording_state.dart';
import '../../application/services/transcription_service.dart';
import '../../application/services/transcription_state.dart';
import '../../application/services/task_scheduling_service.dart';
import '../../data/services/ollama_transcription_backend.dart';

// Hive providers
final hiveBoxProvider = Provider<Box<VoiceNote>>((ref) {
  return Hive.box<VoiceNote>(AppConstants.hiveBoxName);
});

final tasksBoxProvider = Provider<Box<ScheduledTask>>((ref) {
  return Hive.box<ScheduledTask>('tasks_box');
});

final categoriesBoxProvider = Provider<Box<Category>>((ref) {
  return Hive.box<Category>('categories_box');
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

// Categories providers
final categoriesProvider = StateNotifierProvider<CategoriesNotifier, List<Category>>((ref) {
  final box = ref.watch(categoriesBoxProvider);
  return CategoriesNotifier(box);
});

final categoryProvider = Provider.family<Category?, String>((ref, id) {
  final categories = ref.watch(categoriesProvider);
  try {
    return categories.firstWhere((category) => category.id == id);
  } catch (e) {
    return null;
  }
});

final defaultCategoryProvider = Provider<Category?>((ref) {
  final categories = ref.watch(categoriesProvider);
  try {
    return categories.firstWhere((category) => category.isDefault);
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

class CategoriesNotifier extends StateNotifier<List<Category>> {
  final Box<Category> _box;

  CategoriesNotifier(this._box) : super(_box.values.toList()) {
    _box.watch().listen((event) {
      state = _box.values.toList();
    });
  }

  Future<void> addCategory(Category category) async {
    await _box.put(category.id, category);
  }

  Future<void> updateCategory(Category category) async {
    await _box.put(category.id, category);
  }

  Future<void> deleteCategory(String id) async {
    await _box.delete(id);
  }

  Future<Category?> getCategory(String id) async {
    return _box.get(id);
  }

  Category? getDefaultCategory() {
    try {
      return state.firstWhere((category) => category.isDefault);
    } catch (e) {
      return null;
    }
  }

  Future<void> setDefaultCategory(String categoryId) async {
    // Clear existing default
    for (final category in state) {
      if (category.isDefault) {
        await _box.put(category.id, category.copyWith(isDefault: false));
      }
    }
    
    // Set new default
    final newDefault = _box.get(categoryId);
    if (newDefault != null) {
      await _box.put(categoryId, newDefault.copyWith(isDefault: true));
    }
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

// Scheduled Task Repository providers
final scheduledTaskDatasourceProvider = Provider<ScheduledTaskDatasource>((ref) {
  return HiveScheduledTaskDatasource();
});

final scheduledTaskRepositoryProvider = Provider<ScheduledTaskRepository>((ref) {
  final datasource = ref.watch(scheduledTaskDatasourceProvider);
  return ScheduledTaskRepositoryImpl(datasource);
});

// Use Case providers
final createVoiceNoteUseCaseProvider = Provider<CreateVoiceNoteUseCase>((ref) {
  final voiceNoteRepository = ref.watch(voiceNoteRepositoryProvider);
  final categoryRepository = ref.watch(categoryRepositoryProvider);
  return CreateVoiceNoteUseCase(voiceNoteRepository, categoryRepository);
});

final transcribeVoiceNoteUseCaseProvider = Provider<TranscribeVoiceNoteUseCase>((ref) {
  final voiceNoteRepository = ref.watch(voiceNoteRepositoryProvider);
  final transcriptionService = ref.watch(transcriptionServiceProvider);
  return TranscribeVoiceNoteUseCase(voiceNoteRepository, transcriptionService);
});

final scheduleTasksFromVoiceNoteUseCaseProvider = Provider<ScheduleTasksFromVoiceNoteUseCase>((ref) {
  final voiceNoteRepository = ref.watch(voiceNoteRepositoryProvider);
  final taskRepository = ref.watch(scheduledTaskRepositoryProvider);
  final schedulingService = ref.watch(taskSchedulingServiceProvider);
  return ScheduleTasksFromVoiceNoteUseCase(
    voiceNoteRepository, 
    taskRepository, 
    schedulingService,
  );
});

// Task Scheduling Service providers
final taskSchedulingServiceProvider = Provider<TaskSchedulingService>((ref) {
  return TaskSchedulingServiceImpl();
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
