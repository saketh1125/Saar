import 'dart:math';

/// Solar / time-of-day helpers for Varanasi.
///
/// The dynamic theme morphs based on where the sun is over Kashi. We use a
/// lightweight NOAA-style approximation for sunrise/sunset good enough for
/// picking a UI palette; it is not meant for ritual-timing precision (that is
/// the Panchang worker's job server-side).
class Solar {
  Solar._();

  /// Varanasi city centre.
  static const double kashiLatitude = 25.3176;
  static const double kashiLongitude = 83.0130;

  /// Rough sunrise/sunset (local time, decimal hours) for the given day-of-year.
  /// Returns `[sunrise, sunset]`. Approximation via declination + hour angle;
  /// accurate to within a few minutes for Kashi's latitude, which is all the
  /// theme engine needs.
  static List<double> sunriseSunset({
    required int dayOfYear,
    double latitude = kashiLatitude,
    double longitude = kashiLongitude,
    double utcOffsetHours = 5.5, // IST = UTC+5:30
  }) {
    final gamma = (2 * pi / 365) * (dayOfYear - 1);
    // Solar declination (radians).
    final decl = 0.006918 -
        0.399912 * cos(gamma) +
        0.070257 * sin(gamma) -
        0.006758 * cos(2 * gamma) +
        0.000907 * sin(2 * gamma) -
        0.002697 * cos(3 * gamma) +
        0.00148 * sin(3 * gamma);
    final latRad = latitude * pi / 180;
    // -0.83° accounts for the sun's upper limb crossing the horizon.
    final cosH = (-0.83) - (sin(latRad) * sin(decl));
    final h = acos(cosH.clamp(-1.0, 1.0));
    final solarNoon = 12.0 + (longitude / 15.0) - equationOfTime(gamma);
    final solarNoonLocal = solarNoon + utcOffsetHours;
    final halfDay = (h * 180 / pi) / 15.0;
    final sunrise = solarNoonLocal - halfDay;
    final sunset = solarNoonLocal + halfDay;
    return [sunrise, sunset];
  }

  static double equationOfTime(double gamma) {
    // Equation of time in hours.
    final eotMin = 229.18 *
        (0.000075 +
            0.001868 * cos(gamma) -
            0.032077 * sin(gamma) -
            0.014615 * cos(2 * gamma) -
            0.040849 * sin(2 * gamma));
    return eotMin / 60.0;
  }

  /// Returns the day-of-year (1–366) for [dateTime].
  static int dayOfYear(DateTime dateTime) {
    final start = DateTime(dateTime.year, 1, 1);
    return dateTime.difference(start).inDays + 1;
  }
}

/// Discrete theme segments the app cycles through, in chronological order.
enum TimeOfDayPhase { sunrise, daytime, twilight, night, monsoon }

/// Picks the active palette phase for a given local [now] and whether it is
/// currently raining (monsoon override per design spec §1.1 / §4.11).
TimeOfDayPhase resolvePhase(DateTime now, {required bool isRaining}) {
  if (isRaining) return TimeOfDayPhase.monsoon;
  final doy = Solar.dayOfYear(now);
  final rs = Solar.sunriseSunset(dayOfYear: doy);
  final sunrise = rs[0];
  final sunset = rs[1];
  final h = now.hour + now.minute / 60.0;

  // Twilight window is the ~90 minutes after sunset.
  final twilightEnd = sunset + 1.5;

  if (h >= sunrise && h < 9.0) return TimeOfDayPhase.sunrise;
  if (h >= 9.0 && h < sunset) return TimeOfDayPhase.daytime;
  if (h >= sunset && h < twilightEnd) return TimeOfDayPhase.twilight;
  return TimeOfDayPhase.night;
}
