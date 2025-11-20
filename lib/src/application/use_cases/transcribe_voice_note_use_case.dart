import '../../domain/entities/voice_note.dart';
import '../repositories/voice_note_repository.dart';
import '../services/transcription_service.dart';

class TranscribeVoiceNoteUseCase {
  final VoiceNoteRepository _voiceNoteRepository;
  final TranscriptionService _transcriptionService;

  TranscribeVoiceNoteUseCase(
    this._voiceNoteRepository,
    this._transcriptionService,
  );

  Future<VoiceNote> call(String voiceNoteId) async {
    // Get the voice note
    final voiceNote = await _voiceNoteRepository.getVoiceNoteById(voiceNoteId);
    if (voiceNote == null) {
      throw ArgumentError('Voice note not found: $voiceNoteId');
    }

    // Update status to processing
    final processingNote = voiceNote.copyWith(
      status: VoiceNoteStatus.processing,
    );
    await _voiceNoteRepository.updateVoiceNote(processingNote);

    try {
      // Transcribe the audio
      final result = await _transcriptionService.transcribe(voiceNote.audioPath);

      // Update with transcription result
      final transcribedNote = processingNote.copyWith(
        transcription: result.text,
        status: VoiceNoteStatus.processed,
        processedAt: DateTime.now(),
        isProcessed: true,
        metadata: {
          ...processingNote.metadata,
          'confidence': result.confidence?.toString() ?? 'unknown',
          'transcriptionModel': 'whisper:small',
        },
      );

      await _voiceNoteRepository.updateVoiceNote(transcribedNote);
      return transcribedNote;
    } catch (e) {
      // Mark as failed
      final failedNote = processingNote.copyWith(
        status: VoiceNoteStatus.failed,
        metadata: {
          ...processingNote.metadata,
          'error': e.toString(),
        },
      );
      await _voiceNoteRepository.updateVoiceNote(failedNote);
      rethrow;
    }
  }
}