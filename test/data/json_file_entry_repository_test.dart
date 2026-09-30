import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:trailtale/data/json_file_entry_repository.dart';
import 'package:trailtale/domain/entry.dart';
import 'package:trailtale/domain/geo_point.dart';

import '../support/entry_repository_contract.dart';

void main() {
  late Directory directory;
  late File file;

  setUp(() {
    directory = Directory.systemTemp.createTempSync('trailtale_entries_');
    file = File('${directory.path}/entries.json');
  });

  tearDown(() => directory.deleteSync(recursive: true));

  final breakfast = Entry(
    id: 'breakfast',
    tripId: 'lisbon',
    time: DateTime.utc(2026, 5, 1, 7, 15),
    utcOffset: const Duration(hours: 1),
    note: 'Pastéis de nata',
    placeName: 'Belém',
    location: GeoPoint(latitude: 38.6916, longitude: -9.216),
  );
  final dinner = Entry(
    id: 'dinner',
    tripId: 'lisbon',
    time: DateTime.utc(2026, 5, 1, 19),
    utcOffset: const Duration(hours: -3, minutes: -30),
    note: 'Sardines',
    photoPaths: ['photos/1.jpg', 'photos/2.png'],
  );

  group('JsonFileEntryRepository', () {
    entryRepositoryContract(() async => JsonFileEntryRepository(file));

    test('keeps saved entries for a new instance on the same file', () async {
      await JsonFileEntryRepository(file).saveEntry(breakfast);
      await JsonFileEntryRepository(file).saveEntry(dinner);

      final entries = await JsonFileEntryRepository(file)
          .watchEntries('lisbon')
          .first;

      expect(entries, [breakfast, dinner]);
    });

    test('writes a versioned format', () async {
      await JsonFileEntryRepository(file).saveEntry(breakfast);
      await JsonFileEntryRepository(file).saveEntry(dinner);

      final json = jsonDecode(file.readAsStringSync());

      expect(json, {
        'version': 2,
        'entries': [
          {
            'id': 'breakfast',
            'tripId': 'lisbon',
            'time': '2026-05-01T07:15:00.000Z',
            'utcOffsetMinutes': 60,
            'note': 'Pastéis de nata',
            'placeName': 'Belém',
            'location': {'latitude': 38.6916, 'longitude': -9.216},
            'photoPaths': <String>[],
          },
          {
            'id': 'dinner',
            'tripId': 'lisbon',
            'time': '2026-05-01T19:00:00.000Z',
            'utcOffsetMinutes': -210,
            'note': 'Sardines',
            'placeName': null,
            'location': null,
            'photoPaths': ['photos/1.jpg', 'photos/2.png'],
          },
        ],
      });
    });

    test('reads a replaced file after reload', () async {
      final repository = JsonFileEntryRepository(file);
      await repository.saveEntry(breakfast);
      file.writeAsStringSync(jsonEncode({'version': 2, 'entries': []}));

      await repository.reload();

      expect(await repository.watchEntries('lisbon').first, isEmpty);
    });

    test('reads the version 1 format without photos', () async {
      file.writeAsStringSync(
        jsonEncode({
          'version': 1,
          'entries': [
            {
              'id': 'old',
              'tripId': 'lisbon',
              'time': '2026-05-01T07:15:00.000Z',
              'utcOffsetMinutes': 60,
              'note': 'From version 1',
              'placeName': null,
              'location': null,
            },
          ],
        }),
      );

      final entries = await JsonFileEntryRepository(file)
          .watchEntries('lisbon')
          .first;

      expect(entries.single.note, 'From version 1');
      expect(entries.single.photoPaths, isEmpty);
    });

    test('refuses an unknown future version instead of losing data', () async {
      file.writeAsStringSync(jsonEncode({'version': 3, 'entries': []}));
      final repository = JsonFileEntryRepository(file);

      await expectLater(
        repository.watchEntries('lisbon').first,
        throwsStateError,
      );
      await expectLater(repository.saveEntry(dinner), throwsStateError);
      expect(jsonDecode(file.readAsStringSync())['version'], 3);
    });
  });
}
