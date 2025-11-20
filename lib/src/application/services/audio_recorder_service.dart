import 'dart:async';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import '../repositories/category_repository.dart';
import '../repositories/voice_note_repository.dart';
import 'audio_recording_state.dart';
import 'recorder.dart';

abstract class AudioRecorderService {
  Stream<AudioRecordingState> get stateStream;
  AudioRecordingState get currentState;
  
  Future<void> startRecording();
  Future<void> pauseRecording();
  Future<void> resumeRecording();
  Future<RecordingMetadata?> stopRecording();
  Future<void> cancelRecording();
  Future<bool> hasPermissions();
  Future<bool> requestPermissions();
}

class AudioRecorderServiceImpl implements AudioRecorderService {
  static const _permissionErrorMessage =
      'Microphone (and storage on Android) permission is required to record audio. Please enable it in Settings.';

  final Recorder _recorder;
  final VoiceNoteRepository _voiceNoteRepository;
  final CategoryRepository _categoryRepository;

  final StreamController<AudioRecordingState> _stateController =
      StreamController<AudioRecordingState>.broadcast();

  AudioRecordingState _currentState = const AudioRecordingState.initial();
  Timer? _elapsedTimer;
  DateTime? _recordingStartTime;
  Duration _pausedDuration = Duration.zero;
  DateTime? _pauseStartTime;
  bool _isDisposed = false;

  AudioRecorderServiceImpl({
    Recorder? recorder,
    required VoiceNoteRepository voiceNoteRepository,
    required CategoryRepository categoryRepository,
  })  : _recorder = recorder ?? RecordPluginRecorder(),
        _voiceNoteRepository = voiceNoteRepository,
        _categoryRepository = categoryRepository {
    _stateController.add(_currentState);
  }

  @override
  Stream<AudioRecordingState> get stateStream => _stateController.stream;

  @override
  AudioRecordingState get currentState => _currentState;

  void _updateState(AudioRecordingState newState) {
    if (_isDisposed) return;
    _currentState = newState;
    if (!_stateController.isClosed) {
      _stateController.add(newState);
    }
  }

  bool get _needsStoragePermission {
    return Platform.isAndroid;
  }

  @override
  Future<bool> hasPermissions() async {
    final microphoneStatus = await Permission.microphone.status;
    if (!microphoneStatus.isGranted) {
      return false;
    }

    if (_needsStoragePermission) {
      final storageStatus = await Permission.storage.status;
      if (!storageStatus.isGranted && !storageStatus.isLimited) {
        return false;
      }
    }

    return true;
  }

  @override
  Future<bool> requestPermissions() async {
    final microphoneStatus = await Permission.microphone.request();
    if (!microphoneStatus.isGranted) {
      return false;
    }

    if (_needsStoragePermission) {
      final storageStatus = await Permission.storage.request();
      if (!storageStatus.isGranted && !storageStatus.isLimited) {
        return false;
      }
    }

    return true;
  }

  Future<bool> _ensurePermissions() async {
    final hasPermission = await hasPermissions();
    if (hasPermission) {
      return true;
    }

    final granted = await requestPermissions();
    if (!granted) {
      _updateState(
        const AudioRecordingState(
          status: RecordingStatus.permissionDenied,
          errorMessage: _permissionErrorMessage,
        ),
      );
    }
    return granted;
  }

  @override
  Future<void> startRecording() async {
    if (!_currentState.canRecord) {
      throw StateError('Cannot start recording in current state: ${_currentState.status}');
    }

    try {
      final granted = await _ensurePermissions();
      if (!granted) {
        return;
      }

      final defaultCategory = await _categoryRepository.ensureDefaultCategory();
      final audioPath = await _voiceNoteRepository.generateAudioPath(
        defaultCategory.id,
      );

      await _recorder.start(
        path: audioPath,
      );

      _recordingStartTime = DateTime.now();
      _pausedDuration = Duration.zero;
      _pauseStartTime = null;

      _updateState(
        AudioRecordingState(
          status: RecordingStatus.recording,
          audioFilePath: audioPath,
          elapsedTime: Duration.zero,
        ),
      );

      _startElapsedTimer();
    } catch (e) {
      _updateState(
        AudioRecordingState(
          status: RecordingStatus.error,
          errorMessage: 'Failed to start recording: ${e.toString()}',
        ),
      );
      rethrow;
    }
  }

  @override
  Future<void> pauseRecording() async {
    if (!_currentState.canPause) {
      throw StateError('Cannot pause recording in current state: ${_currentState.status}');
    }

    try {
      await _recorder.pause();
      _pauseStartTime = DateTime.now();
      _stopElapsedTimer();

      _updateState(
        _currentState.copyWith(
          status: RecordingStatus.paused,
        ),
      );
    } catch (e) {
      _updateState(
        _currentState.copyWith(
          status: RecordingStatus.error,
          errorMessage: 'Failed to pause recording: ${e.toString()}',
        ),
      );
      rethrow;
    }
  }

  @override
  Future<void> resumeRecording() async {
    if (!_currentState.canResume) {
      throw StateError('Cannot resume recording in current state: ${_currentState.status}');
    }

    try {
      await _recorder.resume();

      if (_pauseStartTime != null) {
        _pausedDuration += DateTime.now().difference(_pauseStartTime!);
        _pauseStartTime = null;
      }

      _updateState(
        _currentState.copyWith(
          status: RecordingStatus.recording,
        ),
      );

      _startElapsedTimer();
    } catch (e) {
      _updateState(
        _currentState.copyWith(
          status: RecordingStatus.error,
          errorMessage: 'Failed to resume recording: ${e.toString()}',
        ),
      );
      rethrow;
    }
  }

  @override
  Future<RecordingMetadata?> stopRecording() async {
    if (!_currentState.canStop) {
      throw StateError('Cannot stop recording in current state: ${_currentState.status}');
    }

    try {
      _stopElapsedTimer();

      final path = await _recorder.stop();
      
      if (path == null || _currentState.audioFilePath == null) {
        _updateState(
          const AudioRecordingState(
            status: RecordingStatus.error,
            errorMessage: 'Recording path is null',
          ),
        );
        return null;
      }

      final file = File(path);
      final fileExists = await file.exists();
      final fileSize = fileExists ? await file.length() : 0;
      final duration = _calculateTotalDuration();

      final metadata = RecordingMetadata(
        audioFilePath: path,
        duration: duration,
        fileSizeBytes: fileSize,
        timestamp: DateTime.now(),
      );

      _updateState(
        AudioRecordingState(
          status: RecordingStatus.stopped,
          audioFilePath: path,
          elapsedTime: duration,
          fileSizeBytes: fileSize,
        ),
      );

      _recordingStartTime = null;
      _pausedDuration = Duration.zero;
      _pauseStartTime = null;

      return metadata;
    } catch (e) {
      _updateState(
        AudioRecordingState(
          status: RecordingStatus.error,
          errorMessage: 'Failed to stop recording: ${e.toString()}',
        ),
      );
      rethrow;
    }
  }

  @override
  Future<void> cancelRecording() async {
    try {
      _stopElapsedTimer();

      final currentPath = _currentState.audioFilePath;
      
      await _recorder.stop();

      if (currentPath != null) {
        await _voiceNoteRepository.deleteAudioFile(currentPath);
      }

      _updateState(const AudioRecordingState.initial());

      _recordingStartTime = null;
      _pausedDuration = Duration.zero;
      _pauseStartTime = null;
    } catch (e) {
      _updateState(
        AudioRecordingState(
          status: RecordingStatus.error,
          errorMessage: 'Failed to cancel recording: ${e.toString()}',
        ),
      );
      rethrow;
    }
  }

  void _startElapsedTimer() {
    _elapsedTimer?.cancel();
    _elapsedTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      final elapsed = _calculateCurrentElapsed();
      _updateState(
        _currentState.copyWith(
          elapsedTime: elapsed,
        ),
      );
    });
  }

  void _stopElapsedTimer() {
    _elapsedTimer?.cancel();
    _elapsedTimer = null;
  }

  Duration _calculateCurrentElapsed() {
    if (_recordingStartTime == null) return Duration.zero;

    final now = DateTime.now();
    final totalElapsed = now.difference(_recordingStartTime!);

    final pausedPortion = _pausedDuration +
        (_pauseStartTime != null ? now.difference(_pauseStartTime!) : Duration.zero);

    final activeDuration = totalElapsed - pausedPortion;
    return activeDuration.isNegative ? Duration.zero : activeDuration;
  }

  Duration _calculateTotalDuration() {
    return _calculateCurrentElapsed();
  }

  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    _stopElapsedTimer();
    _stateController.close();
    _recorder.dispose();
  }
}
