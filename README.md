# Voice Note Scheduler

A Flutter application for recording voice notes and automatically scheduling tasks using local LLM integration.

## Features

- 🎤 **Voice Recording**: Record voice notes with audio waveform visualization
- 🎙️ **On-device Transcription**: Offline speech-to-text using Whisper model via Ollama
- 🤖 **AI Processing**: Local LLM integration for intelligent task extraction
- 📅 **Smart Scheduling**: Automatically organize and schedule tasks from voice notes
- 💾 **Local Storage**: Offline-first with Hive database persistence
- 🎨 **Modern UI**: Material Design 3 with dark/light theme support
- 📱 **Cross-Platform**: Android and iOS support

## Tech Stack

- **Framework**: Flutter 3.19.6
- **State Management**: Riverpod
- **Navigation**: Go Router
- **Local Storage**: Hive with code generation
- **Audio**: Record & Flutter Audio Waveforms
- **LLM Integration**: Ollama Dart (local LLM)
- **Architecture**: Clean Architecture (Presentation, Application, Domain, Data layers)

## Prerequisites

### Flutter Environment

- Flutter SDK 3.19.6 or later
- Dart 3.3.4 or later
- Android Studio / Xcode for mobile development

### Local LLM Setup

1. **Install Ollama**:
   ```bash
   # macOS
   brew install ollama
   
   # Linux
   curl -fsSL https://ollama.ai/install.sh | sh
   
   # Windows
   # Download from https://ollama.ai/download
   ```

2. **Pull Models**:
   ```bash
   # LLM for scheduling
   ollama pull llama3.2
   
   # Whisper model for on-device transcription
   ollama pull whisper:small
   ```

3. **Start Ollama Server**:
   ```bash
   ollama serve
   ```

   The server will be available at `http://localhost:11434`

## Installation

1. **Clone the repository**:
   ```bash
   git clone <repository-url>
   cd voice_note_scheduler
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Generate code**:
   ```bash
   dart run build_runner build
   ```

4. **Run the app**:
   ```bash
   flutter run
   ```

## Project Structure

```
lib/
├── main.dart                    # App entry point
└── src/
    ├── core/
    │   ├── constants/           # App constants
    │   ├── themes/             # App themes
    │   └── utils/              # Utility functions
    ├── data/
    │   ├── datasources/        # Data sources
    │   ├── models/             # Data models
    │   └── repositories/       # Repository implementations
    ├── domain/
    │   ├── entities/           # Domain entities
    │   └── models/             # Domain models
    ├── application/
    │   ├── repositories/       # Repository interfaces
    │   └── use_cases/          # Business logic
    └── presentation/
        ├── pages/              # Screen widgets
        ├── widgets/            # Reusable UI components
        └── providers/          # Riverpod providers
```

## Development

### Code Generation

The project uses code generation for Hive adapters and other generated files:

```bash
# Generate files once
dart run build_runner build

# Watch for changes and regenerate automatically
dart run build_runner watch
```

### Running Tests

```bash
# Run all tests
flutter test

# Run tests with coverage
flutter test --coverage
```

### Code Quality

```bash
# Analyze code for issues
flutter analyze

# Format code
dart format .
```

## Platform Configuration

### Android Permissions

The app requires the following permissions (configured in `android/app/src/main/AndroidManifest.xml`):

- `RECORD_AUDIO`: For recording voice notes
- `WRITE_EXTERNAL_STORAGE`: For saving audio files
- `READ_EXTERNAL_STORAGE`: For accessing saved audio files
- `INTERNET`: For LLM communication
- `ACCESS_NETWORK_STATE`: For network status

### iOS Permissions

The app requires the following permissions (configured in `ios/Runner/Info.plist`):

- `NSMicrophoneUsageDescription`: Microphone access for voice recording
- `NSDocumentsFolderUsageDescription`: Document access for file storage
- `NSNetworkUsageDescription`: Network access for LLM communication

## Configuration

### App Constants

Key configuration values are in `lib/src/core/constants/app_constants.dart`:

- Ollama server URL: `http://localhost:11434`
- Default LLM model: `llama3.2`
- Transcription model: `whisper:small`
- Max recording duration: 300 seconds (5 minutes)
- Audio file format: `.m4a`

### Theme Configuration

App themes are defined in `lib/src/core/themes/app_theme.dart`:

- Light theme with Material Design 3
- Dark theme support
- Custom color scheme and typography

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests and ensure code quality
5. Submit a pull request

## Troubleshooting

### Build Issues

- **Missing dependencies**: Run `flutter pub get`
- **Code generation issues**: Run `dart run build_runner clean && dart run build_runner build`
- **Platform-specific issues**: Ensure you have the correct SDKs installed

### LLM Connection Issues

- Ensure Ollama is running: `ollama serve`
- Check if model is installed: `ollama list`
- Verify server accessibility: `curl http://localhost:11434/api/tags`

### Permission Issues

- Android: Check permissions in device settings
- iOS: Check permissions in Settings app

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Future Enhancements

- [ ] Cloud sync support
- [ ] Multiple language support
- [ ] Advanced task categorization
- [ ] Voice command processing
- [ ] Calendar integration
- [ ] Team collaboration features