import 'package:flutter_test/flutter_test.dart';
import 'package:voice_note_scheduler/src/application/services/transcription_service.dart';
import 'package:voice_note_scheduler/src/data/services/ollama_transcription_backend.dart';

void main() {
  group('OllamaTranscriptionBackend', () {
    test('can be instantiated', () {
      final backend = OllamaTranscriptionBackend();
      expect(backend, isA<TranscriptionBackend>());
      backend.dispose();
    });

    test('ensureServerIsRunning throws on timeout', () async {
      final backend = OllamaTranscriptionBackend();
      
      expect(
        backend.ensureServerIsRunning(),
        throwsA(isA<StateError>()),
      );
      
      await backend.dispose();
    }, timeout: const Timeout(Duration(seconds: 35)));

    test('isModelAvailable returns false when server not running', () async {
      final backend = OllamaTranscriptionBackend();
      
      final result = await backend.isModelAvailable('whisper:small');
      
      expect(result, isFalse);
      
      await backend.dispose();
    });

    test('dispose can be called multiple times safely', () async {
      final backend = OllamaTranscriptionBackend();
      
      await backend.dispose();
      await backend.dispose();
    });
  });
}
