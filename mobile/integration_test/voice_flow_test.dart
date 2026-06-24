import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:kashi_nav/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Voice Flow', () {
    testWidgets('brain screen shows mic button and prompt chips', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to Brain tab
      await tester.tap(find.byIcon(Icons.psychology));
      await tester.pumpAndSettle();

      // Verify Brain screen elements
      expect(find.text('Kashi Brain'), findsOneWidget);
      expect(find.byIcon(Icons.mic), findsOneWidget);
      expect(find.byIcon(Icons.send), findsOneWidget);

      // Verify prompt chips exist
      expect(find.text('Is the Ganga Aarti on tonight?'), findsOneWidget);
      expect(find.text('Best lassi near me?'), findsOneWidget);
      expect(find.text('Set a 4:30 AM alarm'), findsOneWidget);
    });

    testWidgets('tapping mic button opens voice overlay', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to Brain tab
      await tester.tap(find.byIcon(Icons.psychology));
      await tester.pumpAndSettle();

      // Tap mic button
      await tester.tap(find.byIcon(Icons.mic));
      await tester.pumpAndSettle();

      // Voice overlay should appear with listening state
      // The overlay shows "Tap to stop" when listening
      expect(find.text('Tap to stop'), findsOneWidget);
    });

    testWidgets('tapping prompt chip sends message', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to Brain tab
      await tester.tap(find.byIcon(Icons.psychology));
      await tester.pumpAndSettle();

      // Tap a prompt chip
      await tester.tap(find.text('Is the Ganga Aarti on tonight?'));
      await tester.pumpAndSettle();

      // The message should appear in the chat
      expect(find.text('Is the Ganga Aarti on tonight?'), findsWidgets);
    });

    testWidgets('text input sends message', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to Brain tab
      await tester.tap(find.byIcon(Icons.psychology));
      await tester.pumpAndSettle();

      // Type a message
      await tester.enterText(find.byType(TextField), 'Hello Kashi');
      await tester.pumpAndSettle();

      // Tap send button
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      // The message should appear in the chat
      expect(find.text('Hello Kashi'), findsWidgets);
    });
  });
}
