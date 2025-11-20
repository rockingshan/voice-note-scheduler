# Assets Directory

This directory contains static assets used by the Voice Note Scheduler app.

## Structure

```
assets/
├── images/          # Image assets (icons, placeholders, etc.)
│   ├── app_icon.png
│   ├── microphone.png
│   └── placeholder.png
└── audio/           # Default audio files (if needed)
    └── default.mp3
```

## Usage

Images in this directory can be referenced in Flutter using:

```dart
Image.asset('assets/images/app_icon.png')
```

Make sure to update `pubspec.yaml` to include any new assets:

```yaml
flutter:
  assets:
    - assets/images/
    - assets/audio/
```