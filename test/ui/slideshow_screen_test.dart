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
      photos: ['photos/k1.jpg'],
      note: 'Old town walls',
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
  openScreen(WidgetTester tester, {FakeSlideshowWriter? writer}) async {
    final slideshowWriter = writer ?? FakeSlideshowWriter();
    final files = FakeTemporaryFiles();
    final sharer = FakeFileSharer();
    await pumpApp(
      tester,
      SlideshowScreen(
        services: testServices(
          trips: FakeTripRepository([trip]),
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

      await tester.tap(find.text('Create PDF'));
      await tester.pumpAndSettle();

      final document = writer.written.single;
      expect(document.title, 'Montenegro');
      expect(document.dateText, 'Sep 26, 2026 – Sep 30, 2026');
      expect(document.factsText, startsWith('5 days · 3 places · '));
      expect(document.closingTitle, 'The route');
      expect(document.wordmark, 'Trailtale');
      expect(
        [for (final slide in document.stops) slide.name],
        ['Munich', 'Kotor', 'Budva'],
      );
      final kotor = document.stops[1];
      expect(kotor.number, 2);
      expect(kotor.dateText, 'Sep 27, 2026');
      expect(kotor.notes, ['Old town walls']);
      expect(kotor.photoPath, endsWith('photos/k1.jpg'));
      expect(document.coverPhotoPath, endsWith('photos/k1.jpg'));
    });

    testWidgets('leaves out the first and last stop', (tester) async {
      final (:writer, files: _, sharer: _) = await openScreen(tester);

      await tester.tap(find.text('Leave out first and last stop'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Create PDF'));
      await tester.pumpAndSettle();

      expect(
        [for (final slide in writer.written.single.stops) slide.name],
        ['Kotor'],
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
