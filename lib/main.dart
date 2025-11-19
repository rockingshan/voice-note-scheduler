import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'src/core/themes/app_theme.dart';
import 'src/core/utils/hive_initializer.dart';
import 'src/presentation/pages/home_page.dart';
import 'src/presentation/pages/voice_recording_page.dart';
import 'src/presentation/pages/settings_page.dart';
import 'src/presentation/pages/scheduled_tasks_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeHive();
  
  runApp(
    const ProviderScope(
      child: VoiceNoteSchedulerApp(),
    ),
  );
}

class VoiceNoteSchedulerApp extends ConsumerWidget {
  const VoiceNoteSchedulerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Voice Note Scheduler',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}

// Router configuration
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: '/record',
        builder: (context, state) => const VoiceRecordingPage(),
      ),
      GoRoute(
        path: '/tasks',
        builder: (context, state) => const ScheduledTasksPage(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsPage(),
      ),
    ],
  );
});