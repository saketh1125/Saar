import 'package:flutter_test/flutter_test.dart';
import 'package:kashi_nav/core/theme/solar.dart';

void main() {
  group('Solar.sunriseSunset', () {
    test('returns two values with sunset after sunrise', () {
      final result = Solar.sunriseSunset(dayOfYear: 172);
      expect(result, hasLength(2));
      expect(result[1], greaterThan(result[0]));
    });

    test('returns consistent results for same day', () {
      final r1 = Solar.sunriseSunset(dayOfYear: 100);
      final r2 = Solar.sunriseSunset(dayOfYear: 100);
      expect(r1[0], r2[0]);
      expect(r1[1], r2[1]);
    });

    test('day length varies between seasons', () {
      final summer = Solar.sunriseSunset(dayOfYear: 172);
      final winter = Solar.sunriseSunset(dayOfYear: 355);
      final summerLen = summer[1] - summer[0];
      final winterLen = winter[1] - winter[0];
      expect(summerLen, isNot(equals(winterLen)));
    });
  });

  group('Solar.dayOfYear', () {
    test('returns 1 for January 1', () {
      expect(Solar.dayOfYear(DateTime(2026, 1, 1)), 1);
    });

    test('returns 365 for December 31 in non-leap year', () {
      expect(Solar.dayOfYear(DateTime(2026, 12, 31)), 365);
    });

    test('returns 366 for December 31 in leap year', () {
      expect(Solar.dayOfYear(DateTime(2028, 12, 31)), 366);
    });
  });

  group('resolvePhase', () {
    test('returns monsoon when isRaining is true', () {
      final now = DateTime(2026, 6, 16, 12, 0);
      expect(resolvePhase(now, isRaining: true), TimeOfDayPhase.monsoon);
    });

    test('returns a valid phase for any time', () {
      final times = [
        DateTime(2026, 6, 16, 2, 0),
        DateTime(2026, 6, 16, 6, 0),
        DateTime(2026, 6, 16, 12, 0),
        DateTime(2026, 6, 16, 18, 0),
        DateTime(2026, 6, 16, 22, 0),
      ];

      for (final now in times) {
        final phase = resolvePhase(now, isRaining: false);
        expect(
          phase,
          anyOf(
            equals(TimeOfDayPhase.sunrise),
            equals(TimeOfDayPhase.daytime),
            equals(TimeOfDayPhase.twilight),
            equals(TimeOfDayPhase.night),
          ),
        );
      }
    });

    test('night phase is returned for late night hours', () {
      final now = DateTime(2026, 6, 16, 2, 0);
      expect(resolvePhase(now, isRaining: false), TimeOfDayPhase.night);
    });
  });
}
