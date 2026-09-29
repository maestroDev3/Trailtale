import 'package:flutter_test/flutter_test.dart';
import 'package:trailtale/domain/delete_trip_with_entries.dart';
import 'package:trailtale/domain/entry.dart';
import 'package:trailtale/domain/trip.dart';

import '../support/fake_entry_repository.dart';
import '../support/fake_trip_repository.dart';

void main() {
  Trip trip(String id) => Trip(
    id: id,
    title: id,
    startDate: DateTime(2026, 5, 1),
    endDate: DateTime(2026, 5, 2),
  );
  Entry entry(String id, String tripId) => Entry(
    id: id,
    tripId: tripId,
    time: DateTime.utc(2026, 5, 1, 9),
    utcOffset: Duration.zero,
    note: id,
  );

  group('deleteTripWithEntries', () {
    test('deletes the trip and its entries, nothing else', () async {
      final trips = FakeTripRepository([trip('lisbon'), trip('alps')]);
      final entries = FakeEntryRepository([
        entry('a', 'lisbon'),
        entry('b', 'lisbon'),
        entry('c', 'alps'),
      ]);

      await deleteTripWithEntries(
        tripRepository: trips,
        entryRepository: entries,
        tripId: 'lisbon',
      );

      expect(trips.trips.map((trip) => trip.id), ['alps']);
      expect(entries.entries.map((entry) => entry.id), ['c']);
    });
  });
}
