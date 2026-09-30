import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trailtale/domain/entry.dart';
import 'package:trailtale/domain/geo_point.dart';
import 'package:trailtale/domain/trip.dart';
import 'package:trailtale/ui/entry_form_screen.dart';
import 'package:trailtale/ui/home_screen.dart';
import 'package:trailtale/ui/trip_detail_screen.dart';

import '../support/fake_entry_repository.dart';
import '../support/fake_photo_library.dart';
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
  }) async {
    final entries = await openTrip(
      tester,
      photoLibrary: photoLibrary,
      photoPicker: photoPicker,
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

    testWidgets('does not save without a note or a place', (tester) async {
      final entries = await openNewEntryForm(tester);

      await save(tester);

      expect(find.text('Add a note or a place'), findsOneWidget);
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

    testWidgets('changes nothing when the picker is cancelled', (
      tester,
    ) async {
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
}
