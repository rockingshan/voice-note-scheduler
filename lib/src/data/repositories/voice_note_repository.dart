import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../domain/entities/voice_note.dart';
import '../datasources/hive_voice_note_datasource.dart';

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

class VoiceNoteRepositoryImpl implements VoiceNoteRepository {
  final VoiceNoteDatasource _datasource;

  VoiceNoteRepositoryImpl(this._datasource);

  @override
  Future<void> createVoiceNote(VoiceNote voiceNote) async {
    await _datasource.createVoiceNote(voiceNote);
  }

  @override
  Future<void> updateVoiceNote(VoiceNote voiceNote) async {
    await _datasource.updateVoiceNote(voiceNote);
  }

  @override
  Future<void> deleteVoiceNote(String id) async {
    final voiceNote = await _datasource.getVoiceNoteById(id);
    if (voiceNote != null) {
      await deleteAudioFile(voiceNote.audioPath);
    }
    await _datasource.deleteVoiceNote(id);
  }

  @override
  Future<VoiceNote?> getVoiceNoteById(String id) async {
    return _datasource.getVoiceNoteById(id);
  }

  @override
  Future<List<VoiceNote>> getAllVoiceNotes() async {
    return _datasource.getAllVoiceNotes();
  }

  @override
  Future<List<VoiceNote>> getVoiceNotesByCategory(String categoryId) async {
    return _datasource.getVoiceNotesByCategory(categoryId);
  }

  @override
  Stream<List<VoiceNote>> watchAllVoiceNotes() {
    return _datasource.watchAllVoiceNotes();
  }

  @override
  Stream<List<VoiceNote>> watchVoiceNotesByCategory(String categoryId) {
    return _datasource.watchVoiceNotesByCategory(categoryId);
  }

  @override
  Future<String> generateAudioPath(String categoryId, {String? filename}) async {
    final documentsDir = await getApplicationDocumentsDirectory();
    final categoryDir = Directory(p.join(
      documentsDir.path,
      'notes',
      categoryId,
    ));

    if (!await categoryDir.exists()) {
      await categoryDir.create(recursive: true);
    }

    final audioFilename = filename ?? '${DateTime.now().millisecondsSinceEpoch}.m4a';
    return p.join(categoryDir.path, audioFilename);
  }

  @override
  Future<void> moveAudioFile(String oldPath, String newPath) async {
    try {
      final oldFile = File(oldPath);
      if (await oldFile.exists()) {
        final newFile = File(newPath);
        
        final newDir = Directory(p.dirname(newPath));
        if (!await newDir.exists()) {
          await newDir.create(recursive: true);
        }

        await oldFile.rename(newPath);
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> deleteAudioFile(String audioPath) async {
    try {
      final file = File(audioPath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      rethrow;
    }
  }
}
