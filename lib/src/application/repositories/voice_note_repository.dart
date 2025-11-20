import '../entities/voice_note.dart';

abstract class VoiceNoteRepository {
  Future<List<VoiceNote>> getVoiceNotes();
  Future<VoiceNote?> getVoiceNoteById(String id);
  Future<void> addVoiceNote(VoiceNote voiceNote);
  Future<void> updateVoiceNote(VoiceNote voiceNote);
  Future<void> deleteVoiceNote(String id);
  Stream<List<VoiceNote>> watchVoiceNotes();
  Stream<VoiceNote?> watchVoiceNoteById(String id);
  
  // Audio file management
  Future<String> generateAudioPath(String categoryId);
  Future<void> moveAudioFile(String sourcePath, String destinationPath);
  Future<void> deleteAudioFile(String audioPath);
}