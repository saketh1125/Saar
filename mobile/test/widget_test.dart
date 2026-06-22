import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kashi_nav/main.dart';

void main() {
  testWidgets('App renders with bottom navigation', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: KashiNavApp()),
    );
    await tester.pumpAndSettle();

    // The 5-tab bottom nav should be present.
    expect(find.byType(NavigationBar), findsOneWidget);
  });
}
