import 'dart:async';
import 'dart:convert';
import 'package:ollama_dart/ollama_dart.dart';

import '../../application/services/transcription_service.dart';
import '../../core/constants/app_constants.dart';

class OllamaTranscriptionBackend implements TranscriptionBackend {
  final OllamaClient _client;
  bool _isDisposed = false;

  OllamaTranscriptionBackend({OllamaClient? client})
      : _client = client ?? OllamaClient(baseUrl: AppConstants.ollamaBaseUrl);

  @override
  Future<void> ensureServerIsRunning() async {
    if (_isDisposed) throw StateError('Backend is disposed');
    try {
      await _client.listModels().timeout(
            const Duration(seconds: AppConstants.ollamaTimeout),
          );
    } catch (e) {
      throw StateError('Ollama server is not running at ${AppConstants.ollamaBaseUrl}. Error: $e');
    }
  }

  @override
  Future<bool> isModelAvailable(String modelName) async {
    if (_isDisposed) throw StateError('Backend is disposed');
    try {
      final models = await _client.listModels();
      return models.models?.any((model) => model.model == modelName) ?? false;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> downloadModel(String modelName, {void Function(double progress)? onProgress}) async {
    if (_isDisposed) throw StateError('Backend is disposed');
    try {
      final stream = _client.pullModelStream(
        request: PullModelRequest(
          model: modelName,
          stream: true,
        ),
      );

      await for (final response in stream) {
        if (response.status == PullModelStatus.success) {
          onProgress?.call(1.0);
          break;
        }
        final total = response.total ?? 0;
        final completed = response.completed ?? 0;
        if (total > 0) {
          onProgress?.call(completed / total);
        }
      }
    } catch (e) {
      throw StateError('Failed to download model $modelName: $e');
    }
  }

  @override
  Stream<BackendTranscriptionChunk> transcribe({
    required String modelName,
    required Stream<List<int>> audioChunks,
    TranscriptionCancellationToken? cancellationToken,
  }) async* {
    if (_isDisposed) throw StateError('Backend is disposed');

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

    final base64Audio = base64Encode(audioBytes);

    try {
      final stream = _client.generateCompletionStream(
        request: GenerateCompletionRequest(
          model: modelName,
          prompt: 'Transcribe the following audio: [Audio Base64: $base64Audio]',
          stream: true,
          options: const RequestOptions(
            temperature: 0.0,
            topP: 0.9,
          ),
        ),
      );

      String accumulatedText = '';
      await for (final response in stream) {
        if (cancellationToken?.isCancelled ?? false) {
          return;
        }

        final currentText = response.response ?? '';
        accumulatedText += currentText;
        final isFinal = response.done ?? false;

        yield BackendTranscriptionChunk(
          text: accumulatedText,
          isFinal: isFinal,
          confidence: null,
          metadata: {
            'total_duration': response.totalDuration,
            'eval_count': response.evalCount,
            'progress': isFinal ? 1.0 : 0.5,
          },
        );

        if (isFinal) {
          break;
        }
      }
    } catch (e) {
      if (cancellationToken?.isCancelled ?? false) {
        return;
      }
      throw StateError('Transcription failed: $e');
    }
  }

  @override
  Future<void> dispose() async {
    if (_isDisposed) return;
    _isDisposed = true;
    _client.endSession();
  }
}
