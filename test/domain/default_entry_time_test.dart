import 'package:flutter_test/flutter_test.dart';
import 'package:trailtale/domain/default_entry_time.dart';
import 'package:trailtale/domain/trip.dart';

void main() {
  final trip = Trip(
    id: 'lisbon',
    title: 'Lisbon',
    startDate: DateTime(2026, 5, 1),
    endDate: DateTime(2026, 5, 4),
  );

  group('defaultEntryTime', () {
    test('is now when today lies within the trip', () {
      final now = DateTime(2026, 5, 3, 14, 5);

      expect(defaultEntryTime(trip: trip, now: now), now);
    });

    test('is now on the first and on the last day of the trip', () {
      final first = DateTime(2026, 5, 1, 7);
      final last = DateTime(2026, 5, 4, 22, 45);

      expect(defaultEntryTime(trip: trip, now: first), first);
      expect(defaultEntryTime(trip: trip, now: last), last);
    });

    test('is the start day at the current time before the trip', () {
      final now = DateTime(2026, 4, 20, 9, 15);

      expect(
        defaultEntryTime(trip: trip, now: now),
        DateTime(2026, 5, 1, 9, 15),
      );
    });

    test('is the start day at the current time after the trip', () {
      final now = DateTime(2026, 9, 29, 10, 30);

      expect(
        defaultEntryTime(trip: trip, now: now),
        DateTime(2026, 5, 1, 10, 30),
      );
    });
  });
}
