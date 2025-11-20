import 'package:flutter_test/flutter_test.dart';
import 'package:voice_note_scheduler/src/application/services/transcription_state.dart';

void main() {
  group('TranscriptionResult', () {
    test('copyWith creates new instance with updated values', () {
      const result = TranscriptionResult(
        text: 'Original text',
        confidence: 0.85,
        isPartial: true,
      );

      final updated = result.copyWith(text: 'Updated text', isPartial: false);

      expect(updated.text, equals('Updated text'));
      expect(updated.confidence, equals(0.85));
      expect(updated.isPartial, isFalse);
    });

    test('equality comparison works correctly', () {
      const result1 = TranscriptionResult(
        text: 'Test text',
        confidence: 0.9,
        isPartial: false,
      );
      const result2 = TranscriptionResult(
        text: 'Test text',
        confidence: 0.9,
        isPartial: false,
      );
      const result3 = TranscriptionResult(
        text: 'Different text',
        confidence: 0.9,
        isPartial: false,
      );

      expect(result1, equals(result2));
      expect(result1, isNot(equals(result3)));
    });
  });

  group('TranscriptionProgress', () {
    test('idle constructor creates idle state', () {
      const progress = TranscriptionProgress.idle();

      expect(progress.status, equals(TranscriptionStatus.idle));
      expect(progress.progress, equals(0.0));
      expect(progress.partialText, isNull);
      expect(progress.errorMessage, isNull);
      expect(progress.result, isNull);
    });

    test('modelMissing constructor creates proper error state', () {
      const progress = TranscriptionProgress.modelMissing();

      expect(progress.status, equals(TranscriptionStatus.modelMissing));
      expect(progress.errorMessage, isNotNull);
      expect(progress.hasError, isTrue);
    });

    test('isProcessing is true for queued and running', () {
      const queued = TranscriptionProgress(status: TranscriptionStatus.queued);
      const running = TranscriptionProgress(status: TranscriptionStatus.running);
      const completed = TranscriptionProgress(status: TranscriptionStatus.completed);

      expect(queued.isProcessing, isTrue);
      expect(running.isProcessing, isTrue);
      expect(completed.isProcessing, isFalse);
    });

    test('hasError is true for failed and modelMissing', () {
      const failed = TranscriptionProgress(status: TranscriptionStatus.failed);
      const modelMissing = TranscriptionProgress(status: TranscriptionStatus.modelMissing);
      const running = TranscriptionProgress(status: TranscriptionStatus.running);

      expect(failed.hasError, isTrue);
      expect(modelMissing.hasError, isTrue);
      expect(running.hasError, isFalse);
    });

    test('canTranscribe is false when processing', () {
      const running = TranscriptionProgress(status: TranscriptionStatus.running);
      const idle = TranscriptionProgress.idle();

      expect(running.canTranscribe, isFalse);
      expect(idle.canTranscribe, isTrue);
    });

    test('copyWith creates new instance with updated values', () {
      const progress = TranscriptionProgress(
        status: TranscriptionStatus.running,
        progress: 0.5,
      );

      final updated = progress.copyWith(
        progress: 0.75,
        partialText: 'Partial text',
      );

      expect(updated.progress, equals(0.75));
      expect(updated.partialText, equals('Partial text'));
      expect(updated.status, equals(TranscriptionStatus.running));
    });
  });

  group('TranscriptionStatus', () {
    test('all statuses are distinct', () {
      final statuses = TranscriptionStatus.values.toSet();
      expect(statuses.length, equals(TranscriptionStatus.values.length));
    });
  });
}
