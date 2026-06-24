import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/location/location_permissions.dart';
import 'core/routing/app_router.dart';
import 'core/theme/theme_controller.dart';

/// Kashi Nav — local-first, AI-agent travel companion for Varanasi.
///
/// The app does not use a static light/dark toggle; the [ThemeController]
/// resolves the palette from the sun's position over Varanasi (+ a monsoon
/// weather override) and feeds it through [AnimatedTheme] so colours morph over
/// ~30 minutes around sunset (design §4.11).
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await Firebase.initializeApp();

  // Request location permissions early so geofence + navigation work.
  await ensureLocationPermissions();

  runApp(const ProviderScope(child: KashiNavApp()));
}

class KashiNavApp extends ConsumerWidget {
  const KashiNavApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeControllerProvider).toMaterial();
    final router = ref.watch(appRouterProvider);
    return AnimatedTheme(
      data: theme,
      duration: const Duration(seconds: 5),
      curve: Curves.easeInOut,
      child: MaterialApp.router(
        title: 'Kashi Nav',
        debugShowCheckedModeBanner: false,
        theme: theme,
        routerConfig: router,
      ),
    );
  }
}
