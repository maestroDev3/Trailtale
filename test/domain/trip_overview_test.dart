import 'package:flutter_test/flutter_test.dart';
import 'package:trailtale/domain/entry.dart';
import 'package:trailtale/domain/trip.dart';
import 'package:trailtale/domain/trip_overview.dart';

void main() {
  Entry entry(String id, int day, {List<String> photos = const []}) => Entry(
    id: id,
    tripId: 'portugal',
    time: DateTime.utc(2026, 5, day, 9),
    utcOffset: const Duration(hours: 1),
    note: id,
    photoPaths: photos,
  );

  group('coverPhotoOf', () {
    test('is null without photos', () {
      expect(coverPhotoOf(const []), isNull);
      expect(coverPhotoOf([entry('a', 1)]), isNull);
    });

    test('is the first photo of the earliest entry with photos', () {
      final cover = coverPhotoOf([
        entry('late', 3, photos: ['photos/late.jpg']),
        entry('early', 1),
        entry('middle', 2, photos: ['photos/first.jpg', 'photos/second.jpg']),
      ]);

      expect(cover, 'photos/first.jpg');
    });

    test('is the chosen photo while an entry has it', () {
      final cover = coverPhotoOf([
        entry('early', 1, photos: ['photos/first.jpg']),
        entry('late', 3, photos: ['photos/a.jpg', 'photos/kotor.jpg']),
      ], chosen: 'photos/kotor.jpg');

      expect(cover, 'photos/kotor.jpg');
    });

    test('falls back to the first photo when the chosen one is gone', () {
      final cover = coverPhotoOf([
        entry('early', 1, photos: ['photos/first.jpg']),
      ], chosen: 'photos/removed.jpg');

      expect(cover, 'photos/first.jpg');
    });
  });

  group('buildTripOverviews', () {
    test('uses the cover chosen for the trip', () {
      final trip = Trip(
        id: 'portugal',
        title: 'Portugal',
        startDate: DateTime(2026, 5, 1),
        endDate: DateTime(2026, 5, 4),
        coverPhotoPath: 'photos/b.jpg',
      );

      final overviews = buildTripOverviews(
        [trip],
        [
          entry('one', 1, photos: ['photos/a.jpg', 'photos/b.jpg']),
        ],
        today: DateTime(2026, 9, 1),
      );

      expect(overviews.others.single.coverPhoto, 'photos/b.jpg');
    });
  });

  group('tripProgress', () {
    final trip = Trip(
      id: 'portugal',
      title: 'Portugal',
      startDate: DateTime(2026, 5, 1),
      endDate: DateTime(2026, 5, 9),
    );

    test('is upcoming before the start with the days until then', () {
      expect(
        tripProgress(trip, today: DateTime(2026, 4, 28, 23, 50)),
        const UpcomingTrip(daysUntilStart: 3),
      );
    });

    test('is running on the first day as day 1', () {
      expect(
        tripProgress(trip, today: DateTime(2026, 5, 1, 0, 5)),
        const RunningTrip(dayNumber: 1, dayCount: 9),
      );
    });

    test('is running in the middle of the trip', () {
      expect(
        tripProgress(trip, today: DateTime(2026, 5, 4, 12)),
        const RunningTrip(dayNumber: 4, dayCount: 9),
      );
    });

    test('is running on the last day as day n of n', () {
      expect(
        tripProgress(trip, today: DateTime(2026, 5, 9, 23, 59)),
        const RunningTrip(dayNumber: 9, dayCount: 9),
      );
    });

    test('is past the day after the end', () {
      expect(
        tripProgress(trip, today: DateTime(2026, 5, 10)),
        const PastTrip(),
      );
    });
  });
}
