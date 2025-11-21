import 'package:flutter_test/flutter_test.dart';
import 'package:voice_note_scheduler/src/domain/entities/voice_note.dart';

void main() {
  group('VoiceNoteSerialization', () {
    test('VoiceNote serialization and deserialization', () {
      final voiceNote = VoiceNote(
        id: 'test-id',
        title: 'Test Note',
        transcription: 'Test transcription',
        audioPath: '/path/to/audio.m4a',
        createdAt: DateTime.now(),
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
      expect(restored.duration, equals(voiceNote.duration));
      expect(restored.categoryId, equals(voiceNote.categoryId));
      expect(restored.status, equals(voiceNote.status));
      expect(restored.metadata, equals(voiceNote.metadata));
    });

    test('VoiceNote with empty metadata', () {
      final voiceNote = VoiceNote(
        id: 'test-id',
        title: 'Test Note',
        audioPath: '/path/to/audio.m4a',
        createdAt: DateTime.now(),
        categoryId: 'default',
      );

      final json = voiceNote.toJson();
      final restored = VoiceNote.fromJson(json);

      expect(restored.metadata, isEmpty);
    });

    test('VoiceNote status values', () {
      expect(VoiceNoteStatus.values.length, equals(5));
      expect(VoiceNoteStatus.recording, isNotNull);
      expect(VoiceNoteStatus.saved, isNotNull);
      expect(VoiceNoteStatus.processing, isNotNull);
      expect(VoiceNoteStatus.processed, isNotNull);
      expect(VoiceNoteStatus.failed, isNotNull);
    });
  });
}
