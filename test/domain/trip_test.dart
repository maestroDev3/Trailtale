import 'package:flutter_test/flutter_test.dart';
import 'package:trailtale/domain/trip.dart';

void main() {
  Trip trip({
    String id = 'trip-1',
    String title = 'Lisbon',
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return Trip(
      id: id,
      title: title,
      startDate: startDate ?? DateTime(2026, 5, 1),
      endDate: endDate ?? DateTime(2026, 5, 4),
    );
  }

  group('Trip', () {
    test('keeps id, title and dates normalized to the calendar day', () {
      final result = trip(
        startDate: DateTime(2026, 5, 1, 18, 30),
        endDate: DateTime(2026, 5, 4, 7, 15),
      );

      expect(result.id, 'trip-1');
      expect(result.title, 'Lisbon');
      expect(result.startDate, DateTime.utc(2026, 5, 1));
      expect(result.endDate, DateTime.utc(2026, 5, 4));
    });

    test('trims the title', () {
      expect(trip(title: '  Lisbon  ').title, 'Lisbon');
    });

    test('rejects an empty or whitespace-only title', () {
      expect(() => trip(title: ''), throwsArgumentError);
      expect(() => trip(title: '   '), throwsArgumentError);
    });

    test('rejects an end date before the start date', () {
      expect(
        () => trip(
          startDate: DateTime(2026, 5, 4),
          endDate: DateTime(2026, 5, 1),
        ),
        throwsArgumentError,
      );
    });

    test('allows a one-day trip', () {
      final result = trip(
        startDate: DateTime(2026, 5, 1, 8),
        endDate: DateTime(2026, 5, 1, 20),
      );

      expect(result.dayCount, 1);
    });

    test('counts the calendar days inclusively', () {
      expect(trip().dayCount, 4);
    });

    test('counts days correctly across a daylight saving time change', () {
      final result = trip(
        startDate: DateTime(2026, 3, 28),
        endDate: DateTime(2026, 3, 30),
      );

      expect(result.dayCount, 3);
    });

    test('is equal to a trip with the same values', () {
      expect(trip(), trip());
      expect(trip().hashCode, trip().hashCode);
      expect(trip(), isNot(trip(title: 'Porto')));
    });
  });

  group('Trip.copyWith', () {
    test('returns a new trip with the changed fields', () {
      final original = trip();

      final changed = original.copyWith(
        title: 'Porto',
        endDate: DateTime(2026, 5, 6),
      );

      expect(changed.id, original.id);
      expect(changed.title, 'Porto');
      expect(changed.startDate, original.startDate);
      expect(changed.endDate, DateTime.utc(2026, 5, 6));
      expect(original.title, 'Lisbon');
    });

    test('validates the changed values', () {
      expect(() => trip().copyWith(title: ' '), throwsArgumentError);
      expect(
        () => trip().copyWith(endDate: DateTime(2026, 4, 30)),
        throwsArgumentError,
      );
    });
  });

  group('Trip cover photo', () {
    final trip = Trip(
      id: 'me',
      title: 'Montenegro',
      startDate: DateTime(2026, 9, 26),
      endDate: DateTime(2026, 9, 30),
    );

    test('has no chosen cover by default', () {
      expect(trip.coverPhotoPath, isNull);
    });

    test('can set and clear the cover with copyWith', () {
      final withCover = trip.copyWith(coverPhotoPath: 'photos/kotor.jpg');

      expect(withCover.coverPhotoPath, 'photos/kotor.jpg');
      expect(
        withCover.copyWith(title: 'Boka').coverPhotoPath,
        'photos/kotor.jpg',
      );
      expect(withCover.copyWith(clearCoverPhoto: true).coverPhotoPath, isNull);
    });

    test('takes part in equality', () {
      expect(trip.copyWith(coverPhotoPath: 'photos/a.jpg'), isNot(trip));
      expect(
        trip.copyWith(coverPhotoPath: 'photos/a.jpg'),
        trip.copyWith(coverPhotoPath: 'photos/a.jpg'),
      );
    });
  });

  group('sortTripsNewestFirst', () {
    test('orders by start date descending and ties by title', () {
      final spring = trip(
        id: 'a',
        title: 'Spring',
        startDate: DateTime(2026, 3, 1),
        endDate: DateTime(2026, 3, 2),
      );
      final summerB = trip(
        id: 'b',
        title: 'Beach',
        startDate: DateTime(2026, 7, 1),
        endDate: DateTime(2026, 7, 2),
      );
      final summerA = trip(
        id: 'c',
        title: 'Alps',
        startDate: DateTime(2026, 7, 1),
        endDate: DateTime(2026, 7, 9),
      );
      final input = [spring, summerB, summerA];

      final sorted = sortTripsNewestFirst(input);

      expect(sorted, [summerA, summerB, spring]);
      expect(input, [spring, summerB, summerA]);
    });
  });
}
