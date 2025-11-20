// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'voice_note.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class VoiceNoteAdapter extends TypeAdapter<VoiceNote> {
  @override
  final int typeId = 0;

  @override
  VoiceNote read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return VoiceNote(
      id: fields[0] as String?,
      title: fields[1] as String,
      transcription: fields[2] as String?,
      audioPath: fields[3] as String,
      createdAt: fields[4] as DateTime,
      processedAt: fields[5] as DateTime?,
      isProcessed: fields[6] as bool,
      duration: fields[7] as int,
      categoryId: fields[8] as String,
      status: fields[9] as VoiceNoteStatus,
      metadata: (fields[10] as Map).cast<String, String>(),
    );
  }

  @override
  void write(BinaryWriter writer, VoiceNote obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.transcription)
      ..writeByte(3)
      ..write(obj.audioPath)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.processedAt)
      ..writeByte(6)
      ..write(obj.isProcessed)
      ..writeByte(7)
      ..write(obj.duration)
      ..writeByte(8)
      ..write(obj.categoryId)
      ..writeByte(9)
      ..write(obj.status)
      ..writeByte(10)
      ..write(obj.metadata);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VoiceNoteAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class VoiceNoteStatusAdapter extends TypeAdapter<VoiceNoteStatus> {
  @override
  final int typeId = 4;

  @override
  VoiceNoteStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return VoiceNoteStatus.recording;
      case 1:
        return VoiceNoteStatus.saved;
      case 2:
        return VoiceNoteStatus.processing;
      case 3:
        return VoiceNoteStatus.processed;
      case 4:
        return VoiceNoteStatus.failed;
      default:
        return VoiceNoteStatus.recording;
    }
  }

  @override
  void write(BinaryWriter writer, VoiceNoteStatus obj) {
    switch (obj) {
      case VoiceNoteStatus.recording:
        writer.writeByte(0);
        break;
      case VoiceNoteStatus.saved:
        writer.writeByte(1);
        break;
      case VoiceNoteStatus.processing:
        writer.writeByte(2);
        break;
      case VoiceNoteStatus.processed:
        writer.writeByte(3);
        break;
      case VoiceNoteStatus.failed:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VoiceNoteStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
