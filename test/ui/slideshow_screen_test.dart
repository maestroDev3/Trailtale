import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trailtale/domain/entry.dart';
import 'package:trailtale/domain/geo_point.dart';
import 'package:trailtale/domain/trip.dart';
import 'package:trailtale/ui/slideshow_screen.dart';

import '../support/fake_backup.dart';
import '../support/fake_entry_repository.dart';
import '../support/fake_slideshow_writer.dart';
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
    String note = '',
  }) => Entry(
    id: id,
    tripId: 'me',
    time: DateTime.utc(2026, 9, day, 9),
    utcOffset: Duration.zero,
    placeName: place,
    location: GeoPoint(latitude: lat, longitude: lng),
    photoPaths: photos,
    note: note,
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
      note: 'Old town walls',
    ),
    stop('p', 27, 'Perast', 42.4864, 18.6989, photos: ['photos/p1.jpg']),
    Entry(
      id: 'r',
      tripId: 'me',
      time: DateTime.utc(2026, 9, 27, 21, 15),
      utcOffset: Duration.zero,
      note: 'Rainy evening',
    ),
    stop('c', 28, 'Budva', 42.2864, 18.84),
  ];

  Future<
    ({
      FakeSlideshowWriter writer,
      FakeTemporaryFiles files,
      FakeFileSharer sharer,
    })
  >
  openScreen(
    WidgetTester tester, {
    FakeSlideshowWriter? writer,
    FakeTripRepository? trips,
  }) async {
    final slideshowWriter = writer ?? FakeSlideshowWriter();
    final files = FakeTemporaryFiles();
    final sharer = FakeFileSharer();
    await pumpApp(
      tester,
      SlideshowScreen(
        services: testServices(
          trips: trips ?? FakeTripRepository([trip]),
          entries: FakeEntryRepository(entries),
          slideshowWriter: slideshowWriter,
          temporaryFiles: files,
          fileSharer: sharer,
        ),
        trip: trip,
      ),
    );
    return (writer: slideshowWriter, files: files, sharer: sharer);
  }

  Future<void> createPdf(WidgetTester tester) async {
    await tester.tap(find.text('Create PDF'));
    await tester.pumpAndSettle();
  }

  group('SlideshowScreen', () {
    testWidgets('writes the PDF and shares it', (tester) async {
      final (:writer, :files, :sharer) = await openScreen(tester);

      expect(find.text('Slideshow (PDF)'), findsOneWidget);
      await tester.tap(find.text('Create PDF'));
      await tester.pumpAndSettle();

      expect(writer.written, hasLength(1));
      expect(files.written['Montenegro.pdf'], [37, 80, 68, 70]);
      expect(sharer.shared.single.path, endsWith('Montenegro.pdf'));
    });

    testWidgets('fills the document with localized texts', (tester) async {
      final (:writer, files: _, sharer: _) = await openScreen(tester);

      await createPdf(tester);

      final document = writer.written.single;
      expect(document.title, 'Montenegro');
      expect(document.dateText, 'Sep 26, 2026 – Sep 30, 2026');
      expect(document.factsText, startsWith('5 days · 4 places · '));
      expect(document.closingTitle, 'The route');
      expect(document.wordmark, 'Trailtale');
      expect(
        [for (final stop in document.stops) stop.name],
        ['Munich', 'Kotor', 'Perast', 'Budva'],
      );
      expect(
        [for (final day in document.days) day.heading],
        ['Day 1 · Munich', 'Day 2 · Kotor · Perast', 'Day 3 · Budva'],
      );
      final kotorDay = document.days[1];
      expect(kotorDay.dateText, 'Sep 27, 2026');
      expect(kotorDay.photoPath, endsWith('photos/k1.jpg'));
      expect(
        [for (final photo in kotorDay.photos) photo.photoPath],
        [endsWith('photos/k2.jpg'), endsWith('photos/p1.jpg')],
      );
      expect(document.coverPhotoPath, endsWith('photos/k1.jpg'));
    });

    testWidgets('writes the notes of a day with time and place', (
      tester,
    ) async {
      final (:writer, files: _, sharer: _) = await openScreen(tester);

      await createPdf(tester);

      final notes = writer.written.single.days[1].notes;
      expect(notes, hasLength(2));
      expect(notes[0], matches(RegExp(r'^9:00\sAM · Kotor – Old town walls$')));
      expect(notes[1], matches(RegExp(r'^9:15\sPM – Rainy evening$')));
    });

    testWidgets('lists the days with their photos', (tester) async {
      await openScreen(tester);

      expect(find.text('Day 2 · Kotor · Perast'), findsOneWidget);
      expect(
        find.byKey(const Key('slide-photo-photos/k2.jpg')),
        findsOneWidget,
      );
    });

    testWidgets('stores the title photo chosen for a day', (tester) async {
      final trips = FakeTripRepository([trip]);
      final (:writer, files: _, sharer: _) = await openScreen(
        tester,
        trips: trips,
      );

      await tester.tap(find.byKey(const Key('day-title-2026-09-27')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('day-title-option-photos/p1.jpg')));
      await tester.pumpAndSettle();
      await createPdf(tester);

      expect(trips.trips.single.dayCoverPhotos.values, ['photos/p1.jpg']);
      expect(
        writer.written.single.days[1].photoPath,
        endsWith('photos/p1.jpg'),
      );
    });

    testWidgets('leaves out deselected photos', (tester) async {
      final (:writer, files: _, sharer: _) = await openScreen(tester);

      final photo = find.byKey(const Key('slide-photo-photos/k2.jpg'));
      await tester.ensureVisible(photo);
      await tester.tap(photo);
      await tester.pumpAndSettle();
      await createPdf(tester);

      expect(
        [
          for (final photo in writer.written.single.days[1].photos)
            photo.photoPath,
        ],
        [endsWith('photos/p1.jpg')],
      );
    });

    testWidgets('leaves out the first and last stop', (tester) async {
      final (:writer, files: _, sharer: _) = await openScreen(tester);

      await tester.tap(find.text('Leave out first and last stop'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Create PDF'));
      await tester.pumpAndSettle();

      expect(
        [for (final slide in writer.written.single.stops) slide.name],
        ['Kotor', 'Perast'],
      );
      expect(
        [for (final day in writer.written.single.days) day.heading],
        ['Day 2 · Kotor · Perast'],
      );
    });

    testWidgets('shows progress while the PDF is created', (tester) async {
      final writer = FakeSlideshowWriter()..pending = Completer<void>();
      await openScreen(tester, writer: writer);

      await tester.tap(find.text('Create PDF'));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Creating PDF…'), findsOneWidget);
      await tester.tap(find.text('Creating PDF…'));
      await tester.pump();
      expect(writer.written, hasLength(1));

      writer.pending?.complete();
      await tester.pumpAndSettle();
      expect(find.text('Create PDF'), findsOneWidget);
    });

    testWidgets('says when the slideshow could not be created', (tester) async {
      final (writer: _, files: _, :sharer) = await openScreen(
        tester,
        writer: FakeSlideshowWriter()..fails = true,
      );

      await tester.tap(find.text('Create PDF'));
      await tester.pumpAndSettle();

      expect(find.text('The slideshow could not be created'), findsOneWidget);
      expect(sharer.shared, isEmpty);
    });
  });
}
