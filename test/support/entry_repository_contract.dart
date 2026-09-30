import 'package:flutter_test/flutter_test.dart';
import 'package:trailtale/domain/entry.dart';
import 'package:trailtale/domain/entry_repository.dart';
import 'package:trailtale/domain/geo_point.dart';

/// Behavior every [EntryRepository] must show, shared by the real
/// implementation and the fake so both stay interchangeable.
void entryRepositoryContract(Future<EntryRepository> Function() create) {
  final breakfast = Entry(
    id: 'breakfast',
    tripId: 'lisbon',
    time: DateTime.utc(2026, 5, 1, 7),
    utcOffset: const Duration(hours: 1),
    note: 'Pastéis de nata',
    placeName: 'Belém',
    location: GeoPoint(latitude: 38.6916, longitude: -9.2160),
  );
  final dinner = Entry(
    id: 'dinner',
    tripId: 'lisbon',
    time: DateTime.utc(2026, 5, 1, 19),
    utcOffset: const Duration(hours: 1),
    note: 'Sardines',
  );
  final hike = Entry(
    id: 'hike',
    tripId: 'alps',
    time: DateTime.utc(2026, 7, 1, 6),
    utcOffset: const Duration(hours: 2),
    placeName: 'Zermatt',
  );

  group('EntryRepository contract', () {
    test('emits an empty list when nothing is stored', () async {
      final repository = await create();

      expect(await repository.watchEntries('lisbon').first, isEmpty);
    });

    test('emits the entries of one trip in chronological order', () async {
      final repository = await create();

      await repository.saveEntry(dinner);
      await repository.saveEntry(hike);
      await repository.saveEntry(breakfast);

      expect(await repository.watchEntries('lisbon').first, [
        breakfast,
        dinner,
      ]);
      expect(await repository.watchEntries('alps').first, [hike]);
    });

    test('replaces an entry with the same id', () async {
      final repository = await create();
      await repository.saveEntry(dinner);

      await repository.saveEntry(dinner.copyWith(note: 'Grilled sardines'));

      final entries = await repository.watchEntries('lisbon').first;
      expect(entries.map((entry) => entry.note), ['Grilled sardines']);
    });

    test('deletes an entry by id and ignores unknown ids', () async {
      final repository = await create();
      await repository.saveEntry(breakfast);
      await repository.saveEntry(dinner);

      await repository.deleteEntry('breakfast');
      await repository.deleteEntry('unknown');

      expect(await repository.watchEntries('lisbon').first, [dinner]);
    });

    test('deletes all entries of a trip', () async {
      final repository = await create();
      await repository.saveEntry(breakfast);
      await repository.saveEntry(dinner);
      await repository.saveEntry(hike);

      final deleted = await repository.deleteEntriesOfTrip('lisbon');

      expect(deleted, [breakfast, dinner]);
      expect(await repository.watchEntries('lisbon').first, isEmpty);
      expect(await repository.watchEntries('alps').first, [hike]);
    });

    test('emits the entries of all trips in chronological order', () async {
      final repository = await create();

      await repository.saveEntry(hike);
      await repository.saveEntry(dinner);
      await repository.saveEntry(breakfast);

      expect(await repository.watchAllEntries().first, [
        breakfast,
        dinner,
        hike,
      ]);
    });

    test('emits all entries again after every change', () async {
      final repository = await create();
      final emissions = expectLater(
        repository.watchAllEntries(),
        emitsInOrder([
          isEmpty,
          [hike],
          [breakfast, hike],
        ]),
      );

      await repository.saveEntry(hike);
      await repository.saveEntry(breakfast);

      await emissions;
    });

    test('emits again after every change of the trip', () async {
      final repository = await create();
      final emissions = expectLater(
        repository.watchEntries('lisbon'),
        emitsInOrder([
          isEmpty,
          [dinner],
          [breakfast, dinner],
          [breakfast],
        ]),
      );

      await repository.saveEntry(dinner);
      await repository.saveEntry(breakfast);
      await repository.deleteEntry('dinner');

      await emissions;
    });

    test('emits the stored data again after reload', () async {
      final repository = await create();
      await repository.saveEntry(dinner);

      final emissions = expectLater(
        repository.watchEntries('lisbon'),
        emitsInOrder([
          [dinner],
          [dinner],
        ]),
      );
      await repository.reload();

      await emissions;
    });
  });
}
