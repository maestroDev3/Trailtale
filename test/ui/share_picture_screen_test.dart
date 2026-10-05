import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trailtale/domain/entry.dart';
import 'package:trailtale/domain/geo_point.dart';
import 'package:trailtale/domain/trip.dart';
import 'package:trailtale/ui/share_picture_screen.dart';
import 'package:trailtale/ui/widgets/trip_picture_view.dart';

import '../support/fake_backup.dart';
import '../support/fake_entry_repository.dart';
import '../support/fake_photo_gallery.dart';
import '../support/fake_temporary_files.dart';
import '../support/fake_trip_repository.dart';
import '../support/pump_app.dart';
import '../support/test_services.dart';

void main() {
  final trip = Trip(
    id: 'me',
    title: 'Montenegro',
    startDate: DateTime(2026, 9, 26),
    endDate: DateTime(2026, 9, 30),
  );
  Entry stop(
    String id,
    int day,
    String place,
    double lat,
    double lng, {
    List<String> photos = const [],
  }) => Entry(
    id: id,
    tripId: 'me',
    time: DateTime.utc(2026, 9, day, 9),
    utcOffset: Duration.zero,
    placeName: place,
    location: GeoPoint(latitude: lat, longitude: lng),
    photoPaths: photos,
  );
  final entries = [
    stop('a', 26, 'Munich', 48.1374, 11.5755),
    stop(
      'b',
      27,
      'Kotor',
      42.4247,
      18.7712,
      photos: ['photos/k1.jpg', 'photos/k2.jpg'],
    ),
    stop('c', 28, 'Budva', 42.2864, 18.84, photos: ['photos/b1.jpg']),
  ];

  /// Width and height from a PNG header.
  (int, int) pngSize(List<int> bytes) {
    final data = ByteData.sublistView(Uint8List.fromList(bytes));
    return (data.getUint32(16), data.getUint32(20));
  }

  Future<
    ({
      FakeTemporaryFiles files,
      FakeFileSharer sharer,
      FakePhotoGallery gallery,
    })
  >
  openScreen(WidgetTester tester, {Trip? shownTrip, List<Entry>? shown}) async {
    final files = FakeTemporaryFiles();
    final sharer = FakeFileSharer();
    final gallery = FakePhotoGallery();
    await pumpApp(
      tester,
      SharePictureScreen(
        services: testServices(
          trips: FakeTripRepository([trip]),
          entries: FakeEntryRepository(shown ?? entries),
          temporaryFiles: files,
          fileSharer: sharer,
          photoGallery: gallery,
        ),
        trip: shownTrip ?? trip,
      ),
    );
    // Map tiles and photos get time to load before sharing is possible.
    await tester.pump(const Duration(seconds: 2));
    return (files: files, sharer: sharer, gallery: gallery);
  }

  /// Taps [label] and lets the picture be rendered for real.
  Future<void> tapAndRender(
    WidgetTester tester,
    String label, {
    int steps = 6,
  }) async {
    await tester.tap(find.text(label));
    await tester.pump();
    // Loading photos and rendering need real time; each step continues in
    // the next frame, so alternate between real waiting and pumping.
    for (var step = 0; step < steps; step++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 150)),
      );
      await tester.pump();
    }
    await tester.pumpAndSettle();
  }

  TripPictureView preview(WidgetTester tester) =>
      tester.widget<TripPictureView>(find.byType(TripPictureView));

  group('SharePictureScreen', () {
    testWidgets('shows a preview in story format', (tester) async {
      await openScreen(tester);

      expect(find.text('Share picture'), findsOneWidget);
      expect(preview(tester).format, TripPictureFormat.story);
      expect(find.text('Kotor'), findsOneWidget);
      expect(find.text('Marker 2: Kotor'), findsOneWidget);
    });

    testWidgets('switches to the post format', (tester) async {
      await openScreen(tester);

      await tester.tap(find.text('Post'));
      await tester.pumpAndSettle();

      expect(preview(tester).format, TripPictureFormat.post);
    });

    testWidgets('leaves out the first and last stop', (tester) async {
      await openScreen(tester);

      await tester.tap(find.text('Leave out first and last stop'));
      await tester.pumpAndSettle();

      expect(
        [for (final stop in preview(tester).picture.stops) stop.name],
        ['Kotor'],
      );
      expect(find.text('Munich'), findsNothing);
    });

    testWidgets('uses the photos chosen for the picture', (tester) async {
      await openScreen(tester);
      expect(preview(tester).picture.photoPaths, [
        'photos/k1.jpg',
        'photos/b1.jpg',
        'photos/k2.jpg',
      ]);

      await tester.tap(find.text('Choose photos'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Automatic'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Choose photos'));
      await tester.pumpAndSettle();
      for (final path in ['photos/k1.jpg', 'photos/k2.jpg']) {
        await tester.tap(find.byKey(Key('picture-photo-$path')));
      }
      await tester.pumpAndSettle();
      await tester.tap(find.text('Use 1 photo'));
      await tester.pumpAndSettle();

      expect(preview(tester).picture.photoPaths, ['photos/b1.jpg']);
    });

    testWidgets('shares a full-size PNG named after the trip', (tester) async {
      final (:files, :sharer, gallery: _) = await openScreen(tester);

      await tapAndRender(tester, 'Share');

      final bytes = files.written['Montenegro.png'];
      expect(bytes, isNotNull);
      expect(pngSize(bytes!), (1080, 1920));
      expect(sharer.shared.single.path, endsWith('Montenegro.png'));
    });

    testWidgets('shares a 1080 × 1350 PNG in the post format', (tester) async {
      final (:files, sharer: _, gallery: _) = await openScreen(tester);
      await tester.tap(find.text('Post'));
      await tester.pump(const Duration(seconds: 2));

      await tapAndRender(tester, 'Share');

      expect(pngSize(files.written['Montenegro.png'] ?? const []), (
        1080,
        1350,
      ));
    });

    testWidgets('waits for the map and photos before sharing', (tester) async {
      final files = FakeTemporaryFiles();
      await pumpApp(
        tester,
        SharePictureScreen(
          services: testServices(
            trips: FakeTripRepository([trip]),
            entries: FakeEntryRepository(entries),
            temporaryFiles: files,
          ),
          trip: trip,
        ),
      );
      Widget button(String label) => tester.widget<ButtonStyleButton>(
        find.ancestor(
          of: find.text(label),
          matching: find.bySubtype<ButtonStyleButton>(),
        ),
      );

      expect((button('Share') as ButtonStyleButton).onPressed, isNull);
      await tester.pump(const Duration(milliseconds: 1600));
      expect((button('Share') as ButtonStyleButton).onPressed, isNotNull);

      await tester.tap(find.text('Post'));
      await tester.pump();
      expect(
        (button('Save to gallery') as ButtonStyleButton).onPressed,
        isNull,
      );
      await tester.pump(const Duration(milliseconds: 1600));
    });

    testWidgets('saves the picture to the gallery', (tester) async {
      final (files: _, sharer: _, :gallery) = await openScreen(tester);

      await tapAndRender(tester, 'Save to gallery');

      expect(gallery.savedImages.single.title, 'Montenegro');
      expect(pngSize(gallery.savedImages.single.bytes), (1080, 1920));
      expect(find.text('Saved to your gallery'), findsOneWidget);
    });

    testWidgets('says when saving failed', (tester) async {
      final (files: _, sharer: _, :gallery) = await openScreen(tester);
      gallery.saveSucceeds = false;

      await tapAndRender(tester, 'Save to gallery');

      expect(find.text('The picture could not be saved'), findsOneWidget);
    });

    testWidgets('disables both buttons while the picture is created', (
      tester,
    ) async {
      await openScreen(tester);

      await tester.tap(find.text('Share'));
      await tester.pump();

      for (final label in ['Share', 'Save to gallery']) {
        final button = tester.widget<ButtonStyleButton>(
          find.ancestor(
            of: find.text(label),
            matching: find.bySubtype<ButtonStyleButton>(),
          ),
        );
        expect(button.onPressed, isNull, reason: label);
      }
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 500)),
      );
      await tester.pumpAndSettle();
    });
  });

  group('SharePictureScreen carousel', () {
    Future<void> chooseCarousel(WidgetTester tester) async {
      await tester.tap(find.text('Carousel'));
      await tester.pump(const Duration(seconds: 2));
    }

    List<TripPictureView> views(WidgetTester tester) => tester
        .widgetList<TripPictureView>(find.byType(TripPictureView))
        .toList();

    testWidgets('shows the overview and one picture per day', (tester) async {
      await openScreen(tester);

      await chooseCarousel(tester);

      final shown = views(tester);
      expect(
        [for (final view in shown) view.picture.title],
        ['Montenegro', 'Day 1', 'Day 2', 'Day 3'],
      );
      expect({for (final view in shown) view.format}, {TripPictureFormat.post});
      expect(shown.first.facts, isNull);
      expect(shown[2].subtitle, 'Sunday, September 27');
      expect(shown[2].facts, '1 place');
      expect([for (final stop in shown[2].picture.stops) stop.name], ['Kotor']);
    });

    testWidgets('shares one numbered 1080 × 1350 PNG per picture together', (
      tester,
    ) async {
      final (:files, :sharer, gallery: _) = await openScreen(tester);
      await chooseCarousel(tester);

      await tapAndRender(tester, 'Share', steps: 20);

      final names = [for (var i = 1; i <= 4; i++) 'Montenegro-0$i.png'];
      expect(files.written.keys, names);
      for (final name in names) {
        expect(pngSize(files.written[name] ?? const []), (1080, 1350));
      }
      expect(
        [for (final file in sharer.sharedTogether.single) file.path],
        [for (final name in names) '/temporary/$name'],
      );
    });

    testWidgets('saves every picture to the gallery', (tester) async {
      final (files: _, sharer: _, :gallery) = await openScreen(tester);
      await chooseCarousel(tester);

      await tapAndRender(tester, 'Save to gallery', steps: 20);

      expect(
        [for (final image in gallery.savedImages) image.title],
        [for (var i = 1; i <= 4; i++) 'Montenegro-0$i'],
      );
      expect(find.text('Saved to your gallery'), findsOneWidget);
    });

    testWidgets('makes at most 20 pictures and says so', (tester) async {
      final longTrip = Trip(
        id: 'me',
        title: 'Long trip',
        startDate: DateTime(2026, 9, 1),
        endDate: DateTime(2026, 9, 25),
      );
      await openScreen(
        tester,
        shownTrip: longTrip,
        shown: [
          for (var day = 1; day <= 25; day++)
            stop('d$day', day, 'Place $day', 42 + day / 100, 18.7),
        ],
      );

      await chooseCarousel(tester);

      expect(find.byType(TripPictureView), findsNWidgets(20));
      expect(views(tester).last.picture.title, 'Day 19');
      expect(
        find.text('Instagram allows 20 pictures – the last days are left out'),
        findsOneWidget,
      );
    });
  });
}
