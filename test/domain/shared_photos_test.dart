import 'package:flutter_test/flutter_test.dart';
import 'package:trailtale/domain/geo_point.dart';
import 'package:trailtale/domain/photo_metadata.dart';
import 'package:trailtale/domain/place.dart';
import 'package:trailtale/domain/shared_photos.dart';

void main() {
  final now = DateTime(2026, 10, 6, 18);
  const offset = Duration(hours: 2);
  final kotor = GeoPoint(latitude: 42.4247, longitude: 18.7712);
  // About 300 m from Kotor's centre.
  final kotorHarbour = GeoPoint(latitude: 42.4272, longitude: 18.7700);
  // About 12 km away.
  final perast = GeoPoint(latitude: 42.4864, longitude: 18.6989);

  SharedPhoto photo(String path, int? hour, [GeoPoint? location]) =>
      SharedPhoto(
        path: path,
        metadata: PhotoMetadata(
          takenAt: hour == null ? null : DateTime(2026, 9, 27, hour),
          utcOffset: hour == null ? null : offset,
          location: location,
        ),
      );

  List<List<String>> paths(List<PhotoGroup> groups) => [
    for (final group in groups) group.photoPaths,
  ];

  group('groupSharedPhotos', () {
    test('orders photos by time; a group starts at its earliest photo', () {
      final groups = groupSharedPhotos([
        photo('b', 10, kotor),
        photo('a', 9, kotor),
      ], now: now);

      expect(paths(groups), [
        ['a', 'b'],
      ]);
      expect(groups.single.takenAt, DateTime(2026, 9, 27, 9));
      expect(groups.single.utcOffset, offset);
    });

    test('starts a new group after more than two hours', () {
      final groups = groupSharedPhotos([
        photo('a', 9, kotor),
        photo('b', 11, kotor),
        photo('c', 14, kotor),
      ], now: now);

      expect(paths(groups), [
        ['a', 'b'],
        ['c'],
      ]);
    });

    test('starts a new group more than one kilometre away', () {
      final groups = groupSharedPhotos([
        photo('a', 9, kotor),
        photo('b', 10, kotorHarbour),
        photo('c', 11, perast),
      ], now: now);

      expect(paths(groups), [
        ['a', 'b'],
        ['c'],
      ]);
      expect(groups.last.location, perast);
    });

    test('takes the first location; photos without one stay', () {
      final groups = groupSharedPhotos([
        photo('a', 9),
        photo('b', 10, kotor),
        photo('c', 11),
      ], now: now);

      expect(paths(groups), [
        ['a', 'b', 'c'],
      ]);
      expect(groups.single.location, kotor);
    });

    test('puts photos without time into a last group at now', () {
      final groups = groupSharedPhotos([
        photo('x', null, perast),
        photo('a', 9, kotor),
        photo('y', null),
      ], now: now);

      expect(paths(groups), [
        ['a'],
        ['x', 'y'],
      ]);
      expect(groups.last.takenAt, now);
      expect(groups.last.utcOffset, isNull);
      expect(groups.last.location, perast);
    });
  });

  group('entryFromGroup', () {
    test('has the instant, offset, location, place name and photos', () {
      final group = groupSharedPhotos([photo('a', 9, kotor)], now: now).single;

      final entry = entryFromGroup(
        group,
        id: 'e1',
        tripId: 'me',
        photoPaths: const ['photos/a.jpg'],
        nearestPlace: Place(
          name: 'Kotor',
          country: 'Montenegro',
          countryCode: 'ME',
          location: kotor,
          population: 13510,
        ),
      );

      expect(entry.id, 'e1');
      expect(entry.tripId, 'me');
      expect(entry.time, DateTime.utc(2026, 9, 27, 7));
      expect(entry.utcOffset, offset);
      expect(entry.location, kotor);
      expect(entry.placeName, 'Kotor');
      expect(entry.photoPaths, ['photos/a.jpg']);
    });
  });
}
