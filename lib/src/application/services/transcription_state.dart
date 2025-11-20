import 'package:flutter/foundation.dart';

enum TranscriptionStatus {
  idle,
  modelInitializing,
  modelReady,
  modelMissing,
  queued,
  running,
  completed,
  failed,
  cancelled,
}

@immutable
class TranscriptionResult {
  final String text;
  final double? confidence;
  final bool isPartial;
  final Map<String, dynamic> metadata;

  const TranscriptionResult({
    required this.text,
    this.confidence,
    this.isPartial = false,
    this.metadata = const {},
  });

  TranscriptionResult copyWith({
    String? text,
    double? confidence,
    bool? isPartial,
    Map<String, dynamic>? metadata,
  }) {
    return TranscriptionResult(
      text: text ?? this.text,
      confidence: confidence ?? this.confidence,
      isPartial: isPartial ?? this.isPartial,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TranscriptionResult &&
          runtimeType == other.runtimeType &&
          text == other.text &&
          confidence == other.confidence &&
          isPartial == other.isPartial &&
          mapEquals(metadata, other.metadata);

  @override
  int get hashCode =>
      text.hashCode ^
      confidence.hashCode ^
      isPartial.hashCode ^
      metadata.hashCode;

  @override
  String toString() {
    return 'TranscriptionResult{text: $text, confidence: $confidence, isPartial: $isPartial, metadata: $metadata}';
  }
}

@immutable
class TranscriptionProgress {
  final TranscriptionStatus status;
  final double progress;
  final String? partialText;
  final String? errorMessage;
  final TranscriptionResult? result;

  const TranscriptionProgress({
    required this.status,
    this.progress = 0.0,
    this.partialText,
    this.errorMessage,
    this.result,
  });

  const TranscriptionProgress.idle()
      : status = TranscriptionStatus.idle,
        progress = 0.0,
        partialText = null,
        errorMessage = null,
        result = null;

  const TranscriptionProgress.modelInitializing()
      : status = TranscriptionStatus.modelInitializing,
        progress = 0.0,
        partialText = null,
        errorMessage = null,
        result = null;

  const TranscriptionProgress.modelReady()
      : status = TranscriptionStatus.modelReady,
        progress = 0.0,
        partialText = null,
        errorMessage = null,
        result = null;

  const TranscriptionProgress.modelMissing()
      : status = TranscriptionStatus.modelMissing,
        progress = 0.0,
        partialText = null,
        errorMessage = 'Whisper model is not available. Please download it first.',
        result = null;

  TranscriptionProgress copyWith({
    TranscriptionStatus? status,
    double? progress,
    Object? partialText = _defaultValue,
    Object? errorMessage = _defaultValue,
    Object? result = _defaultValue,
  }) {
    return TranscriptionProgress(
      status: status ?? this.status,
      progress: progress ?? this.progress,
      partialText: partialText == _defaultValue ? this.partialText : partialText as String?,
      errorMessage: errorMessage == _defaultValue ? this.errorMessage : errorMessage as String?,
      result: result == _defaultValue ? this.result : result as TranscriptionResult?,
    );
  }

  static const Object _defaultValue = Object();

  bool get isProcessing =>
      status == TranscriptionStatus.queued ||
      status == TranscriptionStatus.running;
  bool get isComplete => status == TranscriptionStatus.completed;
  bool get hasError =>
      status == TranscriptionStatus.failed ||
      status == TranscriptionStatus.modelMissing;
  bool get canTranscribe =>
      status == TranscriptionStatus.idle ||
      status == TranscriptionStatus.modelReady ||
      status == TranscriptionStatus.completed ||
      status == TranscriptionStatus.failed ||
      status == TranscriptionStatus.cancelled;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TranscriptionProgress &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          progress == other.progress &&
          partialText == other.partialText &&
          errorMessage == other.errorMessage &&
          result == other.result;

  @override
  int get hashCode =>
      status.hashCode ^
      progress.hashCode ^
      partialText.hashCode ^
      errorMessage.hashCode ^
      result.hashCode;

  @override
  String toString() {
    return 'TranscriptionProgress{status: $status, progress: $progress, partialText: $partialText, errorMessage: $errorMessage, result: $result}';
  }
}
