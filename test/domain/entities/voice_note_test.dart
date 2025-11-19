import 'package:flutter_test/flutter_test.dart';
import 'package:voice_note_scheduler/src/domain/entities/voice_note.dart';

void main() {
  group('VoiceNote', () {
    test('VoiceNote constructor creates instance with default values', () {
      final now = DateTime.now();
      final voiceNote = VoiceNote(
        title: 'Test Note',
        audioPath: '/path/to/audio.m4a',
        createdAt: now,
        categoryId: 'default',
      );

      expect(voiceNote.title, equals('Test Note'));
      expect(voiceNote.audioPath, equals('/path/to/audio.m4a'));
      expect(voiceNote.createdAt, equals(now));
      expect(voiceNote.categoryId, equals('default'));
      expect(voiceNote.isProcessed, isFalse);
      expect(voiceNote.status, equals(VoiceNoteStatus.saved));
      expect(voiceNote.duration, equals(0));
      expect(voiceNote.metadata, isEmpty);
      expect(voiceNote.id, isNotEmpty);
    });

    test('VoiceNote copyWith updates fields correctly', () {
      final now = DateTime.now();
      final voiceNote = VoiceNote(
        id: 'test-id',
        title: 'Original',
        audioPath: '/path/to/audio.m4a',
        createdAt: now,
        categoryId: 'default',
      );

      final updated = voiceNote.copyWith(
        title: 'Updated',
        duration: 60,
        status: VoiceNoteStatus.processing,
      );

      expect(updated.id, equals('test-id'));
      expect(updated.title, equals('Updated'));
      expect(updated.duration, equals(60));
      expect(updated.status, equals(VoiceNoteStatus.processing));
      expect(updated.audioPath, equals(voiceNote.audioPath));
    });

    test('VoiceNote toJson/fromJson serialization', () {
      final now = DateTime.now();
      final voiceNote = VoiceNote(
        id: 'test-id',
        title: 'Test Note',
        transcription: 'This is a test transcription',
        audioPath: '/path/to/audio.m4a',
        createdAt: now,
        duration: 120,
        categoryId: 'work',
        status: VoiceNoteStatus.processed,
        metadata: {'key': 'value'},
      );

      final json = voiceNote.toJson();
      final restored = VoiceNote.fromJson(json);

      expect(restored.id, equals(voiceNote.id));
      expect(restored.title, equals(voiceNote.title));
      expect(restored.transcription, equals(voiceNote.transcription));
      expect(restored.audioPath, equals(voiceNote.audioPath));
      expect(restored.createdAt, equals(voiceNote.createdAt));
      expect(restored.duration, equals(voiceNote.duration));
      expect(restored.categoryId, equals(voiceNote.categoryId));
      expect(restored.status, equals(voiceNote.status));
      expect(restored.metadata, equals(voiceNote.metadata));
    });

    test('VoiceNote fromJson with missing optional fields', () {
      final json = {
        'id': 'test-id',
        'title': 'Test Note',
        'audioPath': '/path/to/audio.m4a',
        'createdAt': DateTime.now().toIso8601String(),
      };

      final voiceNote = VoiceNote.fromJson(json);

      expect(voiceNote.transcription, isNull);
      expect(voiceNote.duration, equals(0));
      expect(voiceNote.categoryId, equals('default'));
      expect(voiceNote.status, equals(VoiceNoteStatus.saved));
      expect(voiceNote.metadata, isEmpty);
    });

    test('VoiceNote with all fields', () {
      final now = DateTime.now();
      final voiceNote = VoiceNote(
        id: 'test-id',
        title: 'Complete Note',
        transcription: 'Full transcription',
        audioPath: '/path/to/audio.m4a',
        createdAt: now,
        processedAt: now.add(const Duration(seconds: 30)),
        isProcessed: true,
        duration: 300,
        categoryId: 'personal',
        status: VoiceNoteStatus.processed,
        metadata: {
          'speaker': 'John',
          'location': 'Office',
        },
      );

      expect(voiceNote.title, equals('Complete Note'));
      expect(voiceNote.transcription, equals('Full transcription'));
      expect(voiceNote.isProcessed, isTrue);
      expect(voiceNote.duration, equals(300));
      expect(voiceNote.categoryId, equals('personal'));
      expect(voiceNote.status, equals(VoiceNoteStatus.processed));
      expect(voiceNote.metadata, equals({
        'speaker': 'John',
        'location': 'Office',
      }));
    });
  });
}
