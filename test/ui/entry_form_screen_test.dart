import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trailtale/domain/entry.dart';
import 'package:trailtale/domain/geo_point.dart';
import 'package:trailtale/domain/photo_metadata.dart';
import 'package:trailtale/domain/trip.dart';
import 'package:trailtale/ui/entry_form_screen.dart';
import 'package:trailtale/ui/home_screen.dart';
import 'package:trailtale/ui/trip_detail_screen.dart';

import '../support/fake_entry_repository.dart';
import '../support/fake_photo_library.dart';
import '../support/fake_photo_metadata_reader.dart';
import '../support/fake_photo_picker.dart';
import '../support/fake_trip_repository.dart';
import '../support/pump_app.dart';
import '../support/test_services.dart';

void main() {
  final lisbon = Trip(
    id: 'lisbon',
    title: 'Lisbon',
    startDate: DateTime(2026, 5, 1),
    endDate: DateTime(2026, 5, 4),
  );
  final breakfast = Entry(
    id: 'breakfast',
    tripId: 'lisbon',
    time: DateTime.utc(2026, 5, 2, 7, 30),
    utcOffset: const Duration(hours: 1),
    note: 'Pastéis de nata',
    placeName: 'Belém',
  );

  Future<FakeEntryRepository> openTrip(
    WidgetTester tester, {
    List<Entry> entries = const [],
    FakePhotoLibrary? photoLibrary,
    FakePhotoPicker? photoPicker,
    FakePhotoMetadataReader? photoMetadataReader,
  }) async {
    final entryRepository = FakeEntryRepository(entries);
    await pumpApp(
      tester,
      HomeScreen(
        services: testServices(
          trips: FakeTripRepository([lisbon]),
          entries: entryRepository,
          photoLibrary: photoLibrary,
          photoPicker: photoPicker,
          photoMetadataReader: photoMetadataReader,
        ),
      ),
    );
    await tester.tap(find.text('Lisbon'));
    await tester.pumpAndSettle();
    return entryRepository;
  }

  Future<FakeEntryRepository> openNewEntryForm(
    WidgetTester tester, {
    FakePhotoLibrary? photoLibrary,
    FakePhotoPicker? photoPicker,
    FakePhotoMetadataReader? photoMetadataReader,
  }) async {
    final entries = await openTrip(
      tester,
      photoLibrary: photoLibrary,
      photoPicker: photoPicker,
      photoMetadataReader: photoMetadataReader,
    );
    await tester.tap(find.widgetWithText(FloatingActionButton, 'New entry'));
    await tester.pumpAndSettle();
    return entries;
  }

  Finder field(String label) => find.widgetWithText(TextFormField, label);

  Future<void> save(WidgetTester tester) async {
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Save'));
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();
  }

  group('EntryFormScreen for a new entry', () {
    testWidgets('defaults to the trip start day at the current time', (
      tester,
    ) async {
      await openNewEntryForm(tester);

      expect(find.byType(EntryFormScreen), findsOneWidget);
      expect(find.text('May 1, 2026'), findsOneWidget);
      expect(find.textContaining('10:30'), findsOneWidget);
    });

    testWidgets('opens a date picker and a time picker', (tester) async {
      await openNewEntryForm(tester);

      await tester.tap(find.text('May 1, 2026'));
      await tester.pumpAndSettle();
      expect(find.byType(DatePickerDialog), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      await tester.tap(find.textContaining('10:30'));
      await tester.pumpAndSettle();
      expect(find.byType(TimePickerDialog), findsOneWidget);
    });

    testWidgets('does not save without a note, a place or a photo', (
      tester,
    ) async {
      final entries = await openNewEntryForm(tester);

      await save(tester);

      expect(find.text('Add a note, a place or a photo'), findsOneWidget);
      expect(entries.entries, isEmpty);
    });

    testWidgets('requires both coordinates', (tester) async {
      final entries = await openNewEntryForm(tester);

      await tester.enterText(field('Note'), 'Tram 28');
      await tester.enterText(field('Latitude (optional)'), '38.7');
      await save(tester);

      expect(find.text('Enter both latitude and longitude'), findsOneWidget);
      expect(entries.entries, isEmpty);
    });

    testWidgets('rejects coordinates out of range', (tester) async {
      final entries = await openNewEntryForm(tester);

      await tester.enterText(field('Note'), 'Tram 28');
      await tester.enterText(field('Latitude (optional)'), '95');
      await tester.enterText(field('Longitude (optional)'), '0');
      await save(tester);

      expect(
        find.text('Latitude −90 to 90, longitude −180 to 180'),
        findsOneWidget,
      );
      expect(entries.entries, isEmpty);
    });

    testWidgets('saves a new entry and returns to the trip', (tester) async {
      final entries = await openNewEntryForm(tester);

      await tester.enterText(field('Note'), 'Tram 28');
      await tester.enterText(field('Place (optional)'), 'Alfama');
      await tester.enterText(field('Latitude (optional)'), '38.7117');
      await tester.enterText(field('Longitude (optional)'), '-9.1300');
      await save(tester);

      final local = DateTime(2026, 5, 1, 10, 30);
      expect(entries.entries, [
        Entry(
          id: 'id',
          tripId: 'lisbon',
          time: local.toUtc(),
          utcOffset: local.timeZoneOffset,
          note: 'Tram 28',
          placeName: 'Alfama',
          location: GeoPoint(latitude: 38.7117, longitude: -9.13),
        ),
      ]);
      expect(find.byType(EntryFormScreen), findsNothing);
      expect(find.byType(TripDetailScreen), findsOneWidget);
      expect(find.text('Tram 28'), findsOneWidget);
    });
  });

  group('EntryFormScreen for an existing entry', () {
    testWidgets('opens prefilled and replaces the entry when saving', (
      tester,
    ) async {
      final entries = await openTrip(tester, entries: [breakfast]);

      await tester.tap(find.text('Pastéis de nata'));
      await tester.pumpAndSettle();

      expect(find.text('Edit entry'), findsOneWidget);
      expect(find.text('May 2, 2026'), findsOneWidget);
      expect(find.text('Belém'), findsOneWidget);

      await tester.enterText(field('Note'), 'Two pastéis');
      await save(tester);

      expect(entries.entries, hasLength(1));
      expect(entries.entries.single.id, 'breakfast');
      expect(entries.entries.single.note, 'Two pastéis');
      expect(entries.entries.single.placeName, 'Belém');
    });

    testWidgets('deletes the entry after confirmation', (tester) async {
      final entries = await openTrip(tester, entries: [breakfast]);
      await tester.tap(find.text('Pastéis de nata'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Delete entry'));
      await tester.pumpAndSettle();
      expect(find.text('Delete this entry?'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(entries.entries, isEmpty);
      expect(find.byType(TripDetailScreen), findsOneWidget);
      expect(find.text('No entries yet'), findsOneWidget);
    });

    testWidgets('keeps the entry when deleting is cancelled', (tester) async {
      final entries = await openTrip(tester, entries: [breakfast]);
      await tester.tap(find.text('Pastéis de nata'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Delete entry'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();

      expect(entries.entries, [breakfast]);
      expect(find.byType(EntryFormScreen), findsOneWidget);
    });
  });

  group('EntryFormScreen photos', () {
    final withPhoto = breakfast.copyWith(photoPaths: ['photos/old.jpg']);

    Future<void> tapAddPhotos(WidgetTester tester) async {
      final button = find.widgetWithText(OutlinedButton, 'Add photos');
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
    }

    Future<void> tapRemovePhoto(WidgetTester tester) async {
      final button = find.byTooltip('Remove photo').first;
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
    }

    testWidgets('imports picked photos and shows them', (tester) async {
      final library = FakePhotoLibrary();
      final picker = FakePhotoPicker(['/gallery/a.jpg', '/gallery/b.jpg']);
      await openNewEntryForm(
        tester,
        photoLibrary: library,
        photoPicker: picker,
      );

      await tapAddPhotos(tester);

      expect(library.imported, [
        'photos/imported1.jpg',
        'photos/imported2.jpg',
      ]);
      expect(find.byTooltip('Remove photo'), findsNWidgets(2));
    });

    testWidgets('changes nothing when the picker is cancelled', (tester) async {
      final library = FakePhotoLibrary();
      final picker = FakePhotoPicker();
      await openNewEntryForm(
        tester,
        photoLibrary: library,
        photoPicker: picker,
      );

      await tapAddPhotos(tester);

      expect(picker.openCount, 1);
      expect(library.imported, isEmpty);
      expect(find.byTooltip('Remove photo'), findsNothing);
    });

    testWidgets('saves an entry with only photos', (tester) async {
      final entries = await openNewEntryForm(
        tester,
        photoPicker: FakePhotoPicker(['/gallery/a.jpg']),
      );

      await tapAddPhotos(tester);
      await save(tester);

      expect(entries.entries.single.photoPaths, ['photos/imported1.jpg']);
      expect(entries.entries.single.note, isEmpty);
    });

    testWidgets('deletes a removed photo only when saving', (tester) async {
      final library = FakePhotoLibrary();
      final entries = await openTrip(
        tester,
        entries: [withPhoto],
        photoLibrary: library,
      );
      await tester.tap(find.text('Pastéis de nata'));
      await tester.pumpAndSettle();

      await tapRemovePhoto(tester);
      expect(library.deleted, isEmpty);
      await save(tester);

      expect(entries.entries.single.photoPaths, isEmpty);
      expect(library.deleted, ['photos/old.jpg']);
    });

    testWidgets('deletes imported photos when leaving without saving', (
      tester,
    ) async {
      final library = FakePhotoLibrary();
      final entries = await openNewEntryForm(
        tester,
        photoLibrary: library,
        photoPicker: FakePhotoPicker(['/gallery/a.jpg']),
      );

      await tapAddPhotos(tester);
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();

      expect(entries.entries, isEmpty);
      expect(library.deleted, ['photos/imported1.jpg']);
    });

    testWidgets('deleting an entry deletes its photos', (tester) async {
      final library = FakePhotoLibrary();
      final entries = await openTrip(
        tester,
        entries: [withPhoto],
        photoLibrary: library,
      );
      await tester.tap(find.text('Pastéis de nata'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Delete entry'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(entries.entries, isEmpty);
      expect(library.deleted, ['photos/old.jpg']);
    });
  });

  group('EntryFormScreen details from photos', () {
    final lisbonPhoto = FakePhotoMetadataReader({
      'imported1.jpg': PhotoMetadata(
        takenAt: DateTime(2026, 5, 2, 9, 15, 30),
        utcOffset: const Duration(hours: 1),
        location: GeoPoint(latitude: 38.7128, longitude: -9.136),
      ),
    });

    Future<void> addPhoto(WidgetTester tester) async {
      final button = find.widgetWithText(OutlinedButton, 'Add photos');
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
    }

    String fieldText(WidgetTester tester, String label) =>
        tester.widget<TextFormField>(field(label)).controller?.text ?? '';

    testWidgets('fills date, time and coordinates of a new entry', (
      tester,
    ) async {
      final entries = await openNewEntryForm(
        tester,
        photoPicker: FakePhotoPicker(['/gallery/IMG_1.jpg']),
        photoMetadataReader: lisbonPhoto,
      );

      await addPhoto(tester);

      expect(find.text('May 2, 2026'), findsOneWidget);
      expect(find.textContaining('9:15'), findsOneWidget);
      expect(fieldText(tester, 'Latitude (optional)'), startsWith('38.7128'));
      expect(fieldText(tester, 'Longitude (optional)'), startsWith('-9.136'));
      expect(find.text('Date and place taken from the photo'), findsOneWidget);

      await tester.enterText(field('Note'), 'Tram 28');
      await save(tester);

      final entry = entries.entries.single;
      expect(entry.time, DateTime.utc(2026, 5, 2, 8, 15));
      expect(entry.utcOffset, const Duration(hours: 1));
      expect(entry.location?.latitude, closeTo(38.7128, 0.000001));
      expect(entry.location?.longitude, closeTo(-9.136, 0.000001));
    });

    testWidgets('keeps a date and time the user has set', (tester) async {
      await openNewEntryForm(
        tester,
        photoPicker: FakePhotoPicker(['/gallery/IMG_1.jpg']),
        photoMetadataReader: lisbonPhoto,
      );
      await tester.tap(find.textContaining('10:30'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      await addPhoto(tester);

      expect(find.text('May 1, 2026'), findsOneWidget);
      expect(find.textContaining('10:30'), findsOneWidget);
      expect(fieldText(tester, 'Latitude (optional)'), startsWith('38.7128'));
    });

    testWidgets('keeps coordinates the user has entered', (tester) async {
      await openNewEntryForm(
        tester,
        photoPicker: FakePhotoPicker(['/gallery/IMG_1.jpg']),
        photoMetadataReader: lisbonPhoto,
      );
      await tester.enterText(field('Latitude (optional)'), '41.1579');
      await tester.enterText(field('Longitude (optional)'), '-8.6291');

      await addPhoto(tester);

      expect(fieldText(tester, 'Latitude (optional)'), '41.1579');
      expect(fieldText(tester, 'Longitude (optional)'), '-8.6291');
      expect(find.text('May 2, 2026'), findsOneWidget);
    });

    testWidgets('does not change the time of an existing entry', (
      tester,
    ) async {
      await openTrip(
        tester,
        entries: [breakfast],
        photoPicker: FakePhotoPicker(['/gallery/IMG_1.jpg']),
        photoMetadataReader: FakePhotoMetadataReader({
          'imported1.jpg': PhotoMetadata(takenAt: DateTime(2026, 5, 3, 18)),
        }),
      );
      await tester.tap(find.text('Pastéis de nata'));
      await tester.pumpAndSettle();

      await addPhoto(tester);

      expect(find.text('May 2, 2026'), findsOneWidget);
    });

    testWidgets('changes nothing for a photo without metadata', (tester) async {
      await openNewEntryForm(
        tester,
        photoPicker: FakePhotoPicker(['/gallery/IMG_1.jpg']),
      );

      await addPhoto(tester);

      expect(find.text('May 1, 2026'), findsOneWidget);
      expect(fieldText(tester, 'Latitude (optional)'), isEmpty);
      expect(find.byType(SnackBar), findsNothing);
    });
  });
}
