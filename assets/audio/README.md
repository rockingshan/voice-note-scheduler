# Audio Directory

This directory contains audio assets for the Voice Note Scheduler app.

## Contents

### Default Audio Files
- `notification.mp3` - Sound for task notifications
- `recording_start.mp3` - Sound when recording starts
- `recording_stop.mp3` - Sound when recording stops
- `error.mp3` - Error sound feedback

### Audio Guidelines

- Use MP3 or M4A format for compatibility
- Keep file sizes small (< 100KB per file)
- Optimize for mobile playback
- Consider accessibility with visual alternatives

## Usage

```dart
// In Flutter widgets
Audio.asset('assets/audio/notification.mp3')

// For playback
import 'package:audioplayers/audioplayers.dart';

final player = AudioPlayer();
await player.play(AssetSource('assets/audio/notification.mp3'));
```

## Note

User-recorded audio files are stored in the device's application documents directory, not here. This directory is only for app-provided audio assets.