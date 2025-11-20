# Images Directory

This directory contains image assets for the Voice Note Scheduler app.

## Recommended Images

### App Icons
- `app_icon.png` - Main application icon (512x512px)
- `app_icon_foreground.png` - Adaptive icon foreground (512x512px)
- `app_icon_background.png` - Adaptive icon background (512x512px)

### UI Icons
- `microphone.png` - Microphone icon for recording
- `voice_note.png` - Voice note icon
- `task.png` - Task/schedule icon
- `category.png` - Category icon

### Placeholder Images
- `placeholder_audio.png` - Placeholder for missing audio waveforms
- `empty_state.png` - Empty state illustration

## Image Guidelines

- Use PNG format for transparency support
- Optimize for different screen densities
- Follow Material Design 3 guidelines
- Ensure proper contrast ratios for accessibility

## Usage

```dart
// In Flutter widgets
Image.asset('assets/images/microphone.png')

// For app icons, update platform-specific configurations:
# Android: android/app/src/main/res/mipmap-*/
# iOS: ios/Runner/Assets.xcassets/AppIcon.appiconset/
```