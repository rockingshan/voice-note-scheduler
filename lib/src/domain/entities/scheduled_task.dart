import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'scheduled_task.g.dart';

@HiveType(typeId: 1)
class ScheduledTask extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String title;
  @HiveField(2)
  final String? description;
  @HiveField(3)
  final DateTime scheduledFor;
  @HiveField(4)
  final DateTime createdAt;
  @HiveField(5)
  final DateTime updatedAt;
  @HiveField(6)
  final String? voiceNoteId;
  @HiveField(7)
  final TaskPriority priority;
  @HiveField(8)
  final TaskStatus status;
  @HiveField(9)
  final List<String> tags;

  ScheduledTask({
    String? id,
    required this.title,
    this.description,
    required this.scheduledFor,
    required this.createdAt,
    DateTime? updatedAt,
    this.voiceNoteId,
    this.priority = TaskPriority.medium,
    this.status = TaskStatus.pending,
    this.tags = const [],
  }) : id = id ?? const Uuid().v4(),
       updatedAt = updatedAt ?? createdAt;

  ScheduledTask copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? scheduledFor,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? voiceNoteId,
    TaskPriority? priority,
    TaskStatus? status,
    List<String>? tags,
  }) {
    return ScheduledTask(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      scheduledFor: scheduledFor ?? this.scheduledFor,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      voiceNoteId: voiceNoteId ?? this.voiceNoteId,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      tags: tags ?? this.tags,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'scheduledFor': scheduledFor.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'voiceNoteId': voiceNoteId,
      'priority': priority.index,
      'status': status.index,
      'tags': tags,
    };
  }

  factory ScheduledTask.fromJson(Map<String, dynamic> json) {
    return ScheduledTask(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      scheduledFor: DateTime.parse(json['scheduledFor']),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt'] ?? json['createdAt']),
      voiceNoteId: json['voiceNoteId'],
      priority: TaskPriority.values[json['priority'] ?? 1],
      status: TaskStatus.values[json['status'] ?? 0],
      tags: List<String>.from(json['tags'] ?? []),
    );
  }
}

@HiveType(typeId: 2)
enum TaskPriority {
  @HiveField(0)
  low,
  @HiveField(1)
  medium,
  @HiveField(2)
  high,
}

@HiveType(typeId: 3)
enum TaskStatus {
  @HiveField(0)
  pending,
  @HiveField(1)
  inProgress,
  @HiveField(2)
  completed,
  @HiveField(3)
  cancelled,
}