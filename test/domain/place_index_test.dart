import 'package:flutter_test/flutter_test.dart';
import 'package:trailtale/domain/geo_point.dart';
import 'package:trailtale/domain/place.dart';

void main() {
  Place place(
    String name,
    String country,
    double latitude,
    double longitude,
    int population, [
    List<String> alternates = const [],
  ]) => Place(
    name: name,
    country: country,
    countryCode: country.substring(0, 2).toUpperCase(),
    location: GeoPoint(latitude: latitude, longitude: longitude),
    population: population,
    alternateNames: alternates,
  );

  final lisbon = place('Lisbon', 'Portugal', 38.7251, -9.1498, 517802, [
    'Lisboa',
    'Lissabon',
  ]);
  final lisburn = place('Lisburn', 'United Kingdom', 54.5162, -6.058, 45370);
  final saoPaulo = place('São Paulo', 'Brazil', -23.5475, -46.6361, 12400232, [
    'Sao Paulo',
  ]);
  final paris = place('Paris', 'France', 48.8534, 2.3488, 2138551);
  final parisTexas = place('Paris', 'United States', 33.6609, -95.5555, 24782);
  final porto = place('Porto', 'Portugal', 41.1485, -8.611, 252687, ['Oporto']);
  final index = PlaceIndex([
    lisburn,
    porto,
    parisTexas,
    lisbon,
    saoPaulo,
    paris,
  ]);

  group('Place', () {
    test('has a label with its country', () {
      expect(lisbon.label, 'Lisbon, Portugal');
    });

    test('describes region and country', () {
      final kotor = Place(
        name: 'Kotor',
        country: 'Montenegro',
        countryCode: 'ME',
        location: GeoPoint(latitude: 42.4207, longitude: 18.7682),
        population: 5345,
        region: 'Kotor Municipality',
      );

      expect(kotor.detail, 'Kotor Municipality, Montenegro');
    });

    test('describes only the country without a region', () {
      expect(lisbon.region, isNull);
      expect(lisbon.detail, 'Portugal');
    });

    test('stores an empty region as null', () {
      final place = Place(
        name: 'Kotor',
        country: 'Montenegro',
        countryCode: 'ME',
        location: GeoPoint(latitude: 42.4207, longitude: 18.7682),
        population: 5345,
        region: '',
      );

      expect(place.region, isNull);
      expect(place.detail, 'Montenegro');
    });
  });

  group('PlaceIndex.search', () {
    test('finds places by the start of their name, most populous first', () {
      expect(index.search('lis'), [lisbon, lisburn]);
    });

    test('finds places by an alternate name', () {
      expect(index.search('Lissabon'), [lisbon]);
      expect(index.search('opor'), [porto]);
    });

    test('ignores case and accents', () {
      expect(index.search('SAO PAULO'), [saoPaulo]);
      expect(index.search('são'), [saoPaulo]);
    });

    test('finds a later word of the name', () {
      expect(index.search('paulo'), [saoPaulo]);
    });

    test('finds a later word of an alternate name', () {
      final hercegNovi = place('Herceg Novi', 'Montenegro', 42.45, 18.54, 1, [
        'Castelnuovo di Cattaro',
      ]);

      expect(PlaceIndex([hercegNovi, lisbon]).search('cattaro'), [hercegNovi]);
      expect(PlaceIndex([hercegNovi, lisbon]).search('novi'), [hercegNovi]);
    });

    test('does not match inside a word', () {
      expect(index.search('bon'), isEmpty);
    });

    test('puts exact alternate names before other matches', () {
      final lisboaVillage = place('Lisboa Nova', 'Brazil', -7, -35, 9000000);

      expect(PlaceIndex([lisboaVillage, lisbon]).search('lisboa'), [
        lisbon,
        lisboaVillage,
      ]);
    });

    test('puts exact names first', () {
      expect(index.search('paris'), [paris, parisTexas]);
      expect(index.search('Porto').first, porto);
    });

    test('needs at least two characters', () {
      expect(index.search('l'), isEmpty);
      expect(index.search(' '), isEmpty);
    });

    test('returns at most the limit', () {
      final many = PlaceIndex([
        for (var i = 0; i < 20; i++)
          place('Santa $i', 'Spain', 40, -3, 1000 + i),
      ]);

      expect(many.search('santa'), hasLength(8));
      expect(many.search('santa', limit: 3), hasLength(3));
    });
  });

  group('PlaceIndex.nearest', () {
    test('returns the closest place within 30 km', () {
      final near = index.nearest(GeoPoint(latitude: 38.71, longitude: -9.14));

      expect(near, lisbon);
    });

    test('finds a place across the 30 km latitude band edge', () {
      final near = index.nearest(GeoPoint(latitude: 38.98, longitude: -9.1498));

      expect(near, lisbon);
    });

    test('returns null when no place is within 30 km', () {
      expect(index.nearest(GeoPoint(latitude: 38.5, longitude: -12)), isNull);
    });
  });
}
