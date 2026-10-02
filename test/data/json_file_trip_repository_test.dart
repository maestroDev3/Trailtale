import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:trailtale/data/json_file_trip_repository.dart';
import 'package:trailtale/domain/trip.dart';

import '../support/trip_repository_contract.dart';

void main() {
  late Directory directory;
  late File file;

  setUp(() {
    directory = Directory.systemTemp.createTempSync('trailtale_trips_');
    file = File('${directory.path}/trips.json');
  });

  tearDown(() => directory.deleteSync(recursive: true));

  final lisbon = Trip(
    id: 'lisbon',
    title: 'Lisbon',
    startDate: DateTime(2026, 5, 1),
    endDate: DateTime(2026, 5, 4),
  );

  group('JsonFileTripRepository', () {
    tripRepositoryContract(() async => JsonFileTripRepository(file));

    test('keeps saved trips for a new instance on the same file', () async {
      await JsonFileTripRepository(file).saveTrip(lisbon);

      final trips = await JsonFileTripRepository(file).watchTrips().first;

      expect(trips, [lisbon]);
    });

    test('writes a versioned format with calendar dates', () async {
      await JsonFileTripRepository(file).saveTrip(lisbon);

      final json = jsonDecode(file.readAsStringSync());

      expect(json, {
        'version': 1,
        'trips': [
          {
            'id': 'lisbon',
            'title': 'Lisbon',
            'startDate': '2026-05-01',
            'endDate': '2026-05-04',
          },
        ],
      });
    });

    test('stores a chosen cover photo', () async {
      final withCover = lisbon.copyWith(coverPhotoPath: 'photos/tram.jpg');
      await JsonFileTripRepository(file).saveTrip(withCover);

      final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      final stored = (json['trips'] as List).single as Map<String, dynamic>;
      final trips = await JsonFileTripRepository(file).watchTrips().first;

      expect(stored['coverPhoto'], 'photos/tram.jpg');
      expect(trips.single.coverPhotoPath, 'photos/tram.jpg');
    });

    test('reads trips without cover photo as automatic', () async {
      file.writeAsStringSync(
        jsonEncode({
          'version': 1,
          'trips': [
            {
              'id': 'lisbon',
              'title': 'Lisbon',
              'startDate': '2026-05-01',
              'endDate': '2026-05-04',
            },
          ],
        }),
      );

      final trips = await JsonFileTripRepository(file).watchTrips().first;

      expect(trips.single.coverPhotoPath, isNull);
    });

    test('reads the version 1 format', () async {
      file.writeAsStringSync(
        jsonEncode({
          'version': 1,
          'trips': [
            {
              'id': 'porto',
              'title': 'Porto',
              'startDate': '2025-10-24',
              'endDate': '2025-10-27',
            },
          ],
        }),
      );

      final trips = await JsonFileTripRepository(file).watchTrips().first;

      expect(trips, [
        Trip(
          id: 'porto',
          title: 'Porto',
          startDate: DateTime(2025, 10, 24),
          endDate: DateTime(2025, 10, 27),
        ),
      ]);
    });

    test('refuses an unknown future version instead of losing data', () async {
      file.writeAsStringSync(jsonEncode({'version': 2, 'trips': []}));
      final repository = JsonFileTripRepository(file);

      await expectLater(repository.watchTrips().first, throwsStateError);
      await expectLater(repository.saveTrip(lisbon), throwsStateError);
      expect(jsonDecode(file.readAsStringSync())['version'], 2);
    });

    test('reads a replaced file after reload', () async {
      final repository = JsonFileTripRepository(file);
      await repository.saveTrip(lisbon);
      file.writeAsStringSync(jsonEncode({'version': 1, 'trips': []}));

      await repository.reload();

      expect(await repository.watchTrips().first, isEmpty);
    });

    test('leaves no temporary file behind after writing', () async {
      await JsonFileTripRepository(file).saveTrip(lisbon);

      final names = directory
          .listSync()
          .map((entity) => entity.uri.pathSegments.last)
          .toList();

      expect(names, ['trips.json']);
    });
  });
}
