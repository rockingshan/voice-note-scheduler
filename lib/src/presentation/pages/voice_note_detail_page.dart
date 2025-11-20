import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/voice_note.dart';
import '../providers/app_providers.dart';

class VoiceNoteDetailPage extends ConsumerWidget {
  const VoiceNoteDetailPage({
    super.key,
    required this.noteId,
  });

  final String noteId;

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _deleteNote(
    BuildContext context,
    WidgetRef ref,
    VoiceNote note,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Voice Note'),
        content: const Text('Are you sure you want to delete this voice note? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final voiceNotesNotifier = ref.read(voiceNotesProvider.notifier);
      final voiceNoteRepository = ref.read(voiceNoteRepositoryProvider);
      
      try {
        await voiceNoteRepository.deleteAudioFile(note.audioPath);
      } catch (e) {
        // Ignore file deletion errors
      }
      
      await voiceNotesNotifier.deleteVoiceNote(note.id);
      
      if (context.mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Voice note deleted')),
        );
      }
    }
  }

  Future<void> _transcribeNote(
    BuildContext context,
    WidgetRef ref,
    VoiceNote note,
  ) async {
    if (note.status == VoiceNoteStatus.processing) return;
    
    try {
      final useCase = ref.read(transcribeVoiceNoteUseCaseProvider);
      await useCase(note.id);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transcription completed')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Transcription failed: $e')),
        );
      }
    }
  }

  Future<void> _extractTasks(
    BuildContext context,
    WidgetRef ref,
    VoiceNote note,
  ) async {
    try {
      final useCase = ref.read(scheduleTasksFromVoiceNoteUseCaseProvider);
      final tasks = await useCase(note.id);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Extracted ${tasks.length} tasks')),
        );
        // Navigate to tasks page
        context.push('/tasks');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Task extraction failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final note = ref.watch(voiceNoteProvider(noteId));

    if (note == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Voice Note'),
        ),
        body: const Center(
          child: Text('Voice note not found'),
        ),
      );
    }

    final fileSize = note.metadata['fileSize'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Note Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _deleteNote(context, ref, note),
            tooltip: 'Delete',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.mic,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                note.title,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatDate(note.createdAt),
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withOpacity(0.6),
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                    _InfoRow(
                      icon: Icons.timer,
                      label: 'Duration',
                      value: _formatDuration(note.duration),
                    ),
                    const SizedBox(height: 12),
                    _InfoRow(
                      icon: Icons.storage,
                      label: 'File Size',
                      value: fileSize != null 
                          ? '${(int.parse(fileSize) / 1024).toStringAsFixed(1)} KB'
                          : 'Unknown',
                    ),
                    const SizedBox(height: 12),
                    _InfoRow(
                      icon: Icons.check_circle,
                      label: 'Status',
                      value: _getStatusLabel(note.status),
                    ),
                    const SizedBox(height: 12),
                    _InfoRow(
                      icon: Icons.folder,
                      label: 'Category',
                      value: note.categoryId,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (note.transcription != null) ...[
              Text(
                'Transcription',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    note.transcription!,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Task creation section
              Text(
                'Tasks',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _extractTasks(context, ref, note),
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('Extract Tasks from Transcription'),
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Transcription section
            if (note.transcription == null) ...[
              Text(
                'Transcription',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _transcribeNote(context, ref, note),
                  icon: const Icon(Icons.transcribe),
                  label: Text(
                    note.status == VoiceNoteStatus.processing
                        ? 'Transcribing...'
                        : 'Transcribe Audio',
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            Text(
              'Audio File',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: Icon(
                  Icons.audio_file,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: Text(
                  note.audioPath.split('/').last,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                subtitle: FutureBuilder<bool>(
                  future: File(note.audioPath).exists(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return Text(
                        snapshot.data! ? 'File exists' : 'File not found',
                        style: TextStyle(
                          color: snapshot.data!
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.error,
                        ),
                      );
                    }
                    return const Text('Checking...');
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Audio playback coming soon!'),
                    ),
                  );
                },
                icon: const Icon(Icons.play_arrow),
                label: const Text('Play Recording'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getStatusLabel(VoiceNoteStatus status) {
    switch (status) {
      case VoiceNoteStatus.recording:
        return 'Recording';
      case VoiceNoteStatus.saved:
        return 'Saved';
      case VoiceNoteStatus.processing:
        return 'Processing';
      case VoiceNoteStatus.processed:
        return 'Processed';
      case VoiceNoteStatus.failed:
        return 'Failed';
    }
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
        ),
        const Spacer(),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }
}
