import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/brain/brain_screen.dart';
import '../../features/journal/journal_screen.dart';
import '../../features/map/map_screen.dart';
import '../../features/today/today_screen.dart';
import '../../features/tools/tools_screen.dart';
import 'shell_screen.dart';

/// The five primary tabs (handoff §1). The Brain acts as the primary app
/// operator: voice/agent intents call `toggle_tab` to move between these.
enum AppTab { map, today, brain, journal, tools }

final _tabRoutes = <AppTab, String>{
  AppTab.map: 'map',
  AppTab.today: 'today',
  AppTab.brain: 'brain',
  AppTab.journal: 'journal',
  AppTab.tools: 'tools',
};

/// Shell that hosts the bottom nav and renders the active tab via go_router's
/// StatefulShellRoute (preserves each tab's state).
Widget _shell(BuildContext context, GoRouterState state, StatefulNavigationShell shell) {
  return ShellScreen(shell: shell);
}

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/map',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: _shell,
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/map', builder: (_, __) => const MapScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/today', builder: (_, __) => const TodayScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/brain', builder: (_, __) => const BrainScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/journal', builder: (_, __) => const JournalScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/tools', builder: (_, __) => const ToolsScreen()),
          ]),
        ],
      ),
    ],
  );
});

/// Navigates to a tab by enum value. Used by the Brain's `toggle_tab` tool.
void goToTab(BuildContext context, AppTab tab) {
  context.go('/${_tabRoutes[tab]}');
}
