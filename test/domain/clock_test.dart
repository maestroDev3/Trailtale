import 'package:flutter_test/flutter_test.dart';
import 'package:trailtale/domain/clock.dart';

void main() {
  group('Clock', () {
    test('can be provided as a fixed function in tests', () {
      final now = DateTime.utc(2026, 9, 29, 12);

      expect(_readTime(() => now), now);
    });
  });

  group('dayOf', () {
    test('returns midnight UTC of the calendar day', () {
      final day = dayOf(DateTime(2026, 9, 29, 14, 45, 12));

      expect(day, DateTime.utc(2026, 9, 29));
      expect(day.isUtc, isTrue);
    });

    test('returns the same day for the first and the last minute of a day', () {
      final start = dayOf(DateTime(2026, 9, 29, 0, 0));
      final end = dayOf(DateTime(2026, 9, 29, 23, 59));

      expect(start, end);
    });

    test('keeps the calendar day of a UTC value', () {
      expect(dayOf(DateTime.utc(2026, 1, 1, 23, 30)), DateTime.utc(2026, 1, 1));
    });

    test('is not shifted by the daylight saving time change in spring', () {
      final before = dayOf(DateTime(2026, 3, 28, 23, 30));
      final changeDay = dayOf(DateTime(2026, 3, 29, 23, 30));
      final after = dayOf(DateTime(2026, 3, 30, 0, 30));

      expect(changeDay, DateTime.utc(2026, 3, 29));
      expect(changeDay.difference(before), const Duration(days: 1));
      expect(after.difference(changeDay), const Duration(days: 1));
    });

    test('is not shifted by the daylight saving time change in autumn', () {
      final changeDay = dayOf(DateTime(2026, 10, 25, 2, 30));
      final next = dayOf(DateTime(2026, 10, 26, 0, 15));

      expect(changeDay, DateTime.utc(2026, 10, 25));
      expect(next.difference(changeDay), const Duration(days: 1));
    });
  });
}

DateTime _readTime(Clock clock) => clock();
