import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';
import '../theme/theme_controller.dart';

/// Hosts the bottom navigation and the active tab body. Reads the live theme
/// palette so the nav bar morphs with the time of day.
class ShellScreen extends ConsumerWidget {
  const ShellScreen({super.key, required this.shell});
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ref.watch(themeControllerProvider).palette;
    return Scaffold(
      body: shell,
      bottomNavigationBar: _KashiBottomNav(shell: shell, palette: palette),
    );
  }
}

class _KashiBottomNav extends StatelessWidget {
  const _KashiBottomNav({required this.shell, required this.palette});
  final StatefulNavigationShell shell;
  final KashiPalette palette;

  @override
  Widget build(BuildContext context) {
    const items = [
      NavigationDestination(icon: Icon(Icons.map_outlined), selectedIcon: Icon(Icons.map), label: 'Map'),
      NavigationDestination(icon: Icon(Icons.wb_sunny_outlined), selectedIcon: Icon(Icons.wb_sunny), label: 'Today'),
      NavigationDestination(icon: Icon(Icons.psychology_outlined), selectedIcon: Icon(Icons.psychology), label: 'Brain'),
      NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book), label: 'Journal'),
      NavigationDestination(icon: Icon(Icons.handyman_outlined), selectedIcon: Icon(Icons.handyman), label: 'Tools'),
    ];
    return NavigationBar(
      backgroundColor: palette.canvas.withValues(alpha: 0.92),
      indicatorColor: palette.accent.withValues(alpha: 0.18),
      selectedIndex: shell.currentIndex,
      onDestinationSelected: (i) =>
          shell.goBranch(i, initialLocation: i == shell.currentIndex),
      destinations: items,
    );
  }
}
