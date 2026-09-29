import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:trailtale/data/storage_locations.dart';

void main() {
  final documents = Directory('/data/user/0/de.maestrodev.trailtale/app');

  group('tripsFile', () {
    test('is trips.json in the documents directory', () {
      expect(
        tripsFile(documents).path,
        '/data/user/0/de.maestrodev.trailtale/app/trips.json',
      );
    });
  });

  group('entriesFile', () {
    test('is entries.json in the documents directory', () {
      expect(
        entriesFile(documents).path,
        '/data/user/0/de.maestrodev.trailtale/app/entries.json',
      );
    });
  });
}
