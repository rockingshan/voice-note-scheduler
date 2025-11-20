import 'package:uuid/uuid.dart';
import '../../domain/entities/voice_note.dart';
import '../../domain/entities/category.dart';
import '../repositories/voice_note_repository.dart';
import '../repositories/category_repository.dart';

class CreateVoiceNoteUseCase {
  final VoiceNoteRepository _voiceNoteRepository;
  final CategoryRepository _categoryRepository;
  final Uuid _uuid;

  CreateVoiceNoteUseCase(
    this._voiceNoteRepository,
    this._categoryRepository,
  ) : _uuid = const Uuid();

  Future<VoiceNote> call({
    required String title,
    required String audioPath,
    String? categoryId,
    int duration = 0,
    Map<String, String>? metadata,
  }) async {
    // Ensure we have a valid category
    final targetCategoryId = categoryId ?? 
        (await _categoryRepository.getDefaultCategory())?.id ??
        (await _ensureDefaultCategory()).id;

    final voiceNote = VoiceNote(
      id: _uuid.v4(),
      title: title,
      audioPath: audioPath,
      createdAt: DateTime.now(),
      categoryId: targetCategoryId,
      duration: duration,
      status: VoiceNoteStatus.saved,
      metadata: metadata ?? {},
    );

    await _voiceNoteRepository.createVoiceNote(voiceNote);
    return voiceNote;
  }

  Future<Category> _ensureDefaultCategory() async {
    await _categoryRepository.ensureDefaultCategory();
    final defaultCategory = await _categoryRepository.getDefaultCategory();
    if (defaultCategory == null) {
      throw StateError('Failed to create default category');
    }
    return defaultCategory;
  }
}