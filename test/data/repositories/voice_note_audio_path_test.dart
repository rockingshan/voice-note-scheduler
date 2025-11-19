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

  group('VoiceNoteRepository Audio Path Generation', () {
    test('generateAudioPath creates correct directory structure', () async {
      final audioPath = await repository.generateAudioPath('work-category');

      expect(audioPath, contains('notes'));
      expect(audioPath, contains('work-category'));
      expect(audioPath, endsWith('.m4a'));
    });

    test('generateAudioPath with custom filename', () async {
      final customFilename = 'my-note.m4a';
      final audioPath = await repository.generateAudioPath(
        'personal-category',
        filename: customFilename,
      );

      expect(audioPath, endsWith(customFilename));
      expect(audioPath, contains('personal-category'));
    });

    test('generateAudioPath for different categories have different paths',
        () async {
      final path1 = await repository.generateAudioPath('category1');
      final path2 = await repository.generateAudioPath('category2');

      expect(path1, isNot(equals(path2)));
      expect(path1, contains('category1'));
      expect(path2, contains('category2'));
    });

    test('generateAudioPath creates directory if it does not exist',
        () async {
      final audioPath = await repository.generateAudioPath(
        'new-category-directory',
      );

      expect(audioPath, isNotEmpty);
      expect(audioPath, contains('new-category-directory'));
    });

    test('generateAudioPath generates unique names for same category',
        () async {
      final path1 = await repository.generateAudioPath('same-category');
      await Future.delayed(const Duration(milliseconds: 100));
      final path2 = await repository.generateAudioPath('same-category');

      expect(path1, isNot(equals(path2)));
    });
  });
}
