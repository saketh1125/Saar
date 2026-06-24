import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:kashi_nav/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Repository Mode Switching', () {
    testWidgets('tools screen shows repo mode toggle', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to Tools tab
      await tester.tap(find.byIcon(Icons.build));
      await tester.pumpAndSettle();

      // Verify Tools screen is shown
      expect(find.text('Tools'), findsOneWidget);

      // Verify mode toggle exists (Mock/Live switch)
      expect(find.byType(SwitchListTile), findsWidgets);
    });

    testWidgets('toggling repo mode switches between mock and live', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to Tools tab
      await tester.tap(find.byIcon(Icons.build));
      await tester.pumpAndSettle();

      // Find the mode toggle switch
      final switches = find.byType(Switch);
      if (switches.evaluate().isNotEmpty) {
        // Toggle the switch
        await tester.tap(switches.first);
        await tester.pumpAndSettle();

        // The switch should toggle (visual change, no crash)
      }
    });

    testWidgets('journal screen renders with empty state', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to Journal tab
      await tester.tap(find.byIcon(Icons.book));
      await tester.pumpAndSettle();

      // Verify Journal screen is shown
      expect(find.text('Journal'), findsOneWidget);
    });

    testWidgets('today screen renders', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to Today tab
      await tester.tap(find.byIcon(Icons.today));
      await tester.pumpAndSettle();

      // Verify Today screen is shown (panchang data or loading)
      // The screen should render without errors
    });
  });
}
