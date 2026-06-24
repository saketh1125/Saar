import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kashi_nav/core/routing/app_router.dart';
import 'package:kashi_nav/core/theme/theme_controller.dart';
import 'package:kashi_nav/data/repositories/repositories.dart';

/// Wraps a widget with the necessary providers for testing.
class TestWrapper extends StatelessWidget {
  const TestWrapper({
    super.key,
    required this.child,
    this.repoMode = RepoMode.mock,
  });

  final Widget child;
  final RepoMode repoMode;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [
        repositoryModeProvider.overrideWith((ref) {
          final controller = RepositoryModeController();
          controller.use(repoMode);
          return controller;
        }),
      ],
      child: MaterialApp(
        home: child,
      ),
    );
  }
}

/// Creates a testable version of the full app with overridden providers.
class TestableApp extends StatelessWidget {
  const TestableApp({super.key, this.repoMode = RepoMode.mock});

  final RepoMode repoMode;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [
        repositoryModeProvider.overrideWith((ref) {
          final controller = RepositoryModeController();
          controller.use(repoMode);
          return controller;
        }),
      ],
      child: const KashiNavApp(),
    );
  }
}

/// Helper to wait for async operations to complete.
Future<void> settle(WidgetTester tester) async {
  await tester.pumpAndSettle(const Duration(seconds: 2));
}

/// Helper to find text that might be in multiple places.
Finder findText(String text) => find.text(text);

/// Helper to verify a widget exists.
void expectExists(WidgetTester tester, Finder finder, {int? count}) {
  if (count != null) {
    expect(finder, findsNWidgets(count));
  } else {
    expect(finder, findsOneWidget);
  }
}
