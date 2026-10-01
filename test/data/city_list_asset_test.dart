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
      expect(file.lengthSync(), lessThan(3 * 1024 * 1024));
      expect(
        File('pubspec.yaml').readAsStringSync(),
        contains('assets/places/cities.tsv.gz'),
      );
    });

    test('has seven fields per city', () {
      final all = rows();

      expect(all.length, greaterThan(20000));
      expect(all.every((row) => row.length == 7), isTrue);
    });

    test('contains Lisbon with its coordinates and German name', () {
      final lisbon = rows().firstWhere(
        (row) => row[0] == 'Lisbon' && row[2] == 'PT',
      );

      expect(lisbon[1], 'Portugal');
      expect(double.parse(lisbon[3]), closeTo(38.72, 0.05));
      expect(double.parse(lisbon[4]), closeTo(-9.13, 0.05));
      expect(lisbon[6].split('|'), contains('Lissabon'));
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
