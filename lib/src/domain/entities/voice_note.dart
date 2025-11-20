import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'voice_note.g.dart';

@HiveType(typeId: 4)
enum VoiceNoteStatus {
  @HiveField(0)
  recording,
  @HiveField(1)
  saved,
  @HiveField(2)
  processing,
  @HiveField(3)
  processed,
  @HiveField(4)
  failed,
}

@HiveType(typeId: 0)
class VoiceNote extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String title;
  @HiveField(2)
  final String? transcription;
  @HiveField(3)
  final String audioPath;
  @HiveField(4)
  final DateTime createdAt;
  @HiveField(5)
  final DateTime? processedAt;
  @HiveField(6)
  final bool isProcessed;
  @HiveField(7)
  final int duration;
  @HiveField(8)
  final String categoryId;
  @HiveField(9)
  final VoiceNoteStatus status;
  @HiveField(10)
  final Map<String, String> metadata;

  VoiceNote({
    String? id,
    required this.title,
    this.transcription,
    required this.audioPath,
    required this.createdAt,
    this.processedAt,
    this.isProcessed = false,
    this.duration = 0,
    required this.categoryId,
    this.status = VoiceNoteStatus.saved,
    this.metadata = const {},
  }) : id = id ?? const Uuid().v4();

  VoiceNote copyWith({
    String? id,
    String? title,
    String? transcription,
    String? audioPath,
    DateTime? createdAt,
    DateTime? processedAt,
    bool? isProcessed,
    int? duration,
    String? categoryId,
    VoiceNoteStatus? status,
    Map<String, String>? metadata,
  }) {
    return VoiceNote(
      id: id ?? this.id,
      title: title ?? this.title,
      transcription: transcription ?? this.transcription,
      audioPath: audioPath ?? this.audioPath,
      createdAt: createdAt ?? this.createdAt,
      processedAt: processedAt ?? this.processedAt,
      isProcessed: isProcessed ?? this.isProcessed,
      duration: duration ?? this.duration,
      categoryId: categoryId ?? this.categoryId,
      status: status ?? this.status,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'transcription': transcription,
      'audioPath': audioPath,
      'createdAt': createdAt.toIso8601String(),
      'processedAt': processedAt?.toIso8601String(),
      'isProcessed': isProcessed,
      'duration': duration,
      'categoryId': categoryId,
      'status': status.index,
      'metadata': metadata,
    };
  }

  factory VoiceNote.fromJson(Map<String, dynamic> json) {
    return VoiceNote(
      id: json['id'],
      title: json['title'],
      transcription: json['transcription'],
      audioPath: json['audioPath'],
      createdAt: DateTime.parse(json['createdAt']),
      processedAt: json['processedAt'] != null 
          ? DateTime.parse(json['processedAt']) 
          : null,
      isProcessed: json['isProcessed'] ?? false,
      duration: json['duration'] ?? 0,
      categoryId: json['categoryId'] ?? 'default',
      status: VoiceNoteStatus.values[json['status'] ?? 1],
      metadata: Map<String, String>.from(json['metadata'] ?? {}),
    );
  }
}