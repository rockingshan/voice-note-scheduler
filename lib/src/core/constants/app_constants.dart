class AppConstants {
  // App info
  static const String appName = 'Voice Note Scheduler';
  static const String appVersion = '1.0.0';

  // Audio recording
  static const int maxRecordingDuration = 300; // 5 minutes in seconds
  static const String audioFileExtension = '.m4a';
  static const String audioFilesPath = 'audio_recordings';

  // Ollama LLM
  static const String ollamaBaseUrl = 'http://localhost:11434';
  static const String defaultModel = 'llama3.2';
  static const int ollamaTimeout = 30; // seconds

  // Storage
  static const String hiveBoxName = 'voice_notes_box';
  static const String settingsBoxName = 'settings_box';

  // UI
  static const double defaultPadding = 16.0;
  static const double borderRadius = 12.0;
  static const double buttonHeight = 48.0;
}