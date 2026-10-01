import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:trailtale/data/asset_place_directory.dart';

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
  });
}
