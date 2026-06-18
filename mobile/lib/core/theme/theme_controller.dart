import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_colors.dart';
import 'solar.dart';

/// Allows the user to force a phase instead of following the clock (e.g. for
/// previewing themes in the Tools tab). `system` means "follow the sun".
enum ThemeOverride { system, sunrise, daytime, twilight, night, monsoon }

/// Builds a full Material [ThemeData] from a [KashiPalette], applying the
/// design-system typography, card shapes and brand accents.
@immutable
class KashiThemeData {
  final KashiPalette palette;

  const KashiThemeData(this.palette);

  ThemeData toMaterial([ThemeData? base]) {
    final scheme = palette.isDark
        ? ColorScheme.dark(
            primary: palette.accent,
            secondary: palette.accentSecondary,
            surface: palette.component,
            onPrimary: palette.isDark ? KashiColors.sunriseCanvas : Colors.white,
            onSurface: palette.onCanvas,
          )
        : ColorScheme.light(
            primary: palette.accent,
            secondary: palette.accentSecondary,
            surface: palette.component,
            onPrimary: Colors.white,
            onSurface: palette.onCanvas,
          );

    return ThemeData(
      useMaterial3: true,
      brightness: palette.isDark ? Brightness.dark : Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: palette.canvas,
      canvasColor: palette.canvas,
      appBarTheme: AppBarTheme(
        backgroundColor: palette.canvas,
        foregroundColor: palette.onCanvas,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: palette.component,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: palette.component,
        labelStyle: TextStyle(color: palette.onCanvas),
        side: BorderSide(color: palette.accent.withValues(alpha: 0.4)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: palette.component,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: KashiColors.terracotta,
        foregroundColor: KashiColors.sunriseCanvas,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.component,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
      textTheme: _buildTextTheme(palette),
      dividerColor: palette.onCanvas.withValues(alpha: 0.08),
    );
  }

  TextTheme _buildTextTheme(KashiPalette p) {
    final on = p.onCanvas;
    // Outfit-style for titles, Inter-style for body. We fall back to system
    // fonts when the custom families aren't bundled yet; the design system can
    // be wired up fully later via Google Fonts without touching call sites.
    const display = TextStyle(
      fontFamily: 'Outfit',
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
    );
    const body = TextStyle(
      fontFamily: 'Inter',
      fontWeight: FontWeight.w400,
      height: 1.4,
    );
    return TextTheme(
      displayLarge: display.copyWith(fontSize: 32, color: on),
      displayMedium: display.copyWith(fontSize: 24, color: on),
      headlineSmall: display.copyWith(fontSize: 20, color: on),
      titleLarge: display.copyWith(fontSize: 18, color: on),
      titleMedium: display.copyWith(fontSize: 16, color: on),
      bodyLarge: body.copyWith(fontSize: 16, color: on),
      bodyMedium: body.copyWith(fontSize: 14, color: on),
      labelLarge: body.copyWith(fontSize: 14, fontWeight: FontWeight.w600, color: on),
    );
  }
}

/// Holds the resolved palette + phase and rebuilds them whenever the clock
/// ticks past a phase boundary or the user overrides it.
class ThemeController extends StateNotifier<KashiThemeData> {
  ThemeController(this._ref) : super(_initial(_ref)) {
    _clock = _ref.read(systemClockProvider.notifier);
    _clock.addListener(_onClockTick);
  }

  final Ref _ref;
  late final SystemClock _clock;

  static KashiThemeData _initial(Ref ref) {
    final override = ref.read(themeOverrideProvider);
    final isRaining = ref.read(weatherProvider).isRaining;
    final now = ref.read(systemClockProvider);
    return KashiThemeData(_palette(override, isRaining, now));
  }

  void _onClockTick() {
    final override = _ref.read(themeOverrideProvider);
    final isRaining = _ref.read(weatherProvider).isRaining;
    final now = _clock.state;
    final palette = _palette(override, isRaining, now);
    if (palette.name != state.palette.name) {
      state = KashiThemeData(palette);
    }
  }

  static KashiPalette _palette(
    ThemeOverride override,
    bool isRaining,
    DateTime now,
  ) {
    if (override == ThemeOverride.system) {
      return _paletteFromPhase(resolvePhase(now, isRaining: isRaining));
    }
    switch (override) {
      case ThemeOverride.sunrise:
        return KashiPalette.sunrise;
      case ThemeOverride.daytime:
        return KashiPalette.daytime;
      case ThemeOverride.twilight:
        return KashiPalette.twilight;
      case ThemeOverride.night:
        return KashiPalette.night;
      case ThemeOverride.monsoon:
        return KashiPalette.monsoon;
      case ThemeOverride.system:
        return _paletteFromPhase(resolvePhase(now, isRaining: isRaining));
    }
  }

  static KashiPalette _paletteFromPhase(TimeOfDayPhase phase) {
    switch (phase) {
      case TimeOfDayPhase.sunrise:
        return KashiPalette.sunrise;
      case TimeOfDayPhase.daytime:
        return KashiPalette.daytime;
      case TimeOfDayPhase.twilight:
        return KashiPalette.twilight;
      case TimeOfDayPhase.night:
        return KashiPalette.night;
      case TimeOfDayPhase.monsoon:
        return KashiPalette.monsoon;
    }
  }

  @override
  void dispose() {
    _clock.removeListener(_onClockTick);
    super.dispose();
  }
}

/// Simple weather state used by the monsoon override. Defaults to clear.
class WeatherState {
  final bool isRaining;
  final double? temperatureC;
  const WeatherState({this.isRaining = false, this.temperatureC});
}

class WeatherNotifier extends StateNotifier<WeatherState> {
  WeatherNotifier() : super(const WeatherState());
  void setRaining(bool raining) =>
      state = WeatherState(isRaining: raining, temperatureC: state.temperatureC);
}

/// A clock that emits the current time every minute. Exposed as a provider so
/// tests can inject a fake clock.
class SystemClock extends StateNotifier<DateTime> {
  SystemClock() : super(DateTime.now()) {
    _timer = Timer.periodic(const Duration(minutes: 1), (_) => state = DateTime.now());
  }
  late final Timer _timer;
  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }
}

final systemClockProvider =
    StateNotifierProvider<SystemClock, DateTime>((ref) => SystemClock());

final themeOverrideProvider =
    StateProvider<ThemeOverride>((ref) => ThemeOverride.system);

final weatherProvider =
    StateNotifierProvider<WeatherNotifier, WeatherState>((ref) => WeatherNotifier());

final themeControllerProvider =
    StateNotifierProvider<ThemeController, KashiThemeData>((ref) => ThemeController(ref));
