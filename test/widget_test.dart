import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:voice_note_scheduler/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: VoiceNoteSchedulerApp(),
      ),
    );

    // Verify that the app loads with the home page
    expect(find.text('Voice Note Scheduler'), findsOneWidget);
    expect(find.text('Welcome to Voice Note Scheduler'), findsOneWidget);
    expect(find.text('Record Voice Note'), findsOneWidget);
    expect(find.text('View Scheduled Tasks'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });
}