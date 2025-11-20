import 'package:record/record.dart';
import 'package:voice_note_scheduler/src/application/services/recorder.dart';

class FakeAudioRecorder implements Recorder {
  bool _isRecording = false;
  bool _isPaused = false;
  String? _currentPath;
  
  bool shouldFailStart = false;
  bool shouldFailStop = false;
  bool shouldFailPause = false;
  bool shouldFailResume = false;
  
  @override
  Future<void> start({
    required String path,
    AudioEncoder encoder = AudioEncoder.aacLc,
    int bitRate = 128000,
    int samplingRate = 44100,
  }) async {
    if (shouldFailStart) {
      throw Exception('Failed to start recording');
    }
    
    if (_isRecording) {
      throw StateError('Already recording');
    }
    
    _isRecording = true;
    _isPaused = false;
    _currentPath = path;
  }
  
  @override
  Future<String?> stop() async {
    if (shouldFailStop) {
      throw Exception('Failed to stop recording');
    }
    
    if (!_isRecording && !_isPaused) {
      return null;
    }
    
    _isRecording = false;
    _isPaused = false;
    final path = _currentPath;
    _currentPath = null;
    return path;
  }
  
  @override
  Future<void> pause() async {
    if (shouldFailPause) {
      throw Exception('Failed to pause recording');
    }
    
    if (!_isRecording) {
      throw StateError('Not recording');
    }
    
    _isRecording = false;
    _isPaused = true;
  }
  
  @override
  Future<void> resume() async {
    if (shouldFailResume) {
      throw Exception('Failed to resume recording');
    }
    
    if (!_isPaused) {
      throw StateError('Not paused');
    }
    
    _isRecording = true;
    _isPaused = false;
  }
  
  @override
  Future<void> dispose() async {
    _isRecording = false;
    _isPaused = false;
    _currentPath = null;
  }
}
