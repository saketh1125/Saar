import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kashi_nav/main.dart';

void main() {
  testWidgets('App renders with bottom navigation', (WidgetTester tester) async {
    await tester.pumpWidget(const KashiNavApp());
    await tester.pumpAndSettle();

    // The 5-tab bottom nav should be present.
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Map'), findsWidgets);
    expect(find.text('Today'), findsWidgets);
    expect(find.text('Brain'), findsWidgets);
    expect(find.text('Journal'), findsWidgets);
    expect(find.text('Tools'), findsWidgets);
  });
}
