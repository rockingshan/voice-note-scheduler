import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:voice_note_scheduler/src/domain/entities/voice_note.dart';
import 'package:voice_note_scheduler/src/data/datasources/hive_voice_note_datasource.dart';
import 'package:voice_note_scheduler/src/data/repositories/voice_note_repository.dart';

class MockVoiceNoteDatasource extends Mock implements VoiceNoteDatasource {}

void main() {
  late VoiceNoteRepository repository;
  late MockVoiceNoteDatasource mockDatasource;

  setUp(() {
    mockDatasource = MockVoiceNoteDatasource();
    repository = VoiceNoteRepositoryImpl(mockDatasource);
  });

  group('VoiceNoteRepository', () {
    test('createVoiceNote calls datasource', () async {
      final voiceNote = VoiceNote(
        title: 'Test Note',
        audioPath: '/path/to/audio.m4a',
        createdAt: DateTime.now(),
        categoryId: 'default',
      );

      await repository.createVoiceNote(voiceNote);

      verify(mockDatasource.createVoiceNote(voiceNote)).called(1);
    });

    test('getVoiceNoteById calls datasource', () async {
      final voiceNote = VoiceNote(
        id: 'test-id',
        title: 'Test Note',
        audioPath: '/path/to/audio.m4a',
        createdAt: DateTime.now(),
        categoryId: 'default',
      );

      when(mockDatasource.getVoiceNoteById('test-id'))
          .thenAnswer((_) async => voiceNote);

      final result = await repository.getVoiceNoteById('test-id');

      expect(result?.id, equals('test-id'));
      verify(mockDatasource.getVoiceNoteById('test-id')).called(1);
    });

    test('getAllVoiceNotes calls datasource', () async {
      final voiceNotes = [
        VoiceNote(
          title: 'Note 1',
          audioPath: '/path/to/audio1.m4a',
          createdAt: DateTime.now(),
          categoryId: 'default',
        ),
        VoiceNote(
          title: 'Note 2',
          audioPath: '/path/to/audio2.m4a',
          createdAt: DateTime.now(),
          categoryId: 'default',
        ),
      ];

      when(mockDatasource.getAllVoiceNotes())
          .thenAnswer((_) async => voiceNotes);

      final result = await repository.getAllVoiceNotes();

      expect(result.length, equals(2));
      verify(mockDatasource.getAllVoiceNotes()).called(1);
    });

    test('getVoiceNotesByCategory filters by category', () async {
      final categoryId = 'work';
      final voiceNotes = [
        VoiceNote(
          title: 'Work Note',
          audioPath: '/path/to/audio.m4a',
          createdAt: DateTime.now(),
          categoryId: categoryId,
        ),
      ];

      when(mockDatasource.getVoiceNotesByCategory(categoryId))
          .thenAnswer((_) async => voiceNotes);

      final result = await repository.getVoiceNotesByCategory(categoryId);

      expect(result.length, equals(1));
      expect(result[0].categoryId, equals(categoryId));
      verify(mockDatasource.getVoiceNotesByCategory(categoryId)).called(1);
    });

    test('updateVoiceNote calls datasource', () async {
      final voiceNote = VoiceNote(
        id: 'test-id',
        title: 'Updated Note',
        audioPath: '/path/to/audio.m4a',
        createdAt: DateTime.now(),
        categoryId: 'default',
      );

      await repository.updateVoiceNote(voiceNote);

      verify(mockDatasource.updateVoiceNote(voiceNote)).called(1);
    });

    test('deleteVoiceNote deletes audio file and note', () async {
      final voiceNote = VoiceNote(
        id: 'test-id',
        title: 'Test Note',
        audioPath: '/path/to/audio.m4a',
        createdAt: DateTime.now(),
        categoryId: 'default',
      );

      when(mockDatasource.getVoiceNoteById('test-id'))
          .thenAnswer((_) async => voiceNote);

      await repository.deleteVoiceNote('test-id');

      verify(mockDatasource.getVoiceNoteById('test-id')).called(1);
      verify(mockDatasource.deleteVoiceNote('test-id')).called(1);
    });
  });
}
