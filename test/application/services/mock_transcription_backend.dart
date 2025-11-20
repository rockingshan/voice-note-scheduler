import 'dart:async';

import 'package:voice_note_scheduler/src/application/services/transcription_service.dart';

class MockTranscriptionBackend implements TranscriptionBackend {
  bool _isModelAvailable = true;
  bool _throwOnEnsureServer = false;
  bool _throwOnTranscribe = false;
  bool _throwOnDownload = false;
  double _downloadProgress = 0.0;
  List<BackendTranscriptionChunk> _mockChunks = [];
  Duration _chunkDelay = const Duration(milliseconds: 100);
  bool _isDisposed = false;

  bool get isDisposed => _isDisposed;

  void setModelAvailable(bool available) {
    _isModelAvailable = available;
  }

  void setMockChunks(List<BackendTranscriptionChunk> chunks) {
    _mockChunks = chunks;
  }

  void setChunkDelay(Duration delay) {
    _chunkDelay = delay;
  }

  void setThrowOnEnsureServer(bool shouldThrow) {
    _throwOnEnsureServer = shouldThrow;
  }

  void setThrowOnTranscribe(bool shouldThrow) {
    _throwOnTranscribe = shouldThrow;
  }

  void setThrowOnDownload(bool shouldThrow) {
    _throwOnDownload = shouldThrow;
  }

  @override
  Future<void> ensureServerIsRunning() async {
    if (_throwOnEnsureServer) {
      throw StateError('Mock server error');
    }
    await Future.delayed(const Duration(milliseconds: 10));
  }

  @override
  Future<bool> isModelAvailable(String modelName) async {
    await Future.delayed(const Duration(milliseconds: 10));
    return _isModelAvailable;
  }

  @override
  Future<void> downloadModel(String modelName, {void Function(double progress)? onProgress}) async {
    if (_throwOnDownload) {
      throw StateError('Mock download error');
    }
    await Future.delayed(const Duration(milliseconds: 50));
    for (var i = 0; i <= 10; i++) {
      _downloadProgress = i / 10.0;
      onProgress?.call(_downloadProgress);
      await Future.delayed(const Duration(milliseconds: 10));
    }
    _isModelAvailable = true;
  }

  @override
  Stream<BackendTranscriptionChunk> transcribe({
    required String modelName,
    required Stream<List<int>> audioChunks,
    TranscriptionCancellationToken? cancellationToken,
  }) async* {
    if (_throwOnTranscribe) {
      throw StateError('Mock transcription error');
    }

    final audioBytes = <int>[];
    await for (final chunk in audioChunks) {
      if (cancellationToken?.isCancelled ?? false) {
        return;
      }
      audioBytes.addAll(chunk);
    }

    if (cancellationToken?.isCancelled ?? false) {
      return;
    }

    if (_mockChunks.isEmpty) {
      await Future.delayed(_chunkDelay);
      yield BackendTranscriptionChunk(
        text: 'Mock transcription result',
        isFinal: true,
        confidence: 0.95,
        metadata: {'audioSize': audioBytes.length},
      );
    } else {
      for (final chunk in _mockChunks) {
        if (cancellationToken?.isCancelled ?? false) {
          return;
        }
        await Future.delayed(_chunkDelay);
        yield chunk;
      }
    }
  }

  @override
  Future<void> dispose() async {
    _isDisposed = true;
  }
}
