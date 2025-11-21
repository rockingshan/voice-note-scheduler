// ignore_for_file: invalid_use_of_null_value

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:voice_note_scheduler/src/application/repositories/category_repository.dart';
import 'package:voice_note_scheduler/src/application/repositories/voice_note_repository.dart';
import 'package:voice_note_scheduler/src/application/use_cases/create_voice_note_use_case.dart';
import 'package:voice_note_scheduler/src/domain/entities/category.dart';
import 'package:voice_note_scheduler/src/domain/entities/scheduled_task.dart';
import 'package:voice_note_scheduler/src/domain/entities/voice_note.dart';

void main() {
  group('Integration Tests', () {
    late MockVoiceNoteRepository mockVoiceNoteRepo;
    late MockCategoryRepository mockCategoryRepo;
    late CreateVoiceNoteUseCase useCase;

    setUp(() async {
      mockVoiceNoteRepo = MockVoiceNoteRepository();
      mockCategoryRepo = MockCategoryRepository();
      useCase = CreateVoiceNoteUseCase(mockVoiceNoteRepo, mockCategoryRepo);
    });

    test('CreateVoiceNoteUseCase should create voice note with default category', () async {
      // Arrange
      final defaultCategory = Category(
        id: 'default-category',
        name: 'General',
        color: 0xFF2196F3,
        isDefault: true,
        keywords: [],
        createdAt: DateTime.now(),
      );

      when(mockCategoryRepo.getDefaultCategory())
          .thenAnswer((_) async => defaultCategory);
      when(mockVoiceNoteRepo.createVoiceNote(any<VoiceNote>()))
          .thenAnswer((_) async {});

      // Act
      final voiceNote = await useCase.call(
        title: 'Test Note',
        audioPath: '/path/to/audio.m4a',
        duration: 60,
      );

      // Assert
      expect(voiceNote.title, equals('Test Note'));
      expect(voiceNote.audioPath, equals('/path/to/audio.m4a'));
      expect(voiceNote.duration, equals(60));
      expect(voiceNote.categoryId, equals('default-category'));
      expect(voiceNote.status, equals(VoiceNoteStatus.saved));
      
      verify(mockVoiceNoteRepo.createVoiceNote(any<VoiceNote>())).called(1);
    });

    test('ScheduledTask should have correct structure', () {
      // Test that ScheduledTask entity works correctly
      final task = ScheduledTask(
        title: 'Test Task',
        description: 'Test Description',
        scheduledFor: DateTime.now().add(const Duration(days: 1)),
        createdAt: DateTime.now(),
        priority: TaskPriority.medium,
        status: TaskStatus.pending,
        tags: ['test'],
      );

      expect(task.title, equals('Test Task'));
      expect(task.description, equals('Test Description'));
      expect(task.priority, equals(TaskPriority.medium));
      expect(task.status, equals(TaskStatus.pending));
      expect(task.tags, contains('test'));

      // Test copyWith
      final updatedTask = task.copyWith(
        status: TaskStatus.completed,
      );
      expect(updatedTask.status, equals(TaskStatus.completed));
      expect(updatedTask.updatedAt.isAfter(updatedTask.createdAt), isTrue);
    });

    test('VoiceNote should have correct structure', () {
      // Test that VoiceNote entity works correctly
      final voiceNote = VoiceNote(
        title: 'Test Note',
        audioPath: '/path/to/audio.m4a',
        createdAt: DateTime.now(),
        categoryId: 'test-category',
        duration: 120,
        status: VoiceNoteStatus.saved,
        metadata: {'test': 'value'},
      );

      expect(voiceNote.title, equals('Test Note'));
      expect(voiceNote.audioPath, equals('/path/to/audio.m4a'));
      expect(voiceNote.duration, equals(120));
      expect(voiceNote.status, equals(VoiceNoteStatus.saved));
      expect(voiceNote.metadata['test'], equals('value'));

      // Test copyWith
      final updatedNote = voiceNote.copyWith(
        transcription: 'Test transcription',
        status: VoiceNoteStatus.processed,
      );
      expect(updatedNote.transcription, equals('Test transcription'));
      expect(updatedNote.status, equals(VoiceNoteStatus.processed));
    });
  });
}

class MockVoiceNoteRepository extends Mock implements VoiceNoteRepository {}

class MockCategoryRepository extends Mock implements CategoryRepository {}
