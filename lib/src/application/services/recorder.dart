import 'package:record/record.dart';

abstract class Recorder {
  Future<void> start({
    required String path,
    AudioEncoder encoder = AudioEncoder.aacLc,
    int bitRate = 128000,
    int samplingRate = 44100,
    int numChannels = 2,
  });

  Future<String?> stop();
  Future<void> pause();
  Future<void> resume();
  Future<void> dispose();
}

class RecordPluginRecorder implements Recorder {
  final AudioRecorder _recorder;

  RecordPluginRecorder({AudioRecorder? recorder})
      : _recorder = recorder ?? AudioRecorder();

  @override
  Future<void> start({
    required String path,
    AudioEncoder encoder = AudioEncoder.aacLc,
    int bitRate = 128000,
    int samplingRate = 44100,
    int numChannels = 2,
  }) {
    final config = RecordConfig(
      encoder: encoder,
      bitRate: bitRate,
      sampleRate: samplingRate,
      numChannels: numChannels,
    );

    return _recorder.start(
      config,
      path: path,
    );
  }

  @override
  Future<String?> stop() {
    return _recorder.stop();
  }

  @override
  Future<void> pause() {
    return _recorder.pause();
  }

  @override
  Future<void> resume() {
    return _recorder.resume();
  }

  @override
  Future<void> dispose() {
    return _recorder.dispose();
  }
}
