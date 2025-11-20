import 'package:flutter_test/flutter_test.dart';
import 'package:voice_note_scheduler/src/application/services/transcription_service.dart';

void main() {
  group('TranscriptionCancellationToken', () {
    test('starts not cancelled', () {
      final token = TranscriptionCancellationToken();
      expect(token.isCancelled, isFalse);
    });

    test('can be cancelled', () {
      final token = TranscriptionCancellationToken();
      token.cancel();
      expect(token.isCancelled, isTrue);
    });

    test('can cancel multiple times safely', () {
      final token = TranscriptionCancellationToken();
      token.cancel();
      token.cancel();
      expect(token.isCancelled, isTrue);
    });

    test('listeners are called on cancel', () {
      final token = TranscriptionCancellationToken();
      var callCount = 0;
      
      token.addListener(() => callCount++);
      token.addListener(() => callCount++);
      
      token.cancel();
      
      expect(callCount, equals(2));
    });

    test('listeners added after cancel are called immediately', () {
      final token = TranscriptionCancellationToken();
      token.cancel();
      
      var called = false;
      token.addListener(() => called = true);
      
      expect(called, isTrue);
    });

    test('listener can be removed', () {
      final token = TranscriptionCancellationToken();
      var callCount = 0;
      
      final removeListener = token.addListener(() => callCount++);
      removeListener();
      
      token.cancel();
      
      expect(callCount, equals(0));
    });

    test('multiple cancel calls only invoke listeners once', () {
      final token = TranscriptionCancellationToken();
      var callCount = 0;
      
      token.addListener(() => callCount++);
      
      token.cancel();
      token.cancel();
      
      expect(callCount, equals(1));
    });
  });
}
