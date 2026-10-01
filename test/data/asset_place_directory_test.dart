import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:trailtale/data/asset_place_directory.dart';
import 'package:trailtale/domain/geo_point.dart';

void main() {
  const tsv =
      'Lisbon\tPortugal\tPT\t38.7251\t-9.1498\t517802\tLisboa|Lissabon\n'
      'Porto\tPortugal\tPT\t41.1485\t-8.6110\t252687\t\n';

  group('AssetPlaceDirectory', () {
    test('reads the gzipped city list', () async {
      var loads = 0;
      final directory = AssetPlaceDirectory(
        loadBytes: () async {
          loads++;
          return gzip.encode(utf8.encode(tsv));
        },
      );

      final index = await directory.load();
      final lisbon = index.search('lissabon').single;

      expect(lisbon.name, 'Lisbon');
      expect(lisbon.country, 'Portugal');
      expect(lisbon.countryCode, 'PT');
      expect(lisbon.location.latitude, 38.7251);
      expect(lisbon.location.longitude, -9.1498);
      expect(lisbon.population, 517802);
      expect(lisbon.alternateNames, ['Lisboa', 'Lissabon']);
      expect(index.search('porto').single.alternateNames, isEmpty);

      await directory.load();
      expect(loads, 1);
    });

    test('reads the region from the eighth field', () async {
      final directory = AssetPlaceDirectory(
        loadBytes: () async => gzip.encode(
          utf8.encode(
            'Kotor\tMontenegro\tME\t42.4207\t18.7682\t5345\tCattaro\tKotor\n'
            'Budva\tMontenegro\tME\t42.2872\t18.8392\t18000\t\t\n',
          ),
        ),
      );

      final index = await directory.load();

      expect(index.search('kotor').single.region, 'Kotor');
      expect(index.search('budva').single.region, isNull);
    });
  });

  group('AssetPlaceDirectory with the bundled place list', () {
    final directory = AssetPlaceDirectory(
      loadBytes: () => File('assets/places/cities.tsv.gz').readAsBytes(),
    );

    test('finds Kotor in Montenegro first', () async {
      final kotor = (await directory.load()).search('Kotor').first;

      expect(kotor.countryCode, 'ME');
      expect(kotor.detail, endsWith('Montenegro'));
    });

    test('finds Lisbon by its German name', () async {
      final lisbon = (await directory.load()).search('Lissabon').first;

      expect(lisbon.name, 'Lisbon');
      expect(lisbon.countryCode, 'PT');
    });

    test('finds the small town of Bled', () async {
      final results = (await directory.load()).search('Bled');

      expect(results.any((place) => place.countryCode == 'SI'), isTrue);
    });

    test('names the nearest place to a position in Kotor', () async {
      final index = await directory.load();

      final nearest = index.nearest(
        GeoPoint(latitude: 42.4247, longitude: 18.7712),
      );

      expect(nearest?.name, 'Kotor');
    });

    test('searches fast enough for typing', () async {
      final index = await directory.load();
      const queries = [
        'ko',
        'kot',
        'kotor',
        'li',
        'lis',
        'new',
        'san',
        'pa',
        'ber',
        'mün',
        'bled',
        'sao p',
        'herceg n',
      ];
      index.search('warm up');

      final watch = Stopwatch()..start();
      for (final query in queries) {
        index.search(query);
      }
      watch.stop();

      expect(watch.elapsedMilliseconds / queries.length, lessThan(100));
    });
  });
}
