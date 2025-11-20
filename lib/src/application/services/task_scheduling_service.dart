import 'package:uuid/uuid.dart';
import '../../domain/entities/scheduled_task.dart';
import '../../core/constants/app_constants.dart';

abstract class TaskSchedulingService {
  Future<List<ScheduledTask>> extractTasksFromText(String text, String voiceNoteId);
  Future<ScheduledTask> scheduleTask({
    required String title,
    required String description,
    required DateTime scheduledFor,
    required String voiceNoteId,
    TaskPriority priority = TaskPriority.medium,
    List<String>? tags,
  });
}

class TaskSchedulingServiceImpl implements TaskSchedulingService {
  final Uuid _uuid;
  final OllamaTaskExtractor _extractor;

  TaskSchedulingServiceImpl()
      : _uuid = const Uuid(),
        _extractor = OllamaTaskExtractor();

  @override
  Future<List<ScheduledTask>> extractTasksFromText(String text, String voiceNoteId) async {
    try {
      final extractedTasks = await _extractor.extractTasks(text);
      
      final scheduledTasks = <ScheduledTask>[];
      for (final taskData in extractedTasks) {
        final task = ScheduledTask(
          id: _uuid.v4(),
          title: taskData['title'] as String,
          description: taskData['description'] as String? ?? '',
          scheduledFor: _parseDateTime(taskData['scheduledFor'] as String?),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          status: TaskStatus.pending,
          priority: _parsePriority(taskData['priority'] as String?),
          voiceNoteId: voiceNoteId,
          tags: (taskData['tags'] as List<dynamic>?)?.cast<String>() ?? [],
        );
        scheduledTasks.add(task);
      }
      
      return scheduledTasks;
    } catch (e) {
      throw Exception('Failed to extract tasks: $e');
    }
  }

  @override
  Future<ScheduledTask> scheduleTask({
    required String title,
    required String description,
    required DateTime scheduledFor,
    required String voiceNoteId,
    TaskPriority priority = TaskPriority.medium,
    List<String>? tags,
  }) async {
    return ScheduledTask(
      id: _uuid.v4(),
      title: title,
      description: description,
      scheduledFor: scheduledFor,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      status: TaskStatus.pending,
      priority: priority,
      voiceNoteId: voiceNoteId,
      tags: tags ?? [],
    );
  }

  DateTime _parseDateTime(String? dateTimeString) {
    if (dateTimeString == null || dateTimeString.isEmpty) {
      // Default to tomorrow at 9 AM if no time specified
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      return DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 9, 0);
    }
    
    try {
      return DateTime.parse(dateTimeString);
    } catch (e) {
      // If parsing fails, try common formats or default to tomorrow
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      return DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 9, 0);
    }
  }

  TaskPriority _parsePriority(String? priorityString) {
    switch (priorityString?.toLowerCase()) {
      case 'high':
        return TaskPriority.high;
      case 'low':
        return TaskPriority.low;
      default:
        return TaskPriority.medium;
    }
  }
}

class OllamaTaskExtractor {
  Future<List<Map<String, dynamic>>> extractTasks(String text) async {
    // This is a mock implementation for now
    // In a real implementation, this would call Ollama with the Llama model
    
    // Simple regex-based extraction for demonstration
    final tasks = <Map<String, dynamic>>[];
    
    // Look for task patterns like "Call mom tomorrow", "Meeting at 3 PM", etc.
    final taskPatterns = [
      RegExp(r'(?:call|email|text|meet|schedule|appoint|visit)\s+([^,.!?]+)', caseSensitive: false),
      RegExp(r'([^,.!?]*\b(?:meeting|appointment|call|email)\b[^,.!?]*)', caseSensitive: false),
    ];
    
    for (final pattern in taskPatterns) {
      final matches = pattern.allMatches(text);
      for (final match in matches) {
        final taskText = match.group(1)?.trim() ?? '';
        if (taskText.isNotEmpty) {
          tasks.add({
            'title': taskText,
            'description': 'Extracted from voice note',
            'scheduledFor': _suggestTimeFromText(taskText),
            'priority': 'medium',
            'tags': ['voice-extracted'],
          });
        }
      }
    }
    
    // If no tasks found, create a general task
    if (tasks.isEmpty) {
      tasks.add({
        'title': 'Task from voice note',
        'description': text,
        'scheduledFor': DateTime.now().add(const Duration(days: 1)).toIso8601String(),
        'priority': 'medium',
        'tags': ['voice-extracted'],
      });
    }
    
    return tasks;
  }
  
  String _suggestTimeFromText(String text) {
    final now = DateTime.now();
    final lowerText = text.toLowerCase();
    
    // Simple time suggestions based on keywords
    if (lowerText.contains('tomorrow')) {
      final tomorrow = now.add(const Duration(days: 1));
      return DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 9, 0).toIso8601String();
    } else if (lowerText.contains('today')) {
      return DateTime(now.year, now.month, now.day, 14, 0).toIso8601String();
    } else if (lowerText.contains('next week')) {
      final nextWeek = now.add(const Duration(days: 7));
      return DateTime(nextWeek.year, nextWeek.month, nextWeek.day, 9, 0).toIso8601String();
    }
    
    // Default to tomorrow at 9 AM
    final tomorrow = now.add(const Duration(days: 1));
    return DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 9, 0).toIso8601String();
  }
}