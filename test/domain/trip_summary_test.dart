import 'package:flutter_test/flutter_test.dart';
import 'package:trailtale/domain/entry.dart';
import 'package:trailtale/domain/geo_point.dart';
import 'package:trailtale/domain/trip.dart';
import 'package:trailtale/domain/trip_summary.dart';

void main() {
  final trip = Trip(
    id: 'portugal',
    title: 'Portugal',
    startDate: DateTime(2026, 5, 1),
    endDate: DateTime(2026, 5, 4),
  );
  final lisbon = GeoPoint(latitude: 38.7223, longitude: -9.1393);
  final porto = GeoPoint(latitude: 41.1579, longitude: -8.6291);

  Entry entry(
    String id,
    int hour, {
    String? place,
    GeoPoint? location,
    List<String> photos = const [],
  }) => Entry(
    id: id,
    tripId: 'portugal',
    time: DateTime.utc(2026, 5, 1, hour),
    utcOffset: const Duration(hours: 1),
    note: id,
    placeName: place,
    location: location,
    photoPaths: photos,
  );

  group('summarizeTrip', () {
    test('is empty for a trip without entries', () {
      final summary = summarizeTrip(trip, const []);

      expect(summary.dayCount, 4);
      expect(summary.entryCount, 0);
      expect(summary.placeCount, 0);
      expect(summary.photoCount, 0);
      expect(summary.distanceMeters, 0);
    });

    test('counts entries and photos', () {
      final summary = summarizeTrip(trip, [
        entry('a', 8, photos: ['photos/1.jpg', 'photos/2.jpg']),
        entry('b', 9, photos: ['photos/3.jpg']),
        entry('c', 10),
      ]);

      expect(summary.entryCount, 3);
      expect(summary.photoCount, 3);
    });

    test('counts distinct place names ignoring case and spaces', () {
      final summary = summarizeTrip(trip, [
        entry('a', 8, place: 'Lisbon'),
        entry('b', 9, place: ' lisbon '),
        entry('c', 10, place: 'Porto'),
        entry('d', 11),
      ]);

      expect(summary.placeCount, 2);
    });

    test('sums distances between located entries in time order', () {
      final summary = summarizeTrip(trip, [
        entry('back', 20, location: lisbon),
        entry('start', 8, location: lisbon),
        entry('lunch', 12),
        entry('porto', 14, location: porto),
      ]);

      expect(summary.distanceMeters, closeTo(548591, 1000));
    });

    test('is zero with fewer than two located entries', () {
      final summary = summarizeTrip(trip, [
        entry('a', 8, location: lisbon),
        entry('b', 9),
      ]);

      expect(summary.distanceMeters, 0);
    });
  });
}
