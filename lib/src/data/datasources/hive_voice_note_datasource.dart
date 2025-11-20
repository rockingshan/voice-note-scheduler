import 'package:hive_flutter/hive_flutter.dart';
import '../../domain/entities/voice_note.dart';
import '../../core/constants/app_constants.dart';

abstract class VoiceNoteDatasource {
  Future<void> createVoiceNote(VoiceNote voiceNote);
  Future<void> updateVoiceNote(VoiceNote voiceNote);
  Future<void> deleteVoiceNote(String id);
  Future<VoiceNote?> getVoiceNoteById(String id);
  Future<List<VoiceNote>> getAllVoiceNotes();
  Future<List<VoiceNote>> getVoiceNotesByCategory(String categoryId);
  Stream<List<VoiceNote>> watchAllVoiceNotes();
  Stream<List<VoiceNote>> watchVoiceNotesByCategory(String categoryId);
}

class HiveVoiceNoteDatasource implements VoiceNoteDatasource {
  late Box<VoiceNote> _voiceNotesBox;

  HiveVoiceNoteDatasource() {
    _voiceNotesBox = Hive.box<VoiceNote>(AppConstants.hiveBoxName);
  }

  @override
  Future<void> createVoiceNote(VoiceNote voiceNote) async {
    await _voiceNotesBox.put(voiceNote.id, voiceNote);
  }

  @override
  Future<void> updateVoiceNote(VoiceNote voiceNote) async {
    final key = _voiceNotesBox.keys.firstWhere(
      (key) => (_voiceNotesBox.get(key) as VoiceNote).id == voiceNote.id,
      orElse: () => null,
    );
    if (key != null) {
      await _voiceNotesBox.put(key, voiceNote);
    }
  }

  @override
  Future<void> deleteVoiceNote(String id) async {
    final key = _voiceNotesBox.keys.firstWhere(
      (key) => (_voiceNotesBox.get(key) as VoiceNote).id == id,
      orElse: () => null,
    );
    if (key != null) {
      await _voiceNotesBox.delete(key);
    }
  }

  @override
  Future<VoiceNote?> getVoiceNoteById(String id) async {
    try {
      return _voiceNotesBox.values.firstWhere(
        (note) => note.id == id,
        orElse: () => null,
      );
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<VoiceNote>> getAllVoiceNotes() async {
    return _voiceNotesBox.values.toList();
  }

  @override
  Future<List<VoiceNote>> getVoiceNotesByCategory(String categoryId) async {
    return _voiceNotesBox.values
        .where((note) => note.categoryId == categoryId)
        .toList();
  }

  @override
  Stream<List<VoiceNote>> watchAllVoiceNotes() {
    return _voiceNotesBox.watch().map((_) => _voiceNotesBox.values.toList());
  }

  @override
  Stream<List<VoiceNote>> watchVoiceNotesByCategory(String categoryId) {
    return _voiceNotesBox.watch().map(
          (_) => _voiceNotesBox.values
              .where((note) => note.categoryId == categoryId)
              .toList(),
        );
  }
}
