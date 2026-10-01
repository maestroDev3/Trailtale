import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trailtale/ui/licenses.dart';

void main() {
  final file = File('assets/places/cities.tsv.gz');

  List<List<String>> rows() => const LineSplitter()
      .convert(utf8.decode(gzip.decode(file.readAsBytesSync())))
      .where((line) => line.isNotEmpty)
      .map((line) => line.split('\t'))
      .toList();

  group('City list asset', () {
    test('exists, is declared and stays small', () {
      expect(file.existsSync(), isTrue);
      expect(file.lengthSync(), lessThan(6 * 1024 * 1024));
      expect(
        File('pubspec.yaml').readAsStringSync(),
        contains('assets/places/cities.tsv.gz'),
      );
    });

    test('has eight fields per place', () {
      final all = rows();

      expect(all.length, greaterThan(100000));
      expect(all.every((row) => row.length == 8), isTrue);
    });

    test('is sorted by population, most populous first', () {
      final populations = [for (final row in rows()) int.parse(row[5])];

      for (var i = 1; i < populations.length; i++) {
        expect(populations[i], lessThanOrEqualTo(populations[i - 1]));
      }
    });

    for (final (name, code, latitude, longitude) in [
      ('Kotor', 'ME', 42.42, 18.77),
      ('Hallstatt', 'AT', 47.56, 13.65),
      ('Positano', 'IT', 40.63, 14.48),
    ]) {
      test('contains the small town $name', () {
        final place = rows().firstWhere(
          (row) => row[0] == name && row[2] == code,
        );

        expect(double.parse(place[3]), closeTo(latitude, 0.05));
        expect(double.parse(place[4]), closeTo(longitude, 0.05));
      });
    }

    test('contains Lisbon with its coordinates and German name', () {
      final lisbon = rows().firstWhere(
        (row) => row[0] == 'Lisbon' && row[2] == 'PT',
      );

      expect(lisbon[1], 'Portugal');
      expect(double.parse(lisbon[3]), closeTo(38.72, 0.05));
      expect(double.parse(lisbon[4]), closeTo(-9.13, 0.05));
      expect(lisbon[6].split('|'), contains('Lissabon'));
      expect(lisbon[7], 'Lisbon');
    });

    test('contains Porto', () {
      expect(rows().any((row) => row[0] == 'Porto' && row[2] == 'PT'), isTrue);
    });
  });

  group('registerPlaceDataLicense', () {
    testWidgets('adds the GeoNames attribution', (tester) async {
      registerPlaceDataLicense();

      final packages = await tester.runAsync(
        () => LicenseRegistry.licenses
            .expand((license) => license.packages)
            .toList(),
      );

      expect(packages, contains('GeoNames'));
    });
  });
}
