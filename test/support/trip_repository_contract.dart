import 'package:flutter_test/flutter_test.dart';
import 'package:trailtale/domain/trip.dart';
import 'package:trailtale/domain/trip_repository.dart';

/// Behavior every [TripRepository] must show, shared by the real
/// implementation and the fake so both stay interchangeable.
void tripRepositoryContract(Future<TripRepository> Function() create) {
  final lisbon = Trip(
    id: 'lisbon',
    title: 'Lisbon',
    startDate: DateTime(2026, 5, 1),
    endDate: DateTime(2026, 5, 4),
  );
  final alps = Trip(
    id: 'alps',
    title: 'Alps',
    startDate: DateTime(2026, 7, 1),
    endDate: DateTime(2026, 7, 9),
  );

  group('TripRepository contract', () {
    test('emits an empty list when nothing is stored', () async {
      final repository = await create();

      expect(await repository.watchTrips().first, isEmpty);
    });

    test('emits a saved trip', () async {
      final repository = await create();

      await repository.saveTrip(lisbon);

      expect(await repository.watchTrips().first, [lisbon]);
    });

    test('replaces a trip with the same id', () async {
      final repository = await create();
      await repository.saveTrip(lisbon);

      await repository.saveTrip(lisbon.copyWith(title: 'Lisbon and Sintra'));

      final trips = await repository.watchTrips().first;
      expect(trips.map((trip) => trip.title), ['Lisbon and Sintra']);
    });

    test('emits trips newest first', () async {
      final repository = await create();

      await repository.saveTrip(lisbon);
      await repository.saveTrip(alps);

      expect(await repository.watchTrips().first, [alps, lisbon]);
    });

    test('deletes a trip by id', () async {
      final repository = await create();
      await repository.saveTrip(lisbon);
      await repository.saveTrip(alps);

      await repository.deleteTrip('lisbon');

      expect(await repository.watchTrips().first, [alps]);
    });

    test('ignores deleting an unknown id', () async {
      final repository = await create();
      await repository.saveTrip(lisbon);

      await repository.deleteTrip('unknown');

      expect(await repository.watchTrips().first, [lisbon]);
    });

    test('emits again after every change', () async {
      final repository = await create();
      final emissions = expectLater(
        repository.watchTrips(),
        emitsInOrder([
          isEmpty,
          [lisbon],
          [alps, lisbon],
          [alps],
        ]),
      );

      await repository.saveTrip(lisbon);
      await repository.saveTrip(alps);
      await repository.deleteTrip('lisbon');

      await emissions;
    });

    test('emits the stored data again after reload', () async {
      final repository = await create();
      await repository.saveTrip(lisbon);

      final emissions = expectLater(
        repository.watchTrips(),
        emitsInOrder([
          [lisbon],
          [lisbon],
        ]),
      );
      await repository.reload();

      await emissions;
    });
  });
}
