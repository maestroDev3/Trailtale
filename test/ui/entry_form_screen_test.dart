import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trailtale/domain/entry.dart';
import 'package:trailtale/domain/geo_point.dart';
import 'package:trailtale/domain/photo_gallery.dart';
import 'package:trailtale/domain/photo_metadata.dart';
import 'package:trailtale/domain/place.dart';
import 'package:trailtale/domain/trip.dart';
import 'package:trailtale/ui/entry_form_screen.dart';
import 'package:trailtale/ui/home_screen.dart';
import 'package:trailtale/ui/trip_detail_screen.dart';

import '../support/fake_entry_repository.dart';
import '../support/fake_photo_gallery.dart';
import '../support/fake_photo_library.dart';
import '../support/fake_photo_metadata_reader.dart';
import '../support/fake_photo_picker.dart';
import '../support/fake_place_directory.dart';
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
    FakePhotoGallery? photoGallery,
    FakePlaceDirectory? placeDirectory,
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
          photoGallery: photoGallery,
          placeDirectory: placeDirectory,
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
    FakePlaceDirectory? placeDirectory,
  }) async {
    final entries = await openTrip(
      tester,
      photoLibrary: photoLibrary,
      photoPicker: photoPicker,
      photoMetadataReader: photoMetadataReader,
      placeDirectory: placeDirectory,
    );
    await tester.tap(find.widgetWithText(FloatingActionButton, 'New entry'));
    await tester.pumpAndSettle();
    return entries;
  }

  Finder field(String label) => find.widgetWithText(TextFormField, label);

  Future<void> showCoordinates(WidgetTester tester) async {
    if (field('Latitude (optional)').evaluate().isNotEmpty) return;
    await tester.ensureVisible(find.text('Coordinates'));
    await tester.tap(find.text('Coordinates'));
    await tester.pumpAndSettle();
  }

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
      await showCoordinates(tester);
      await tester.enterText(field('Latitude (optional)'), '38.7');
      await save(tester);

      expect(find.text('Enter both latitude and longitude'), findsOneWidget);
      expect(entries.entries, isEmpty);
    });

    testWidgets('rejects coordinates out of range', (tester) async {
      final entries = await openNewEntryForm(tester);

      await tester.enterText(field('Note'), 'Tram 28');
      await showCoordinates(tester);
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
      await showCoordinates(tester);
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
      await showCoordinates(tester);
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
      await showCoordinates(tester);
      expect(fieldText(tester, 'Latitude (optional)'), startsWith('38.7128'));
    });

    testWidgets('keeps coordinates the user has entered', (tester) async {
      await openNewEntryForm(
        tester,
        photoPicker: FakePhotoPicker(['/gallery/IMG_1.jpg']),
        photoMetadataReader: lisbonPhoto,
      );
      await showCoordinates(tester);
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
      await showCoordinates(tester);
      expect(fieldText(tester, 'Latitude (optional)'), isEmpty);
      expect(find.text('This photo has no location'), findsOneWidget);
    });

    testWidgets('says when the photo has a date but no location', (
      tester,
    ) async {
      await openNewEntryForm(
        tester,
        photoPicker: FakePhotoPicker(['/gallery/IMG_1.jpg']),
        photoMetadataReader: FakePhotoMetadataReader({
          'imported1.jpg': PhotoMetadata(takenAt: DateTime(2026, 5, 2, 9)),
        }),
      );

      await addPhoto(tester);

      expect(
        find.text('Date taken from the photo – it has no location'),
        findsOneWidget,
      );
    });

    testWidgets('does not complain about a missing location when coordinates '
        'are set', (tester) async {
      await openNewEntryForm(
        tester,
        photoPicker: FakePhotoPicker(['/gallery/IMG_1.jpg']),
      );
      await showCoordinates(tester);
      await tester.enterText(field('Latitude (optional)'), '41.1579');
      await tester.enterText(field('Longitude (optional)'), '-8.6291');

      await addPhoto(tester);

      expect(find.byType(SnackBar), findsNothing);
    });
  });

  group('EntryFormScreen gallery', () {
    GalleryPhoto photo(String id, DateTime takenAt) =>
        GalleryPhoto(id: id, takenAt: takenAt);

    FakePhotoGallery lisbonGallery({
      GalleryAccess access = GalleryAccess.full,
      Set<String> missingOriginals = const {},
    }) => FakePhotoGallery(
      access: access,
      missingOriginals: missingOriginals,
      photos: [
        photo('tram', DateTime(2026, 5, 2, 9, 15)),
        photo('castle', DateTime(2026, 5, 3, 11)),
      ],
    );

    Future<void> addPhotos(WidgetTester tester) async {
      final button = find.widgetWithText(OutlinedButton, 'Add photos');
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
    }

    Future<void> choose(WidgetTester tester, List<String> ids) async {
      for (final id in ids) {
        await tester.tap(find.byKey(ValueKey('gallery-photo-$id')));
      }
      await tester.pumpAndSettle();
      final label = ids.length == 1
          ? 'Add 1 photo'
          : 'Add ${ids.length} photos';
      await tester.tap(find.widgetWithText(FilledButton, label));
      await tester.pumpAndSettle();
    }

    Future<({FakePhotoLibrary library, FakePhotoPicker picker})> openForm(
      WidgetTester tester,
      FakePhotoGallery gallery, {
      FakePhotoMetadataReader? photoMetadataReader,
    }) async {
      final library = FakePhotoLibrary();
      final picker = FakePhotoPicker(['/system/picked.jpg']);
      await openTrip(
        tester,
        photoGallery: gallery,
        photoLibrary: library,
        photoPicker: picker,
        photoMetadataReader: photoMetadataReader,
      );
      await tester.tap(find.widgetWithText(FloatingActionButton, 'New entry'));
      await tester.pumpAndSettle();
      return (library: library, picker: picker);
    }

    testWidgets('imports the original files of the chosen photos in order', (
      tester,
    ) async {
      final gallery = lisbonGallery();
      final (:library, :picker) = await openForm(tester, gallery);

      await addPhotos(tester);
      expect(find.text('Choose photos'), findsOneWidget);
      await choose(tester, ['castle', 'tram']);

      expect(gallery.accessRequests, 1);
      expect(picker.openCount, 0);
      expect(library.sources, ['/gallery/castle.jpg', '/gallery/tram.jpg']);
      expect(find.byTooltip('Remove photo'), findsNWidgets(2));
    });

    testWidgets('opens the gallery picker with limited access too', (
      tester,
    ) async {
      final gallery = lisbonGallery(access: GalleryAccess.limited);
      final (:library, :picker) = await openForm(tester, gallery);

      await addPhotos(tester);
      await choose(tester, ['tram']);

      expect(picker.openCount, 0);
      expect(library.sources, ['/gallery/tram.jpg']);
    });

    testWidgets('fills the form from the chosen photo', (tester) async {
      final (library: _, picker: _) = await openForm(
        tester,
        lisbonGallery(),
        photoMetadataReader: FakePhotoMetadataReader({
          'imported1.jpg': PhotoMetadata(
            takenAt: DateTime(2026, 5, 2, 9, 15),
            location: GeoPoint(latitude: 38.7128, longitude: -9.136),
          ),
        }),
      );

      await addPhotos(tester);
      await choose(tester, ['tram']);

      expect(find.text('Date and place taken from the photo'), findsOneWidget);
      expect(find.text('May 2, 2026'), findsOneWidget);
    });

    testWidgets('skips photos whose original file is unavailable', (
      tester,
    ) async {
      final gallery = lisbonGallery(missingOriginals: {'castle'});
      final (:library, picker: _) = await openForm(tester, gallery);

      await addPhotos(tester);
      await choose(tester, ['castle', 'tram']);

      expect(library.sources, ['/gallery/tram.jpg']);
      expect(find.byTooltip('Remove photo'), findsOneWidget);
    });

    testWidgets('changes nothing when the gallery picker is closed', (
      tester,
    ) async {
      final (:library, picker: _) = await openForm(tester, lisbonGallery());

      await addPhotos(tester);
      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(library.sources, isEmpty);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('falls back to the system photo picker without access', (
      tester,
    ) async {
      final gallery = lisbonGallery(access: GalleryAccess.denied);
      final (:library, :picker) = await openForm(tester, gallery);

      await addPhotos(tester);

      expect(find.text('Choose photos'), findsNothing);
      expect(picker.openCount, 1);
      expect(library.sources, ['/system/picked.jpg']);
    });
  });

  group('EntryFormScreen layout', () {
    double top(WidgetTester tester, Finder finder) =>
        tester.getTopLeft(finder).dy;

    testWidgets('starts with the photos', (tester) async {
      await openNewEntryForm(tester);

      final addPhotos = find.widgetWithText(OutlinedButton, 'Add photos');
      expect(
        top(tester, addPhotos),
        lessThan(top(tester, find.text('May 1, 2026'))),
      );
      expect(top(tester, addPhotos), lessThan(top(tester, field('Note'))));
    });

    testWidgets('shows date and time next to each other', (tester) async {
      await openNewEntryForm(tester);

      expect(
        top(tester, find.text('May 1, 2026')),
        top(tester, find.textContaining('10:30')),
      );
    });

    testWidgets('shows latitude and longitude next to each other', (
      tester,
    ) async {
      await openNewEntryForm(tester);

      await showCoordinates(tester);
      expect(
        top(tester, field('Latitude (optional)')),
        top(tester, field('Longitude (optional)')),
      );
    });

    testWidgets('writes the note in the display font', (tester) async {
      await openNewEntryForm(tester);

      final note = tester.widget<EditableText>(
        find.descendant(of: field('Note'), matching: find.byType(EditableText)),
      );
      expect(note.style.fontFamily, 'Fraunces');
    });
  });

  group('EntryFormScreen place suggestions', () {
    final lisbon = Place(
      name: 'Lisbon',
      country: 'Portugal',
      countryCode: 'PT',
      location: GeoPoint(latitude: 38.7251, longitude: -9.1498),
      population: 517802,
      alternateNames: const ['Lissabon'],
    );
    final lisburn = Place(
      name: 'Lisburn',
      country: 'United Kingdom',
      countryCode: 'GB',
      location: GeoPoint(latitude: 54.5162, longitude: -6.058),
      population: 45370,
    );
    FakePlaceDirectory places() => FakePlaceDirectory([lisburn, lisbon]);

    testWidgets('suggests places while typing', (tester) async {
      await openNewEntryForm(tester, placeDirectory: places());

      await tester.enterText(field('Place (optional)'), 'lis');
      await tester.pumpAndSettle();

      expect(find.text('Lisbon, Portugal'), findsOneWidget);
      expect(find.text('Lisburn, United Kingdom'), findsOneWidget);
    });

    testWidgets('fills name and coordinates from a picked place', (
      tester,
    ) async {
      final entries = await openNewEntryForm(tester, placeDirectory: places());

      await tester.enterText(field('Place (optional)'), 'Lissab');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lisbon, Portugal'));
      await tester.pumpAndSettle();

      expect(find.text('38.7251, -9.1498'), findsOneWidget);
      await save(tester);
      final entry = entries.entries.single;
      expect(entry.placeName, 'Lisbon');
      expect(entry.location, GeoPoint(latitude: 38.7251, longitude: -9.1498));
    });

    testWidgets('keeps a free text place without coordinates', (tester) async {
      final entries = await openNewEntryForm(tester, placeDirectory: places());

      await tester.enterText(field('Place (optional)'), 'Alfama');
      await tester.pumpAndSettle();
      await save(tester);

      expect(entries.entries.single.placeName, 'Alfama');
      expect(entries.entries.single.location, isNull);
    });

    testWidgets('hides the coordinates until expanded', (tester) async {
      await openNewEntryForm(tester);

      expect(field('Latitude (optional)'), findsNothing);
      expect(find.text('Coordinates'), findsOneWidget);

      await showCoordinates(tester);

      expect(field('Latitude (optional)'), findsOneWidget);
    });

    testWidgets('shows invalid coordinates even when collapsed', (
      tester,
    ) async {
      final entries = await openNewEntryForm(tester);
      await showCoordinates(tester);
      await tester.enterText(field('Latitude (optional)'), '95');
      await tester.enterText(field('Longitude (optional)'), '0');
      await tester.enterText(field('Note'), 'Tram 28');
      await tester.tap(find.text('Coordinates'));
      await tester.pumpAndSettle();

      await save(tester);

      expect(
        find.text('Latitude −90 to 90, longitude −180 to 180'),
        findsOneWidget,
      );
      expect(entries.entries, isEmpty);
    });
  });

  group('EntryFormScreen place name from photos', () {
    final lisbonCity = Place(
      name: 'Lisbon',
      country: 'Portugal',
      countryCode: 'PT',
      location: GeoPoint(latitude: 38.7251, longitude: -9.1498),
      population: 517802,
    );
    FakePhotoMetadataReader photoAt(double latitude, double longitude) =>
        FakePhotoMetadataReader({
          'imported1.jpg': PhotoMetadata(
            takenAt: DateTime(2026, 5, 2, 9, 15),
            location: GeoPoint(latitude: latitude, longitude: longitude),
          ),
        });

    Future<void> addPhoto(WidgetTester tester) async {
      final button = find.widgetWithText(OutlinedButton, 'Add photos');
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
    }

    String placeText(WidgetTester tester) =>
        tester
            .widget<TextFormField>(field('Place (optional)'))
            .controller
            ?.text ??
        '';

    testWidgets('fills the nearest city into an empty place field', (
      tester,
    ) async {
      await openNewEntryForm(
        tester,
        photoPicker: FakePhotoPicker(['/gallery/IMG_1.jpg']),
        photoMetadataReader: photoAt(38.7128, -9.136),
        placeDirectory: FakePlaceDirectory([lisbonCity]),
      );

      await addPhoto(tester);

      expect(placeText(tester), 'Lisbon');
      expect(find.text('Date and place taken from the photo'), findsOneWidget);
    });

    testWidgets('keeps a place typed by the user', (tester) async {
      await openNewEntryForm(
        tester,
        photoPicker: FakePhotoPicker(['/gallery/IMG_1.jpg']),
        photoMetadataReader: photoAt(38.7128, -9.136),
        placeDirectory: FakePlaceDirectory([lisbonCity]),
      );
      await tester.enterText(field('Place (optional)'), 'Belém');
      await tester.pumpAndSettle();

      await addPhoto(tester);

      expect(placeText(tester), 'Belém');
    });

    testWidgets('leaves the place empty without a city nearby', (tester) async {
      await openNewEntryForm(
        tester,
        photoPicker: FakePhotoPicker(['/gallery/IMG_1.jpg']),
        photoMetadataReader: photoAt(38.5, -12),
        placeDirectory: FakePlaceDirectory([lisbonCity]),
      );

      await addPhoto(tester);

      expect(placeText(tester), isEmpty);
    });
  });
}
