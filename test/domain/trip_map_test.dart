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
      expect(points.map((point) => point.entryId), [
        'lisbon',
        'sintra',
        'porto',
      ]);
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

  group('routeLegs', () {
    MapPoint point(int number, double latitude, double longitude) => MapPoint(
      number: number,
      entryId: 'e$number',
      location: GeoPoint(latitude: latitude, longitude: longitude),
      label: '',
    );

    final lisbon = point(1, 38.7223, -9.1393);
    final sintra = point(2, 38.8029, -9.3817);
    final porto = point(3, 41.1579, -8.6291);
    final kotor = point(4, 42.4247, 18.7712);

    test('joins the points in their order', () {
      final legs = routeLegs([lisbon, sintra, porto]);

      expect(legs, hasLength(2));
      expect(legs[0].start, (latitude: 38.7223, longitude: -9.1393));
      expect(legs[0].end, (latitude: 38.8029, longitude: -9.3817));
      expect(legs[1].start, legs[0].end);
      expect(legs[1].end, (latitude: 41.1579, longitude: -8.6291));
    });

    test('has no legs with fewer than two points', () {
      expect(routeLegs([]), isEmpty);
      expect(routeLegs([lisbon]), isEmpty);
    });

    test('adds no leg for a point at the previous location', () {
      final again = point(2, 38.7223, -9.1393);

      final legs = routeLegs([lisbon, again, sintra]);

      expect(legs, hasLength(1));
      expect(legs.single.end, (latitude: 38.8029, longitude: -9.3817));
    });

    test('marks legs longer than 300 km as long', () {
      final legs = routeLegs([lisbon, porto, kotor]);

      expect(legs[0].distanceMeters, closeTo(274000, 2000));
      expect(legs[0].isLong, isFalse);
      expect(legs[1].isLong, isTrue);
      expect(longLegMeters, 300000);
    });

    test('takes the short way across the date line', () {
      final fiji = point(1, -17.7, 179.5);
      final samoa = point(2, -17.7, -179.5);

      final leg = routeLegs([fiji, samoa]).single;

      expect(leg.start.longitude, 179.5);
      expect(leg.end.longitude, closeTo(180.5, 0.000001));
      expect(leg.distanceMeters, lessThan(120000));
    });
  });
}
