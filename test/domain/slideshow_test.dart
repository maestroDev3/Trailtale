import 'package:flutter_test/flutter_test.dart';
import 'package:trailtale/domain/entry.dart';
import 'package:trailtale/domain/geo_point.dart';
import 'package:trailtale/domain/slideshow.dart';
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
  final budva = GeoPoint(latitude: 42.2864, longitude: 18.84);

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
    utcOffset: const Duration(hours: 2),
    placeName: place,
    location: location,
    photoPaths: photos,
    note: note.isEmpty && place == null && location == null && photos.isEmpty
        ? 'note'
        : note,
  );

  final entries = [
    entry(26, 6, place: 'Munich', location: home, photos: ['p/home.jpg']),
    entry(27, 8, place: 'Kotor', location: kotor, note: 'Old town walls'),
    entry(27, 12, place: 'kotor ', photos: ['p/kotor1.jpg', 'p/kotor2.jpg']),
    entry(27, 15, place: 'Kotor', note: 'Cats everywhere'),
    entry(27, 18, place: 'Kotor', note: 'Fish dinner'),
    entry(27, 20, place: 'Kotor', note: 'Sunset at the fortress'),
    entry(28, 10, place: 'Budva', location: budva, note: '  '),
    entry(29, 9, note: 'Rainy day', photos: ['p/rain.jpg']),
    entry(30, 20, place: 'Munich', location: home, note: 'Home again'),
  ];

  group('buildSlideshow', () {
    test('has one numbered slide per stop in visiting order', () {
      final slideshow = buildSlideshow(trip, entries, leaveOutEnds: false);

      expect(
        [for (final slide in slideshow.stops) slide.name],
        ['Munich', 'Kotor', 'Budva'],
      );
      expect([for (final slide in slideshow.stops) slide.number], [1, 2, 3]);
    });

    test('gives a stop slide its first visit, first photo and notes', () {
      final kotorSlide = buildSlideshow(
        trip,
        entries,
        leaveOutEnds: false,
      ).stops[1];

      expect(kotorSlide.firstVisit, DateTime(2026, 9, 27, 10));
      expect(kotorSlide.photoPath, 'p/kotor1.jpg');
      expect(kotorSlide.notes, [
        'Old town walls',
        'Cats everywhere',
        'Fish dinner',
      ]);
    });

    test('gives a stop without photos and notes none', () {
      final budvaSlide = buildSlideshow(
        trip,
        entries,
        leaveOutEnds: false,
      ).stops[2];

      expect(budvaSlide.photoPath, isNull);
      expect(budvaSlide.notes, isEmpty);
    });

    test('uses the chosen cover, else the automatic one', () {
      expect(
        buildSlideshow(trip, entries, leaveOutEnds: false).coverPhotoPath,
        'p/home.jpg',
      );
      expect(
        buildSlideshow(
          trip.copyWith(coverPhotoPath: 'p/kotor2.jpg'),
          entries,
          leaveOutEnds: false,
        ).coverPhotoPath,
        'p/kotor2.jpg',
      );
    });

    test('leaves out the first and last stop, also on round trips', () {
      final slideshow = buildSlideshow(trip, entries, leaveOutEnds: true);

      expect(
        [for (final slide in slideshow.stops) slide.name],
        ['Kotor', 'Budva'],
      );
      expect([for (final slide in slideshow.stops) slide.number], [1, 2]);
    });

    test(
      'replaces a cover of a left-out stop by the first remaining photo',
      () {
        final slideshow = buildSlideshow(trip, entries, leaveOutEnds: true);

        expect(slideshow.coverPhotoPath, 'p/kotor1.jpg');
      },
    );

    test('has the same figures as the trip picture', () {
      for (final leaveOutEnds in [false, true]) {
        final slideshow = buildSlideshow(
          trip,
          entries,
          leaveOutEnds: leaveOutEnds,
        );
        final picture = buildTripPicture(
          trip,
          entries,
          leaveOutEnds: leaveOutEnds,
        );

        expect(slideshow.overview.dayCount, picture.dayCount);
        expect(slideshow.overview.placeCount, picture.placeCount);
        expect(slideshow.overview.distanceMeters, picture.distanceMeters);
      }
    });
  });
}
