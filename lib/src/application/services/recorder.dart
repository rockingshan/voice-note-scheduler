import 'package:record/record.dart';

abstract class Recorder {
  Future<void> start({
    required String path,
    AudioEncoder encoder,
    int bitRate,
    int samplingRate,
  });

  Future<String?> stop();
  Future<void> pause();
  Future<void> resume();
  Future<void> dispose();
}

class RecordPluginRecorder implements Recorder {
  final Record _record;

  RecordPluginRecorder({Record? record}) : _record = record ?? Record();

  @override
  Future<void> start({
    required String path,
    AudioEncoder encoder = AudioEncoder.aacLc,
    int bitRate = 128000,
    int samplingRate = 44100,
  }) {
    return _record.start(
      path: path,
      encoder: encoder,
      bitRate: bitRate,
      samplingRate: samplingRate,
    );
  }

  @override
  Future<String?> stop() {
    return _record.stop();
  }

  @override
  Future<void> pause() {
    return _record.pause();
  }

  @override
  Future<void> resume() {
    return _record.resume();
  }

  @override
  Future<void> dispose() {
    return _record.dispose();
  }
}
