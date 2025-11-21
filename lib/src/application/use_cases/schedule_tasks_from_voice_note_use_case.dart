import '../../domain/entities/scheduled_task.dart';
import '../repositories/voice_note_repository.dart';
import '../repositories/scheduled_task_repository.dart';
import '../services/task_scheduling_service.dart';

class ScheduleTasksFromVoiceNoteUseCase {
  final VoiceNoteRepository _voiceNoteRepository;
  final ScheduledTaskRepository _taskRepository;
  final TaskSchedulingService _schedulingService;

  ScheduleTasksFromVoiceNoteUseCase(
    this._voiceNoteRepository,
    this._taskRepository,
    this._schedulingService,
  );

  Future<List<ScheduledTask>> call(String voiceNoteId) async {
    // Get the voice note
    final voiceNote = await _voiceNoteRepository.getVoiceNoteById(voiceNoteId);
    if (voiceNote == null) {
      throw ArgumentError('Voice note not found: $voiceNoteId');
    }

    if (voiceNote.transcription == null || voiceNote.transcription!.isEmpty) {
      throw StateError(
          'Voice note must be transcribed before scheduling tasks');
    }

    // Extract tasks from transcription
    final extractedTasks = await _schedulingService.extractTasksFromText(
      voiceNote.transcription!,
      voiceNoteId,
    );

    // Save tasks to repository
    final savedTasks = <ScheduledTask>[];
    for (final task in extractedTasks) {
      await _taskRepository.addTask(task);
      savedTasks.add(task);
    }

    // Update voice note metadata
    final updatedNote = voiceNote.copyWith(
      metadata: {
        ...voiceNote.metadata,
        'tasksExtracted': savedTasks.length.toString(),
        'lastScheduledAt': DateTime.now().toIso8601String(),
      },
    );
    await _voiceNoteRepository.updateVoiceNote(updatedNote);

    return savedTasks;
  }
}
