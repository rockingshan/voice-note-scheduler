import 'package:hive_flutter/hive_flutter.dart';
import '../../domain/entities/voice_note.dart';
import '../../domain/entities/scheduled_task.dart';
import '../../core/constants/app_constants.dart';

Future<void> initializeHive() async {
  // Initialize Hive
  await Hive.initFlutter();
  
  // Register adapters
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(VoiceNoteAdapter());
  }
  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(ScheduledTaskAdapter());
  }
  if (!Hive.isAdapterRegistered(2)) {
    Hive.registerAdapter(TaskPriorityAdapter());
  }
  if (!Hive.isAdapterRegistered(3)) {
    Hive.registerAdapter(TaskStatusAdapter());
  }
  
  // Open boxes
  await Hive.openBox<VoiceNote>(AppConstants.hiveBoxName);
  await Hive.openBox<ScheduledTask>('tasks_box');
}