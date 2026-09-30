import 'package:flutter_test/flutter_test.dart';
import 'package:trailtale/domain/coordinates_input.dart';
import 'package:trailtale/domain/geo_point.dart';

void main() {
  group('parseCoordinates', () {
    test('returns no coordinates when both fields are empty', () {
      expect(parseCoordinates(' ', ''), isA<NoCoordinates>());
    });

    test('returns a point for valid numbers', () {
      final result = parseCoordinates('38.7223', '-9.1393');

      expect(
        result,
        isA<ValidCoordinates>().having(
          (valid) => valid.point,
          'point',
          GeoPoint(latitude: 38.7223, longitude: -9.1393),
        ),
      );
    });

    test('accepts a comma as decimal separator', () {
      final result = parseCoordinates('38,5', '-9,25');

      expect(
        (result as ValidCoordinates).point,
        GeoPoint(latitude: 38.5, longitude: -9.25),
      );
    });

    test('reports incomplete coordinates when only one is given', () {
      expect(
        parseCoordinates('38.7', ''),
        const InvalidCoordinates(CoordinatesError.incomplete),
      );
      expect(
        parseCoordinates('', '-9.1'),
        const InvalidCoordinates(CoordinatesError.incomplete),
      );
    });

    test('reports values that are not numbers or out of range', () {
      expect(
        parseCoordinates('north', '-9.1'),
        const InvalidCoordinates(CoordinatesError.outOfRange),
      );
      expect(
        parseCoordinates('95', '0'),
        const InvalidCoordinates(CoordinatesError.outOfRange),
      );
      expect(
        parseCoordinates('0', '-181'),
        const InvalidCoordinates(CoordinatesError.outOfRange),
      );
    });
  });
}
