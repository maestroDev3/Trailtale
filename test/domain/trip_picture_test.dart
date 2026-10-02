import 'package:flutter_test/flutter_test.dart';
import 'package:trailtale/domain/entry.dart';
import 'package:trailtale/domain/geo_point.dart';
import 'package:trailtale/domain/trip.dart';
import 'package:trailtale/domain/trip_picture.dart';

void main() {
  final trip = Trip(
    id: 't',
    title: 'Montenegro',
    startDate: DateTime(2026, 9, 26),
    endDate: DateTime(2026, 9, 30),
  );
  final home = GeoPoint(latitude: 48.1374, longitude: 11.5755);
  final kotor = GeoPoint(latitude: 42.4247, longitude: 18.7712);
  final budva = GeoPoint(latitude: 42.2864, longitude: 18.8400);

  var counter = 0;
  Entry entry(
    int day,
    int hour, {
    String? place,
    GeoPoint? location,
    List<String> photos = const [],
    String note = '',
  }) => Entry(
    id: 'e${counter++}',
    tripId: 't',
    time: DateTime.utc(2026, 9, day, hour),
    utcOffset: Duration.zero,
    placeName: place,
    location: location,
    photoPaths: photos,
    note: note.isEmpty && place == null && location == null && photos.isEmpty
        ? 'note'
        : note,
  );

  group('buildTripPicture', () {
    test('takes title, dates and day count from the trip', () {
      final picture = buildTripPicture(trip, const [], leaveOutEnds: false);

      expect(picture.title, 'Montenegro');
      expect(picture.startDate, trip.startDate);
      expect(picture.endDate, trip.endDate);
      expect(picture.dayCount, 5);
    });

    test('lists stops in visiting order with their first location', () {
      final picture = buildTripPicture(trip, [
        entry(27, 10, place: 'Budva', location: budva),
        entry(26, 9, place: 'Kotor'),
        entry(26, 12, place: 'kotor ', location: kotor),
        entry(28, 9, place: 'Kotor', location: budva),
      ], leaveOutEnds: false);

      expect([for (final stop in picture.stops) stop.name], ['Kotor', 'Budva']);
      expect(picture.stops[0].location, kotor);
      expect(picture.stops[1].location, budva);
    });

    test('gives a stop without any located entry no location', () {
      final picture = buildTripPicture(trip, [
        entry(26, 9, place: 'Perast'),
      ], leaveOutEnds: false);

      expect(picture.stops.single.location, isNull);
    });

    test('leaves out the first and last stop', () {
      final picture = buildTripPicture(trip, [
        entry(26, 8, place: 'Munich', location: home, photos: ['photos/h.jpg']),
        entry(27, 9, place: 'Kotor', location: kotor),
        entry(28, 9, place: 'Budva', location: budva),
        entry(30, 20, place: 'Munich', location: home),
        entry(30, 21, place: 'Home again', location: home),
      ], leaveOutEnds: true);

      expect([for (final stop in picture.stops) stop.name], ['Kotor', 'Budva']);
      expect(picture.placeCount, 2);
      expect(picture.photoPaths, isEmpty);
    });

    test('keeps no stop when leaving out the ends of two stops', () {
      final picture = buildTripPicture(trip, [
        entry(26, 8, place: 'Munich', location: home),
        entry(27, 9, place: 'Kotor', location: kotor),
      ], leaveOutEnds: true);

      expect(picture.stops, isEmpty);
      expect(picture.distanceMeters, 0);
    });

    test('sums the distance between the located stops', () {
      final picture = buildTripPicture(trip, [
        entry(26, 8, place: 'Munich', location: home),
        entry(27, 9, place: 'Perast'),
        entry(27, 12, place: 'Kotor', location: kotor),
        entry(28, 9, place: 'Budva', location: budva),
      ], leaveOutEnds: false);

      expect(
        picture.distanceMeters,
        closeTo(home.distanceTo(kotor) + kotor.distanceTo(budva), 1),
      );
      expect(picture.placeCount, 4);
    });

    test('picks the first photo of different days first', () {
      final picture = buildTripPicture(trip, [
        entry(26, 9, photos: ['photos/a1.jpg', 'photos/a2.jpg']),
        entry(26, 18, photos: ['photos/a3.jpg']),
        entry(27, 9, photos: ['photos/b1.jpg', 'photos/b2.jpg']),
      ], leaveOutEnds: false);

      expect(picture.photoPaths, [
        'photos/a1.jpg',
        'photos/b1.jpg',
        'photos/a2.jpg',
        'photos/a3.jpg',
      ]);
    });

    test('spreads at most four photos over many days', () {
      final picture = buildTripPicture(trip, [
        for (var day = 26; day <= 30; day++)
          entry(day, 9, photos: ['photos/$day.jpg']),
      ], leaveOutEnds: false);

      expect(picture.photoPaths, hasLength(4));
      expect(picture.photoPaths.first, 'photos/26.jpg');
      expect(picture.photoPaths.last, 'photos/30.jpg');
    });
  });

  group('layoutRoute', () {
    test('keeps every pin inside the box with a margin', () {
      final positions = layoutRoute(
        [home, kotor, budva],
        width: 300,
        height: 200,
        margin: 20,
      );

      for (final position in positions) {
        expect(position, isNotNull);
        expect(position!.x, inInclusiveRange(20, 280));
        expect(position.y, inInclusiveRange(20, 180));
      }
    });

    test('keeps north up and east right', () {
      final [munich, kotorPin, _] = layoutRoute(
        [home, kotor, budva],
        width: 300,
        height: 300,
        margin: 20,
      );

      expect(kotorPin!.x, greaterThan(munich!.x));
      expect(kotorPin.y, greaterThan(munich.y));
    });

    test('keeps the aspect ratio and centers the route', () {
      final west = GeoPoint(latitude: 0, longitude: 0);
      final east = GeoPoint(latitude: 0, longitude: 10);

      final [a, b] = layoutRoute(
        [west, east],
        width: 300,
        height: 300,
        margin: 20,
      );

      expect(a!.x, closeTo(20, 0.001));
      expect(b!.x, closeTo(280, 0.001));
      expect(a.y, closeTo(150, 0.001));
      expect(b.y, closeTo(150, 0.001));
    });

    test('places a single stop in the center', () {
      final [only] = layoutRoute([kotor], width: 300, height: 200, margin: 20);

      expect(only!.x, 150);
      expect(only.y, 100);
    });

    test('gives stops without location no position', () {
      final positions = layoutRoute(
        [kotor, null, budva],
        width: 300,
        height: 200,
        margin: 20,
      );

      expect(positions[0], isNotNull);
      expect(positions[1], isNull);
      expect(positions[2], isNotNull);
    });
  });
}
