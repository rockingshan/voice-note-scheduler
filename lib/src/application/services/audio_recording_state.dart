import 'package:flutter/foundation.dart';

enum RecordingStatus {
  idle,
  recording,
  paused,
  stopped,
  permissionDenied,
  error,
}

@immutable
class AudioRecordingState {
  final RecordingStatus status;
  final Duration elapsedTime;
  final String? audioFilePath;
  final String? errorMessage;
  final int? fileSizeBytes;

  const AudioRecordingState({
    required this.status,
    this.elapsedTime = Duration.zero,
    this.audioFilePath,
    this.errorMessage,
    this.fileSizeBytes,
  });

  const AudioRecordingState.initial()
      : status = RecordingStatus.idle,
        elapsedTime = Duration.zero,
        audioFilePath = null,
        errorMessage = null,
        fileSizeBytes = null;

  AudioRecordingState copyWith({
    RecordingStatus? status,
    Duration? elapsedTime,
    String? audioFilePath,
    String? errorMessage,
    int? fileSizeBytes,
  }) {
    return AudioRecordingState(
      status: status ?? this.status,
      elapsedTime: elapsedTime ?? this.elapsedTime,
      audioFilePath: audioFilePath ?? this.audioFilePath,
      errorMessage: errorMessage ?? this.errorMessage,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
    );
  }

  bool get isRecording => status == RecordingStatus.recording;
  bool get isPaused => status == RecordingStatus.paused;
  bool get isIdle => status == RecordingStatus.idle;
  bool get hasError => status == RecordingStatus.error || status == RecordingStatus.permissionDenied;
  bool get canRecord => status == RecordingStatus.idle || status == RecordingStatus.stopped;
  bool get canPause => status == RecordingStatus.recording;
  bool get canResume => status == RecordingStatus.paused;
  bool get canStop => status == RecordingStatus.recording || status == RecordingStatus.paused;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AudioRecordingState &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          elapsedTime == other.elapsedTime &&
          audioFilePath == other.audioFilePath &&
          errorMessage == other.errorMessage &&
          fileSizeBytes == other.fileSizeBytes;

  @override
  int get hashCode =>
      status.hashCode ^
      elapsedTime.hashCode ^
      audioFilePath.hashCode ^
      errorMessage.hashCode ^
      fileSizeBytes.hashCode;

  @override
  String toString() {
    return 'AudioRecordingState{status: $status, elapsedTime: $elapsedTime, audioFilePath: $audioFilePath, errorMessage: $errorMessage, fileSizeBytes: $fileSizeBytes}';
  }
}

@immutable
class RecordingMetadata {
  final String audioFilePath;
  final Duration duration;
  final int fileSizeBytes;
  final DateTime timestamp;

  const RecordingMetadata({
    required this.audioFilePath,
    required this.duration,
    required this.fileSizeBytes,
    required this.timestamp,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecordingMetadata &&
          runtimeType == other.runtimeType &&
          audioFilePath == other.audioFilePath &&
          duration == other.duration &&
          fileSizeBytes == other.fileSizeBytes &&
          timestamp == other.timestamp;

  @override
  int get hashCode =>
      audioFilePath.hashCode ^
      duration.hashCode ^
      fileSizeBytes.hashCode ^
      timestamp.hashCode;

  @override
  String toString() {
    return 'RecordingMetadata{audioFilePath: $audioFilePath, duration: $duration, fileSizeBytes: $fileSizeBytes, timestamp: $timestamp}';
  }
}
