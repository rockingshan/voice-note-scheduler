import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'voice_note.g.dart';

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

  VoiceNote({
    String? id,
    required this.title,
    this.transcription,
    required this.audioPath,
    required this.createdAt,
    this.processedAt,
    this.isProcessed = false,
  }) : id = id ?? const Uuid().v4();

  VoiceNote copyWith({
    String? id,
    String? title,
    String? transcription,
    String? audioPath,
    DateTime? createdAt,
    DateTime? processedAt,
    bool? isProcessed,
  }) {
    return VoiceNote(
      id: id ?? this.id,
      title: title ?? this.title,
      transcription: transcription ?? this.transcription,
      audioPath: audioPath ?? this.audioPath,
      createdAt: createdAt ?? this.createdAt,
      processedAt: processedAt ?? this.processedAt,
      isProcessed: isProcessed ?? this.isProcessed,
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
    );
  }
}