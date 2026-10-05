import 'package:flutter_test/flutter_test.dart';
import 'package:trailtale/domain/clock.dart';
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

    test('uses the chosen photos in their order', () {
      final picture = buildTripPicture(
        trip,
        [
          entry(26, 9, photos: ['photos/a.jpg', 'photos/b.jpg']),
          entry(
            27,
            9,
            photos: ['photos/c.jpg', 'photos/d.jpg', 'photos/e.jpg'],
          ),
        ],
        leaveOutEnds: false,
        chosenPhotos: const [
          'photos/e.jpg',
          'photos/missing.jpg',
          'photos/a.jpg',
          'photos/e.jpg',
          'photos/b.jpg',
          'photos/c.jpg',
          'photos/d.jpg',
        ],
      );

      expect(picture.photoPaths, [
        'photos/e.jpg',
        'photos/a.jpg',
        'photos/b.jpg',
        'photos/c.jpg',
      ]);
    });

    test('picks automatically without chosen photos', () {
      final picture = buildTripPicture(
        trip,
        [
          entry(26, 9, photos: ['photos/a.jpg']),
        ],
        leaveOutEnds: false,
        chosenPhotos: const [],
      );

      expect(picture.photoPaths, ['photos/a.jpg']);
    });

    test('leaves out only home on a round trip', () {
      final picture = buildTripPicture(trip, [
        entry(26, 8, place: 'Munich', location: home),
        entry(27, 9, place: 'Kotor', location: kotor),
        entry(28, 9, place: 'Budva', location: budva),
        entry(30, 20, place: 'Munich', location: home),
      ], leaveOutEnds: true);

      expect([for (final stop in picture.stops) stop.name], ['Kotor', 'Budva']);
    });

    test('leaves out the place of the last named entry', () {
      final picture = buildTripPicture(trip, [
        entry(26, 8, place: 'Munich', location: home),
        entry(27, 9, place: 'Kotor', location: kotor),
        entry(28, 9, place: 'Budva', location: budva),
        entry(29, 9, place: 'Kotor', location: kotor),
      ], leaveOutEnds: true);

      expect([for (final stop in picture.stops) stop.name], ['Budva']);
    });

    test('drops chosen photos of left-out stops', () {
      final picture = buildTripPicture(
        trip,
        [
          entry(26, 8, place: 'Munich', photos: ['photos/home.jpg']),
          entry(27, 9, place: 'Kotor', photos: ['photos/kotor.jpg']),
          entry(28, 9, place: 'Budva', photos: ['photos/budva.jpg']),
          entry(30, 9, place: 'Munich'),
        ],
        leaveOutEnds: true,
        chosenPhotos: const ['photos/home.jpg', 'photos/budva.jpg'],
      );

      expect(picture.photoPaths, ['photos/budva.jpg']);
    });

    test('picks automatically when no chosen photo is left', () {
      final picture = buildTripPicture(
        trip,
        [
          entry(26, 9, photos: ['photos/a.jpg']),
        ],
        leaveOutEnds: false,
        chosenPhotos: const ['photos/removed.jpg'],
      );

      expect(picture.photoPaths, ['photos/a.jpg']);
    });
  });

  group('buildDayPictures', () {
    final perast = GeoPoint(latitude: 42.4864, longitude: 18.6989);
    final days = [
      entry(26, 8, place: 'Munich', location: home, photos: ['p/home.jpg']),
      entry(27, 9, place: 'Kotor', location: kotor, photos: ['p/k1.jpg']),
      entry(27, 12, place: 'Perast', location: perast, photos: ['p/p1.jpg']),
      entry(27, 15, place: 'Kotor', photos: ['p/k2.jpg', 'p/k3.jpg']),
      entry(27, 18, photos: ['p/k4.jpg']),
      entry(28, 9, place: 'Budva', location: budva),
      entry(30, 20, place: 'Munich', location: home),
    ];

    test('has one picture per day with entries, numbered in the trip', () {
      final pictures = buildDayPictures(trip, days, leaveOutEnds: false);

      expect(
        [for (final picture in pictures) picture.day],
        [
          for (final day in [26, 27, 28, 30]) dayOf(DateTime(2026, 9, day)),
        ],
      );
      expect([for (final picture in pictures) picture.dayNumber], [1, 2, 3, 5]);
    });

    test('has the places of the day with their first location', () {
      final kotorDay = buildDayPictures(
        trip,
        days,
        leaveOutEnds: false,
      )[1].picture;

      expect(
        [for (final stop in kotorDay.stops) stop.name],
        ['Kotor', 'Perast'],
      );
      expect(kotorDay.stops.first.location, kotor);
      expect(kotorDay.placeCount, 2);
      expect(kotorDay.distanceMeters, closeTo(kotor.distanceTo(perast), 1));
    });

    test('puts the stored day title photo first, at most four photos', () {
      final pictures = buildDayPictures(
        trip.withDayCover(DateTime(2026, 9, 27), 'p/k3.jpg'),
        days,
        leaveOutEnds: false,
      );

      expect(pictures[1].picture.photoPaths, [
        'p/k3.jpg',
        'p/k1.jpg',
        'p/p1.jpg',
        'p/k2.jpg',
      ]);
      expect(pictures[0].picture.photoPaths, ['p/home.jpg']);
    });

    test('ignores left-out stops and drops days without entries', () {
      final pictures = buildDayPictures(trip, days, leaveOutEnds: true);

      expect([for (final picture in pictures) picture.dayNumber], [2, 3]);
    });
  });
}
