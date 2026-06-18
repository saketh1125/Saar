import 'package:flutter/material.dart';

/// Design tokens for Kashi Nav.
///
/// The app does NOT use a static light/dark toggle. Instead the palette morphs
/// with the local time of day in Varanasi (sunrise / daytime / twilight / night)
/// plus a monsoon rain weather override. See [ThemeController] and the matrix in
/// `kashi_nav_ui_design.md` §1.1.
class KashiColors {
  KashiColors._();

  // Brand accents (consistent across themes) -------------------------------
  static const saffronGold = Color(0xFFF39C12);
  static const terracotta = Color(0xFFD35400);
  static const dustyOrange = Color(0xFFE67E22);
  static const neonSaffron = Color(0xFFFFB93C);
  static const riverJade = Color(0xFF16A085);
  static const deepIndigo = Color(0xFF2C3E50);
  static const slateGrey = Color(0xFF34495E);
  static const stormyBlue = Color(0xFF455A64);

  // Canvas + component colours, per time-of-day state ----------------------
  // Sunrise 05:00–09:00
  static const sunriseCanvas = Color(0xFFFDFEFE); // Clay White
  static const sunriseComponent = Color(0xFFFAEDCD); // Soft Peach

  // Daytime 09:00–18:00
  static const dayCanvas = Color(0xFFFAF0E6); // Warm Paper
  static const dayComponent = Color(0xFFF5EBE6); // Dune Cream

  // Twilight 18:00–19:30
  static const twilightCanvas = Color(0xFF2E3A4E); // Dusk Slate
  static const twilightComponent = Color(0xFF1E2736); // Night Card

  // Night 19:30–05:00
  static const nightCanvas = Color(0xFF0E1620); // Deep Blue
  static const nightComponent = Color(0xFF1A2635); // Dark Slate

  // Monsoon (weather override)
  static const monsoonCanvas = Color(0xFFECEFF1); // Mist Grey
  static const monsoonComponent = Color(0xFFCFD8DC); // Slate Card
}

/// The five themed palettes the app cycles through. Each carries the canvas
/// (scaffold background), component (card) colour, the primary brand accent,
/// and whether the surface is dark (so text contrast flips to clay-white).
@immutable
class KashiPalette {
  final String name;
  final Color canvas;
  final Color component;
  final Color accent;
  final Color accentSecondary;
  final bool isDark;

  const KashiPalette({
    required this.name,
    required this.canvas,
    required this.component,
    required this.accent,
    required this.accentSecondary,
    required this.isDark,
  });

  static const sunrise = KashiPalette(
    name: 'Sunrise',
    canvas: KashiColors.sunriseCanvas,
    component: KashiColors.sunriseComponent,
    accent: KashiColors.saffronGold,
    accentSecondary: KashiColors.terracotta,
    isDark: false,
  );

  static const daytime = KashiPalette(
    name: 'Daytime',
    canvas: KashiColors.dayCanvas,
    component: KashiColors.dayComponent,
    accent: KashiColors.terracotta,
    accentSecondary: KashiColors.slateGrey,
    isDark: false,
  );

  static const twilight = KashiPalette(
    name: 'Twilight',
    canvas: KashiColors.twilightCanvas,
    component: KashiColors.twilightComponent,
    accent: KashiColors.dustyOrange,
    accentSecondary: KashiColors.deepIndigo,
    isDark: true,
  );

  static const night = KashiPalette(
    name: 'Night',
    canvas: KashiColors.nightCanvas,
    component: KashiColors.nightComponent,
    accent: KashiColors.neonSaffron,
    accentSecondary: KashiColors.sunriseCanvas, // Clay White
    isDark: true,
  );

  static const monsoon = KashiPalette(
    name: 'Monsoon',
    canvas: KashiColors.monsoonCanvas,
    component: KashiColors.monsoonComponent,
    accent: KashiColors.stormyBlue,
    accentSecondary: KashiColors.riverJade,
    isDark: false,
  );

  /// Text colour that contrasts with the canvas.
  Color get onCanvas => isDark ? KashiColors.sunriseCanvas : KashiColors.slateGrey;

  /// Slightly muted variant for secondary text.
  Color get onCanvasMuted =>
      isDark ? const Color(0xB3FDFEFE) : const Color(0xB334495E);
}
