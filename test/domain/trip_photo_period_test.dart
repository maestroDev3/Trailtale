import 'package:flutter_test/flutter_test.dart';
import 'package:trailtale/domain/photo_gallery.dart';
import 'package:trailtale/domain/trip.dart';

void main() {
  group('tripPhotoPeriod', () {
    test('covers the whole first and last day in local time', () {
      final trip = Trip(
        id: 't',
        title: 'Montenegro',
        startDate: DateTime(2026, 9, 26),
        endDate: DateTime(2026, 10, 3),
      );

      final period = tripPhotoPeriod(trip);

      expect(period.from, DateTime(2026, 9, 26));
      expect(period.until, DateTime(2026, 10, 4));
      expect(period.from.isUtc, isFalse);
    });

    test('covers a one-day trip completely', () {
      final trip = Trip(
        id: 't',
        title: 'Day trip',
        startDate: DateTime(2026, 12, 31),
        endDate: DateTime(2026, 12, 31),
      );

      final period = tripPhotoPeriod(trip);

      expect(period.from, DateTime(2026, 12, 31));
      expect(period.until, DateTime(2027));
    });
  });
}
