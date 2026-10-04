import 'package:flutter_test/flutter_test.dart';
import 'package:trailtale/domain/clock.dart';
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

  group('buildSlideshow days', () {
    List<String?> titles(Slideshow slideshow) => [
      for (final day in slideshow.days) day.titlePhotoPath,
    ];

    test('has one day slide per day with entries, numbered in the trip', () {
      final slideshow = buildSlideshow(trip, entries, leaveOutEnds: false);

      expect(
        [for (final day in slideshow.days) day.day],
        [
          for (final day in [26, 27, 28, 29, 30]) dayOf(DateTime(2026, 9, day)),
        ],
      );
      expect(
        [for (final day in slideshow.days) day.dayNumber],
        [1, 2, 3, 4, 5],
      );
    });

    test('has no day number outside the trip dates', () {
      final slideshow = buildSlideshow(trip, [
        entry(20, 9, place: 'Munich'),
      ], leaveOutEnds: false);

      expect(slideshow.days.single.dayNumber, isNull);
    });

    test('lists the places of a day in visiting order', () {
      final slideshow = buildSlideshow(trip, [
        entry(27, 8, place: 'Kotor'),
        entry(27, 12, place: 'Perast'),
        entry(27, 15, place: 'kotor'),
      ], leaveOutEnds: false);

      expect(slideshow.days.single.places, ['Kotor', 'Perast']);
    });

    test('uses the first photo of the day as title, the others as slides', () {
      final kotorDay = buildSlideshow(
        trip,
        entries,
        leaveOutEnds: false,
      ).days[1];

      expect(kotorDay.titlePhotoPath, 'p/kotor1.jpg');
      expect(
        [for (final photo in kotorDay.photos) photo.path],
        ['p/kotor2.jpg'],
      );
    });

    test('uses the stored title photo of a day while the day has it', () {
      final slideshow = buildSlideshow(
        trip
            .withDayCover(DateTime(2026, 9, 27), 'p/kotor2.jpg')
            .withDayCover(DateTime(2026, 9, 29), 'p/removed.jpg'),
        entries,
        leaveOutEnds: false,
      );

      expect(slideshow.days[1].titlePhotoPath, 'p/kotor2.jpg');
      expect(
        [for (final photo in slideshow.days[1].photos) photo.path],
        ['p/kotor1.jpg'],
      );
      expect(slideshow.days[3].titlePhotoPath, 'p/rain.jpg');
    });

    test('has no title photo on a day without photos', () {
      final slideshow = buildSlideshow(trip, entries, leaveOutEnds: false);

      expect(titles(slideshow), [
        'p/home.jpg',
        'p/kotor1.jpg',
        null,
        'p/rain.jpg',
        null,
      ]);
    });

    test('gives photo slides their place but no caption', () {
      final slideshow = buildSlideshow(trip, [
        entry(27, 8, place: 'Kotor', photos: ['p/a.jpg']),
        entry(
          27,
          9,
          place: 'Kotor',
          photos: ['p/b.jpg', 'p/c.jpg'],
          note: '  Cats everywhere ',
        ),
      ], leaveOutEnds: false);

      final photos = slideshow.days.single.photos;
      expect([for (final photo in photos) photo.path], ['p/b.jpg', 'p/c.jpg']);
      expect(photos.first.place, 'Kotor');
    });

    test(
      'puts every note of the day on the day slide, with time and place',
      () {
        final kotorDay = buildSlideshow(
          trip,
          entries,
          leaveOutEnds: false,
        ).days[1];

        expect(
          [for (final note in kotorDay.notes) note.text],
          [
            'Old town walls',
            'Cats everywhere',
            'Fish dinner',
            'Sunset at the fortress',
          ],
        );
        expect(kotorDay.notes.first.time, DateTime(2026, 9, 27, 10));
        expect(kotorDay.notes.first.place, 'Kotor');
      },
    );

    test('includes the notes of entries with photos', () {
      final day = buildSlideshow(trip, [
        entry(27, 8, place: 'Kotor', photos: ['p/a.jpg'], note: 'Arrival'),
        entry(27, 9, note: 'Car rental'),
      ], leaveOutEnds: false).days.single;

      expect(
        [for (final note in day.notes) note.text],
        ['Arrival', 'Car rental'],
      );
      expect(day.notes.last.place, isNull);
    });

    test('leaves out excluded photos, also as title photo', () {
      final slideshow = buildSlideshow(
        trip,
        entries,
        leaveOutEnds: false,
        excludedPhotos: const {'p/kotor1.jpg', 'p/rain.jpg'},
      );

      expect(slideshow.days[1].titlePhotoPath, 'p/kotor2.jpg');
      expect(slideshow.days[1].photos, isEmpty);
      expect(slideshow.days[3].titlePhotoPath, isNull);
    });

    test('ignores the left-out stops and drops days without entries', () {
      final slideshow = buildSlideshow(trip, entries, leaveOutEnds: true);

      expect([for (final day in slideshow.days) day.dayNumber], [2, 3, 4]);
      expect(slideshow.days.first.places, ['Kotor']);
    });
  });

  group('buildSlideshow stops within a day', () {
    List<String?> stopPlaces(DaySlide day) => [
      for (final stop in day.stops) stop.place,
    ];

    test('makes one stop of consecutive entries at the same place', () {
      final day = buildSlideshow(trip, [
        entry(27, 8, place: 'Kotor', note: 'Arrival'),
        entry(27, 9, place: ' kotor', note: 'Car rental'),
        entry(27, 12, place: 'Perast'),
        entry(27, 16, place: 'Kotor'),
      ], leaveOutEnds: false).days.single;

      expect(stopPlaces(day), ['Kotor', 'Perast', 'Kotor']);
      expect(day.stops.first.time, DateTime(2026, 9, 27, 10));
      expect(
        [for (final note in day.stops.first.notes) note.text],
        ['Arrival', 'Car rental'],
      );
    });

    test('adds an entry without place to the stop before it', () {
      final day = buildSlideshow(trip, [
        entry(27, 7, note: 'Breakfast'),
        entry(27, 8, place: 'Kotor'),
        entry(27, 9, note: 'Coffee'),
        entry(27, 12, place: 'Perast'),
      ], leaveOutEnds: false).days.single;

      expect(stopPlaces(day), [null, 'Kotor', 'Perast']);
      expect([for (final note in day.stops[1].notes) note.text], ['Coffee']);
    });

    test('gives a stop its first photo and the rest as photo slides', () {
      final day = buildSlideshow(trip, [
        entry(27, 8, place: 'Kotor', photos: ['p/k1.jpg', 'p/k2.jpg']),
        entry(27, 12, place: 'Perast', photos: ['p/p1.jpg', 'p/p2.jpg']),
        entry(27, 13, place: 'Perast', photos: ['p/p3.jpg']),
      ], leaveOutEnds: false).days.single;

      expect(day.titlePhotoPath, 'p/k1.jpg');
      expect(day.stops[0].photoPath, 'p/k2.jpg');
      expect(day.stops[0].photos, isEmpty);
      expect(day.stops[1].photoPath, 'p/p1.jpg');
      expect(
        [for (final photo in day.stops[1].photos) photo.path],
        ['p/p2.jpg', 'p/p3.jpg'],
      );
    });

    test('leaves out excluded photos in the stops', () {
      final day = buildSlideshow(
        trip,
        [
          entry(27, 8, place: 'Kotor', photos: ['p/k1.jpg']),
          entry(27, 12, place: 'Perast', photos: ['p/p1.jpg', 'p/p2.jpg']),
        ],
        leaveOutEnds: false,
        excludedPhotos: const {'p/p1.jpg'},
      ).days.single;

      expect(day.stops[1].photoPath, 'p/p2.jpg');
      expect(day.stops[1].photos, isEmpty);
    });

    test('keeps a day with one stop as before', () {
      final kotorDay = buildSlideshow(
        trip,
        entries,
        leaveOutEnds: false,
      ).days[1];

      expect(stopPlaces(kotorDay), ['Kotor']);
      expect(
        [for (final photo in kotorDay.photos) photo.path],
        ['p/kotor2.jpg'],
      );
      expect(kotorDay.notes, hasLength(4));
    });
  });
}
