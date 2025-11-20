import 'dart:async';
import 'dart:io';

import 'package:meta/meta.dart';

import '../../core/constants/app_constants.dart';
import 'transcription_state.dart';

typedef _CancelCallback = void Function();

abstract class TranscriptionService {
  Stream<TranscriptionProgress> get progressStream;
  TranscriptionProgress get currentProgress;

  Future<void> ensureModelReady();
  Future<TranscriptionResult> transcribe(
    String audioFilePath, {
    TranscriptionCancellationToken? cancellationToken,
  });
  Future<void> cancelCurrentTranscription();
  bool get isBusy;
  void dispose();
}

abstract class TranscriptionBackend {
  Future<bool> isModelAvailable(String modelName);
  Future<void> downloadModel(
    String modelName, {
    void Function(double progress)? onProgress,
  });
  Future<void> ensureServerIsRunning();
  Stream<BackendTranscriptionChunk> transcribe({
    required String modelName,
    required Stream<List<int>> audioChunks,
    TranscriptionCancellationToken? cancellationToken,
  });
  Future<void> dispose();
}

class BackendTranscriptionChunk {
  final String text;
  final bool isFinal;
  final double? confidence;
  final Map<String, dynamic> metadata;

  BackendTranscriptionChunk({
    required this.text,
    required this.isFinal,
    this.confidence,
    this.metadata = const {},
  });
}

@visibleForTesting
class TranscriptionCancellationToken {
  bool _isCancelled = false;
  final List<_CancelCallback> _listeners = [];

  bool get isCancelled => _isCancelled;

  void cancel() {
    if (_isCancelled) return;
    _isCancelled = true;
    for (final listener in List<_CancelCallback>.from(_listeners)) {
      listener();
    }
    _listeners.clear();
  }

  _CancelCallback addListener(_CancelCallback listener) {
    if (_isCancelled) {
      listener();
      return () {};
    }
    _listeners.add(listener);
    return () {
      _listeners.remove(listener);
    };
  }
}

class _TranscriptionJob {
  _TranscriptionJob({
    required this.file,
    required this.token,
    required this.completer,
  });

  final File file;
  final TranscriptionCancellationToken token;
  final Completer<TranscriptionResult> completer;
}

class TranscriptionServiceImpl implements TranscriptionService {
  static const Duration _modelCheckInterval = Duration(minutes: 5);
  static const int _defaultChunkSizeBytes = 1024 * 1024; // 1 MB

  final TranscriptionBackend _backend;
  final StreamController<TranscriptionProgress> _progressController;
  final List<_TranscriptionJob> _jobQueue = [];

  TranscriptionProgress _currentProgress = const TranscriptionProgress.idle();
  TranscriptionCancellationToken? _currentToken;
  Timer? _modelCheckTimer;
  bool _isEnsuringModel = false;
  bool _isProcessingQueue = false;
  bool _isDisposed = false;

  @override
  bool get isBusy =>
      _isProcessingQueue || _currentProgress.isProcessing || _jobQueue.isNotEmpty;

  TranscriptionServiceImpl({required TranscriptionBackend backend})
      : _backend = backend,
        _progressController = StreamController<TranscriptionProgress>.broadcast() {
    _progressController.add(_currentProgress);
    _scheduleModelCheck();
  }

  @override
  Stream<TranscriptionProgress> get progressStream => _progressController.stream;

  @override
  TranscriptionProgress get currentProgress => _currentProgress;

  void _updateProgress(TranscriptionProgress progress) {
    if (_isDisposed) return;
    _currentProgress = progress;
    if (!_progressController.isClosed) {
      _progressController.add(progress);
    }
  }

  Future<void> _setModelStatus(
    TranscriptionStatus status, {
    String? message,
  }) async {
    switch (status) {
      case TranscriptionStatus.modelInitializing:
        _updateProgress(const TranscriptionProgress.modelInitializing());
        break;
      case TranscriptionStatus.modelReady:
        _updateProgress(const TranscriptionProgress.modelReady());
        break;
      case TranscriptionStatus.modelMissing:
        _updateProgress(const TranscriptionProgress.modelMissing());
        break;
      default:
        _updateProgress(
          TranscriptionProgress(
            status: status,
            errorMessage: message,
          ),
        );
    }
  }

  Future<void> _scheduleModelCheck() async {
    _modelCheckTimer?.cancel();
    _modelCheckTimer =
        Timer.periodic(_modelCheckInterval, (_) => ensureModelReady());
  }

  @override
  Future<void> ensureModelReady() async {
    if (_isEnsuringModel) return;
    _isEnsuringModel = true;
    try {
      await _backend.ensureServerIsRunning();
      final isAvailable =
          await _backend.isModelAvailable(AppConstants.transcriptionModelName);
      if (!isAvailable) {
        await _setModelStatus(TranscriptionStatus.modelInitializing);
        await _backend.downloadModel(
          AppConstants.transcriptionModelName,
          onProgress: (progress) {
            _updateProgress(
              TranscriptionProgress(
                status: TranscriptionStatus.modelInitializing,
                progress: progress,
              ),
            );
          },
        );
      }
      await _setModelStatus(TranscriptionStatus.modelReady);
    } catch (e) {
      await _setModelStatus(
        TranscriptionStatus.modelMissing,
        message: 'Failed to prepare Whisper model: $e',
      );
      rethrow;
    } finally {
      _isEnsuringModel = false;
    }
  }

  @override
  Future<TranscriptionResult> transcribe(
    String audioFilePath, {
    TranscriptionCancellationToken? cancellationToken,
  }) async {
    if (_isDisposed) {
      throw StateError('Transcription service has been disposed.');
    }

    final file = File(audioFilePath);
    if (!await file.exists()) {
      throw ArgumentError('Audio file does not exist at $audioFilePath');
    }

    final token = cancellationToken ?? TranscriptionCancellationToken();
    final completer = Completer<TranscriptionResult>();
    final job = _TranscriptionJob(
      file: file,
      token: token,
      completer: completer,
    );

    _jobQueue.add(job);

    if (!_isProcessingQueue && !_currentProgress.isProcessing) {
      _updateProgress(
        const TranscriptionProgress(
          status: TranscriptionStatus.queued,
          progress: 0.0,
        ),
      );
    }

    unawaited(_processQueue());
    return completer.future;
  }

  Future<void> _processQueue() async {
    if (_isProcessingQueue || _isDisposed) return;
    _isProcessingQueue = true;

    while (_jobQueue.isNotEmpty && !_isDisposed) {
      final job = _jobQueue.removeAt(0);
      _currentToken = job.token;

      if (job.token.isCancelled) {
        _handlePreStartCancellation(job);
        continue;
      }

      try {
        await _prepareModelForJob();
        final result = await _runTranscriptionJob(job.file, job.token);
        if (!job.completer.isCompleted) {
          job.completer.complete(result);
        }
      } catch (e, stack) {
        if (!job.completer.isCompleted) {
          job.completer.completeError(e, stack);
        }
      } finally {
        if (_currentToken == job.token) {
          _currentToken = null;
        }
      }
    }

    _isProcessingQueue = false;
  }

  Future<void> _prepareModelForJob() async {
    try {
      await ensureModelReady();
    } catch (e) {
      throw StateError('Failed to prepare Whisper model: $e');
    }

    if (_currentProgress.status == TranscriptionStatus.modelMissing) {
      throw StateError('Whisper model is missing.');
    }
  }

  void _handlePreStartCancellation(_TranscriptionJob job) {
    _updateProgress(
      const TranscriptionProgress(
        status: TranscriptionStatus.cancelled,
        progress: 0.0,
        errorMessage: 'Transcription cancelled before it started.',
      ),
    );
    if (!job.completer.isCompleted) {
      job.completer.completeError(StateError('Transcription cancelled'));
    }
  }

  Future<TranscriptionResult> _runTranscriptionJob(
    File file,
    TranscriptionCancellationToken token,
  ) async {
    _updateProgress(
      const TranscriptionProgress(
        status: TranscriptionStatus.running,
        progress: 0.01,
      ),
    );

    final controller = StreamController<List<int>>();
    final chunkedStream = controller.stream.asBroadcastStream();
    final totalBytes = await file.length();
    var processedBytes = 0;

    Future<void> readFile() async {
      final raf = await file.open(mode: FileMode.read);
      try {
        while (true) {
          if (token.isCancelled) {
            break;
          }
          final chunk = await raf.read(_defaultChunkSizeBytes);
          if (chunk.isEmpty) {
            break;
          }
          processedBytes += chunk.length;
          if (!controller.isClosed) {
            controller.add(chunk);
          }
          _updateProgress(
            _currentProgress.copyWith(
              status: TranscriptionStatus.running,
              progress: totalBytes == 0 ? 0.0 : processedBytes / totalBytes,
            ),
          );
        }
      } finally {
        await raf.close();
        await controller.close();
      }
    }

    final readFuture = readFile();
    TranscriptionResult? finalResult;

    try {
      await for (final chunk in _backend.transcribe(
        modelName: AppConstants.transcriptionModelName,
        audioChunks: chunkedStream,
        cancellationToken: token,
      )) {
        if (token.isCancelled) {
          break;
        }
        final result = TranscriptionResult(
          text: chunk.text,
          confidence: chunk.confidence,
          isPartial: !chunk.isFinal,
          metadata: chunk.metadata,
        );
        final progress = chunk.metadata['progress'] as double? ??
            (_currentProgress.progress > 0 ? _currentProgress.progress : 0.5);
        _updateProgress(
          TranscriptionProgress(
            status: chunk.isFinal
                ? TranscriptionStatus.completed
                : TranscriptionStatus.running,
            progress: chunk.isFinal ? 1.0 : progress,
            partialText: chunk.isFinal ? null : result.text,
            result: chunk.isFinal ? result : null,
          ),
        );
        if (chunk.isFinal) {
          finalResult = result;
        }
      }
      await readFuture;
    } catch (e) {
      if (token.isCancelled) {
        _updateProgress(
          TranscriptionProgress(
            status: TranscriptionStatus.cancelled,
            progress: _currentProgress.progress,
            errorMessage: 'Transcription cancelled.',
          ),
        );
        throw StateError('Transcription cancelled');
      }
      _updateProgress(
        TranscriptionProgress(
          status: TranscriptionStatus.failed,
          progress: _currentProgress.progress,
          errorMessage: 'Failed to transcribe audio: $e',
        ),
      );
      rethrow;
    } finally {
      _currentToken = null;
    }

    if (token.isCancelled) {
      _updateProgress(
        TranscriptionProgress(
          status: TranscriptionStatus.cancelled,
          progress: _currentProgress.progress,
        ),
      );
      throw StateError('Transcription cancelled');
    }

    if (finalResult == null) {
      _updateProgress(
        TranscriptionProgress(
          status: TranscriptionStatus.failed,
          progress: _currentProgress.progress,
          errorMessage: 'Transcription backend returned no final result.',
        ),
      );
      throw StateError('Transcription backend returned no final result.');
    }

    _updateProgress(
      TranscriptionProgress(
        status: TranscriptionStatus.completed,
        progress: 1.0,
        result: finalResult,
      ),
    );
    return finalResult;
  }

  @override
  Future<void> cancelCurrentTranscription() async {
    if (_currentToken != null && _currentProgress.isProcessing) {
      _currentToken?.cancel();
      return;
    }

    if (_jobQueue.isNotEmpty) {
      final job = _jobQueue.removeAt(0);
      job.token.cancel();
      if (!job.completer.isCompleted) {
        job.completer.completeError(StateError('Transcription cancelled'));
      }
      _updateProgress(
        TranscriptionProgress(
          status: TranscriptionStatus.cancelled,
          progress: 0.0,
          errorMessage: 'Queued transcription cancelled.',
        ),
      );
    }
  }

  @override
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    _modelCheckTimer?.cancel();
    _currentToken?.cancel();
    for (final job in _jobQueue) {
      job.token.cancel();
      if (!job.completer.isCompleted) {
        job.completer.completeError(StateError('Transcription service disposed'));
      }
    }
    _jobQueue.clear();
    _progressController.close();
    unawaited(_backend.dispose());
  }
}
