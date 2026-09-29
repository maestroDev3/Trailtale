import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:trailtale/data/storage_locations.dart';

void main() {
  group('tripsFile', () {
    test('is trips.json in the documents directory', () {
      final documents = Directory('/data/user/0/de.maestrodev.trailtale/app');

      expect(
        tripsFile(documents).path,
        '/data/user/0/de.maestrodev.trailtale/app/trips.json',
      );
    });
  });
}
