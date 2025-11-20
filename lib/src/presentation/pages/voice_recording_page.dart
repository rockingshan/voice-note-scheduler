import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/services/audio_recording_state.dart';
import '../../domain/entities/voice_note.dart';
import '../providers/app_providers.dart';

class VoiceRecordingPage extends ConsumerWidget {
  const VoiceRecordingPage({super.key});

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Future<void> _runAction(
    BuildContext context,
    Future<void> Function() action,
  ) async {
    try {
      await action();
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }

  Future<void> _saveVoiceNote(
    WidgetRef ref,
    RecordingMetadata metadata,
  ) async {
    final categoryRepository = ref.read(categoryRepositoryProvider);
    final voiceNotesNotifier = ref.read(voiceNotesProvider.notifier);
    
    final defaultCategory = await categoryRepository.ensureDefaultCategory();
    
    final voiceNote = VoiceNote(
      title: 'Voice Note ${DateTime.now().toString().substring(0, 16)}',
      audioPath: metadata.audioFilePath,
      createdAt: metadata.timestamp,
      duration: metadata.duration.inSeconds,
      categoryId: defaultCategory.id,
      status: VoiceNoteStatus.saved,
      metadata: {
        'fileSize': metadata.fileSizeBytes.toString(),
      },
    );
    
    await voiceNotesNotifier.addVoiceNote(voiceNote);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stateAsync = ref.watch(audioRecordingStateProvider);
    final audioRecorder = ref.read(audioRecorderServiceProvider);

    final state = stateAsync.when(
      data: (value) => value,
      loading: () => const AudioRecordingState.initial(),
      error: (_, __) => const AudioRecordingState.initial(),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Record Voice Note'),
        actions: [
          if (!state.isIdle)
            IconButton(
              tooltip: 'Discard recording',
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _runAction(context, audioRecorder.cancelRecording),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 160,
                    width: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: state.isRecording
                          ? Theme.of(context).colorScheme.primary.withOpacity(0.15)
                          : Theme.of(context).colorScheme.surfaceContainerHighest,
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary,
                        width: state.isRecording ? 4 : 2,
                      ),
                    ),
                    child: Icon(
                      state.isRecording ? Icons.mic : Icons.mic_none,
                      size: 72,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _formatDuration(state.elapsedTime),
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _statusLabel(state),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (state.hasError && state.errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      state.errorMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  if (state.fileSizeBytes != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Size: ${(state.fileSizeBytes! / 1024).toStringAsFixed(1)} KB',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 32),
            _RecordingControls(
              state: state,
              onStart: () => _runAction(context, audioRecorder.startRecording),
              onPause: () => _runAction(context, audioRecorder.pauseRecording),
              onResume: () => _runAction(context, audioRecorder.resumeRecording),
              onStop: () async {
                final metadata = await audioRecorder.stopRecording();
                if (metadata != null && context.mounted) {
                  await _saveVoiceNote(ref, metadata);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Recording saved (${metadata.duration.inSeconds}s)',
                        ),
                      ),
                    );
                    context.pop();
                  }
                }
              },
              onCancel: () => _runAction(context, audioRecorder.cancelRecording),
            ),
          ],
        ),
      ),
    );
  }

  String _statusLabel(AudioRecordingState state) {
    switch (state.status) {
      case RecordingStatus.idle:
        return 'Ready to record';
      case RecordingStatus.recording:
        return 'Recording in progress';
      case RecordingStatus.paused:
        return 'Recording paused';
      case RecordingStatus.stopped:
        return 'Recording finished';
      case RecordingStatus.permissionDenied:
        return 'Permission needed';
      case RecordingStatus.error:
        return 'Recording error';
    }
  }
}

class _RecordingControls extends StatelessWidget {
  const _RecordingControls({
    required this.state,
    required this.onStart,
    required this.onPause,
    required this.onResume,
    required this.onStop,
    required this.onCancel,
  });

  final AudioRecordingState state;
  final Future<void> Function() onStart;
  final Future<void> Function() onPause;
  final Future<void> Function() onResume;
  final Future<void> Function() onStop;
  final Future<void> Function() onCancel;

  @override
  Widget build(BuildContext context) {
    if (state.canRecord) {
      return FilledButton.icon(
        onPressed: onStart,
        icon: const Icon(Icons.mic),
        label: const Text('Start recording'),
      );
    }

    if (state.isRecording) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onPause,
              icon: const Icon(Icons.pause),
              label: const Text('Pause'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              onPressed: onStop,
              icon: const Icon(Icons.stop),
              label: const Text('Stop'),
            ),
          ),
        ],
      );
    }

    if (state.isPaused) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onResume,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Resume'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                  onPressed: onStop,
                  icon: const Icon(Icons.stop),
                  label: const Text('Stop'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: onCancel,
            icon: const Icon(Icons.delete_outline),
            label: const Text('Discard recording'),
          ),
        ],
      );
    }

    return FilledButton.icon(
      onPressed: onStart,
      icon: const Icon(Icons.mic),
      label: const Text('Start recording'),
    );
  }
}
