import 'package:flutter_test/flutter_test.dart';
import 'package:trailtale/domain/geo_point.dart';

void main() {
  final lisbon = GeoPoint(latitude: 38.7223, longitude: -9.1393);
  final porto = GeoPoint(latitude: 41.1579, longitude: -8.6291);

  group('GeoPoint', () {
    test('keeps latitude and longitude', () {
      expect(lisbon.latitude, 38.7223);
      expect(lisbon.longitude, -9.1393);
    });

    test('rejects coordinates out of range', () {
      expect(() => GeoPoint(latitude: 90.1, longitude: 0), throwsArgumentError);
      expect(
        () => GeoPoint(latitude: -90.1, longitude: 0),
        throwsArgumentError,
      );
      expect(
        () => GeoPoint(latitude: 0, longitude: 180.1),
        throwsArgumentError,
      );
      expect(
        () => GeoPoint(latitude: 0, longitude: -180.1),
        throwsArgumentError,
      );
    });

    test('allows the boundaries', () {
      expect(GeoPoint(latitude: 90, longitude: 180).latitude, 90);
      expect(GeoPoint(latitude: -90, longitude: -180).longitude, -180);
    });

    test('rejects NaN and infinite coordinates', () {
      expect(
        () => GeoPoint(latitude: double.nan, longitude: 0),
        throwsArgumentError,
      );
      expect(
        () => GeoPoint(latitude: 0, longitude: double.infinity),
        throwsArgumentError,
      );
    });

    test('trims the name and treats an empty name as missing', () {
      expect(
        GeoPoint(latitude: 0, longitude: 0, name: ' Lisbon ').name,
        'Lisbon',
      );
      expect(GeoPoint(latitude: 0, longitude: 0, name: '  ').name, isNull);
      expect(GeoPoint(latitude: 0, longitude: 0).name, isNull);
    });

    test('is equal to a point with the same values', () {
      expect(
        GeoPoint(latitude: 1, longitude: 2, name: 'A'),
        GeoPoint(latitude: 1, longitude: 2, name: 'A'),
      );
      expect(
        GeoPoint(latitude: 1, longitude: 2).hashCode,
        GeoPoint(latitude: 1, longitude: 2).hashCode,
      );
      expect(
        GeoPoint(latitude: 1, longitude: 2),
        isNot(GeoPoint(latitude: 1, longitude: 3)),
      );
    });
  });

  group('GeoPoint.distanceTo', () {
    test('returns the great-circle distance in meters', () {
      expect(lisbon.distanceTo(porto), closeTo(274296, 1000));
    });

    test('is zero to the same point', () {
      expect(lisbon.distanceTo(lisbon), 0);
    });

    test('is symmetric', () {
      expect(lisbon.distanceTo(porto), porto.distanceTo(lisbon));
    });

    test('takes the short way across the antimeridian', () {
      final west = GeoPoint(latitude: 0, longitude: 179.5);
      final east = GeoPoint(latitude: 0, longitude: -179.5);

      expect(west.distanceTo(east), closeTo(111195, 100));
    });
  });
}
