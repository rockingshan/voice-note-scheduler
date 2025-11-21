import '../../domain/entities/voice_note.dart';

abstract class VoiceNoteRepository {
  Future<void> createVoiceNote(VoiceNote voiceNote);
  Future<void> updateVoiceNote(VoiceNote voiceNote);
  Future<void> deleteVoiceNote(String id);
  Future<VoiceNote?> getVoiceNoteById(String id);
  Future<List<VoiceNote>> getAllVoiceNotes();
  Future<List<VoiceNote>> getVoiceNotesByCategory(String categoryId);
  Stream<List<VoiceNote>> watchAllVoiceNotes();
  Stream<List<VoiceNote>> watchVoiceNotesByCategory(String categoryId);
  Future<String> generateAudioPath(String categoryId, {String? filename});
  Future<void> moveAudioFile(String oldPath, String newPath);
  Future<void> deleteAudioFile(String audioPath);
}
