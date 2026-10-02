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
  Entry stop(String id, int day, String place, double lat, double lng) => Entry(
    id: id,
    tripId: 'me',
    time: DateTime.utc(2026, 9, day, 9),
    utcOffset: Duration.zero,
    placeName: place,
    location: GeoPoint(latitude: lat, longitude: lng),
  );
  final entries = [
    stop('a', 26, 'Munich', 48.1374, 11.5755),
    stop('b', 27, 'Kotor', 42.4247, 18.7712),
    stop('c', 28, 'Budva', 42.2864, 18.84),
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
  openScreen(WidgetTester tester) async {
    final files = FakeTemporaryFiles();
    final sharer = FakeFileSharer();
    final gallery = FakePhotoGallery();
    await pumpApp(
      tester,
      SharePictureScreen(
        services: testServices(
          trips: FakeTripRepository([trip]),
          entries: FakeEntryRepository(entries),
          temporaryFiles: files,
          fileSharer: sharer,
          photoGallery: gallery,
        ),
        trip: trip,
      ),
    );
    return (files: files, sharer: sharer, gallery: gallery);
  }

  /// Taps [label] and lets the picture be rendered for real.
  Future<void> tapAndRender(WidgetTester tester, String label) async {
    await tester.tap(find.text(label));
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 500)),
    );
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
}
