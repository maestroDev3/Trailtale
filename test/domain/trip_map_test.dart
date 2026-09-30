import 'package:flutter_test/flutter_test.dart';
import 'package:trailtale/domain/entry.dart';
import 'package:trailtale/domain/geo_point.dart';
import 'package:trailtale/domain/trip_map.dart';

void main() {
  final lisbon = GeoPoint(latitude: 38.7223, longitude: -9.1393);
  final porto = GeoPoint(latitude: 41.1579, longitude: -8.6291);
  final sintra = GeoPoint(latitude: 38.8029, longitude: -9.3817);

  Entry entry(
    String id,
    int hour, {
    GeoPoint? location,
    String? place,
    String note = '',
  }) => Entry(
    id: id,
    tripId: 'portugal',
    time: DateTime.utc(2026, 5, 1, hour),
    utcOffset: Duration.zero,
    note: note.isEmpty && place == null && location == null ? 'x' : note,
    placeName: place,
    location: location,
  );

  group('tripMapPoints', () {
    test('numbers located entries in chronological order', () {
      final points = tripMapPoints([
        entry('porto', 18, location: porto, place: 'Porto'),
        entry('lisbon', 8, location: lisbon, place: 'Lisbon'),
        entry('lunch', 12, note: 'Lunch'),
        entry('sintra', 14, location: sintra, place: 'Sintra'),
      ]);

      expect(points.map((point) => point.number), [1, 2, 3]);
      expect(points.map((point) => point.entryId), ['lisbon', 'sintra', 'porto']);
      expect(points.first.location, lisbon);
    });

    test('labels a point with the place name, else the first note line', () {
      final points = tripMapPoints([
        entry('a', 8, location: lisbon, place: 'Lisbon', note: 'Coffee'),
        entry('b', 9, location: sintra, note: 'Palace\nin the fog'),
        entry('c', 10, location: porto),
      ]);

      expect(points.map((point) => point.label), ['Lisbon', 'Palace', '']);
    });

    test('is empty without locations', () {
      expect(tripMapPoints([entry('a', 8, note: 'Hi')]), isEmpty);
    });
  });

  group('boundsOf', () {
    test('is null without points', () {
      expect(boundsOf(const []), isNull);
    });

    test('encloses all points', () {
      final bounds = boundsOf(
        tripMapPoints([
          entry('a', 8, location: lisbon),
          entry('b', 9, location: porto),
          entry('c', 10, location: sintra),
        ]),
      );

      expect(bounds?.south, 38.7223);
      expect(bounds?.north, 41.1579);
      expect(bounds?.west, -9.3817);
      expect(bounds?.east, -8.6291);
    });

    test('gives a single point a minimum span', () {
      final bounds = boundsOf(tripMapPoints([entry('a', 8, location: lisbon)]));

      expect(bounds?.south, closeTo(38.7123, 1e-9));
      expect(bounds?.north, closeTo(38.7323, 1e-9));
      expect(bounds?.west, closeTo(-9.1493, 1e-9));
      expect(bounds?.east, closeTo(-9.1293, 1e-9));
    });
  });
}
