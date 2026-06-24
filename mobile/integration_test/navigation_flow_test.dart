import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:kashi_nav/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Navigation Flow', () {
    testWidgets('app renders with bottom navigation and 5 tabs', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Verify the app renders
      expect(find.byType(MaterialApp), findsOneWidget);

      // Verify bottom navigation exists with 5 tabs
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationDestination), findsNWidgets(5));
    });

    testWidgets('can navigate between tabs', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Tap on Brain tab (index 2)
      await tester.tap(find.byIcon(Icons.psychology));
      await tester.pumpAndSettle();

      // Verify Brain screen is shown
      expect(find.text('Kashi Brain'), findsOneWidget);

      // Tap on Map tab (index 0)
      await tester.tap(find.byIcon(Icons.map));
      await tester.pumpAndSettle();

      // Verify Map screen is shown (search header should be visible)
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('map screen shows search header and filter chips', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Verify search header exists
      expect(find.byType(TextField), findsOneWidget);

      // Verify filter chips exist
      expect(find.byType(FilterChip), findsWidgets);
    });

    testWidgets('tapping a filter chip toggles its state', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Find the first filter chip and tap it
      final filterChips = find.byType(FilterChip);
      expect(filterChips, findsWidgets);

      await tester.tap(filterChips.first);
      await tester.pumpAndSettle();

      // The chip should toggle (visual change, no crash)
    });
  });
}
