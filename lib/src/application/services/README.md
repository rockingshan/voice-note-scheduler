# Transcription Service

## Overview

The TranscriptionService provides offline, on-device audio transcription using Ollama and Whisper models. It handles model initialization, audio file processing, streaming partial results, and cancellation support.

## Key Features

- **Offline transcription**: Uses local Ollama server with Whisper model
- **Model management**: Automatic download and initialization
- **Streaming support**: Provides partial transcription results
- **Cancellation**: Full support for cancelling transcription mid-process
- **Status tracking**: Detailed status updates (queued, running, completed, failed, cancelled)
- **Error handling**: Graceful failure without dangling futures or temp files

## Usage Example

### Basic Transcription

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voice_note_scheduler/src/application/services/transcription_service.dart';
import 'package:voice_note_scheduler/src/presentation/providers/app_providers.dart';

class TranscriptionExample extends ConsumerWidget {
  final String audioFilePath;
  
  const TranscriptionExample({required this.audioFilePath});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transcriptionService = ref.watch(transcriptionServiceProvider);
    final transcriptionStateAsync = ref.watch(transcriptionStateProvider);

    return transcriptionStateAsync.when(
      data: (progress) {
        return Column(
          children: [
            Text('Status: ${progress.status}'),
            if (progress.isProcessing)
              LinearProgressIndicator(value: progress.progress),
            if (progress.partialText != null)
              Text('Partial: ${progress.partialText}'),
            if (progress.result != null)
              Text('Final: ${progress.result!.text}'),
            if (progress.hasError && progress.errorMessage != null)
              Text('Error: ${progress.errorMessage}'),
            ElevatedButton(
              onPressed: progress.canTranscribe
                  ? () => _startTranscription(transcriptionService)
                  : null,
              child: const Text('Transcribe'),
            ),
            if (progress.isProcessing)
              ElevatedButton(
                onPressed: () => transcriptionService.cancelCurrentTranscription(),
                child: const Text('Cancel'),
              ),
          ],
        );
      },
      loading: () => const CircularProgressIndicator(),
      error: (error, stack) => Text('Error: $error'),
    );
  }

  Future<void> _startTranscription(TranscriptionService service) async {
    try {
      final result = await service.transcribe(audioFilePath);
      print('Transcription complete: ${result.text}');
      print('Confidence: ${result.confidence}');
    } catch (e) {
      print('Transcription failed: $e');
    }
  }
}
```

### With Cancellation Token

```dart
Future<void> transcribeWithCancellation(
  TranscriptionService service,
  String audioFilePath,
) async {
  final cancellationToken = TranscriptionCancellationToken();
  
  // Start transcription
  final transcriptionFuture = service.transcribe(
    audioFilePath,
    cancellationToken: cancellationToken,
  );

  // Cancel after 5 seconds
  Future.delayed(const Duration(seconds: 5), () {
    cancellationToken.cancel();
  });

  try {
    final result = await transcriptionFuture;
    print('Result: ${result.text}');
  } on StateError catch (e) {
    print('Transcription was cancelled');
  }
}
```

### Integration with Voice Notes

```dart
Future<void> transcribeVoiceNote(
  WidgetRef ref,
  VoiceNote note,
) async {
  final transcriptionService = ref.read(transcriptionServiceProvider);
  final voiceNotesNotifier = ref.read(voiceNotesProvider.notifier);

  // Update status to processing
  await voiceNotesNotifier.updateVoiceNote(
    note.copyWith(status: VoiceNoteStatus.processing),
  );

  try {
    final result = await transcriptionService.transcribe(note.audioPath);
    
    // Update with transcription
    await voiceNotesNotifier.updateVoiceNote(
      note.copyWith(
        transcription: result.text,
        status: VoiceNoteStatus.processed,
        processedAt: DateTime.now(),
        isProcessed: true,
        metadata: {
          ...note.metadata,
          'confidence': result.confidence?.toString() ?? 'unknown',
        },
      ),
    );
  } catch (e) {
    // Mark as failed
    await voiceNotesNotifier.updateVoiceNote(
      note.copyWith(status: VoiceNoteStatus.failed),
    );
    rethrow;
  }
}
```

## Architecture

### Service Layers

1. **TranscriptionService (interface)**: Abstract service interface
2. **TranscriptionServiceImpl**: Core service implementation
3. **TranscriptionBackend (interface)**: Backend abstraction
4. **OllamaTranscriptionBackend**: Ollama/Whisper implementation

### State Models

- **TranscriptionStatus**: Enum for status tracking
- **TranscriptionResult**: Final or partial transcription result
- **TranscriptionProgress**: Complete progress state with metadata

### Key Components

- **TranscriptionCancellationToken**: Cooperative cancellation support
- **Model Management**: Automatic download and initialization
- **Stream Processing**: Chunked audio file reading for memory efficiency

## Model Requirements

The service requires the Ollama server running with the Whisper model:

```bash
# Start Ollama
ollama serve

# Pull Whisper model
ollama pull whisper:small
```

## Configuration

Model configuration in `lib/src/core/constants/app_constants.dart`:

```dart
static const String ollamaBaseUrl = 'http://localhost:11434';
static const String transcriptionModelName = 'whisper:small';
```

## Testing

The service includes comprehensive tests with mock backends:

```bash
flutter test test/application/services/transcription_service_test.dart
flutter test test/application/services/transcription_state_test.dart
flutter test test/application/services/transcription_cancellation_token_test.dart
```

## Error Handling

The service handles these error scenarios:

- **Model missing**: Status changes to `modelMissing`, with error message
- **Server unavailable**: Throws StateError on ensureServerIsRunning
- **File not found**: Throws ArgumentError
- **Transcription failure**: Updates status to `failed`, includes error message
- **Cancellation**: Updates status to `cancelled`, throws StateError

## Performance Considerations

- Audio files are read in 1MB chunks to minimize memory usage
- Model availability is checked periodically (every 5 minutes)
- Backend operations run off the UI thread
- Streams are properly closed to prevent memory leaks
