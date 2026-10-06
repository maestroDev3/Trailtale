import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trailtale/domain/geo_point.dart';
import 'package:trailtale/domain/photo_metadata.dart';
import 'package:trailtale/domain/place.dart';
import 'package:trailtale/domain/trip.dart';
import 'package:trailtale/ui/shared_photos_screen.dart';
import 'package:trailtale/ui/trip_detail_screen.dart';
import 'package:trailtale/ui/trip_form_screen.dart';

import '../support/fake_entry_repository.dart';
import '../support/fake_photo_library.dart';
import '../support/fake_photo_metadata_reader.dart';
import '../support/fake_place_directory.dart';
import '../support/fake_trip_repository.dart';
import '../support/pump_app.dart';
import '../support/test_services.dart';

void main() {
  final kotor = GeoPoint(latitude: 42.4247, longitude: 18.7712);
  // About 60 km from Kotor – no known place nearby.
  final dubrovnik = GeoPoint(latitude: 42.6507, longitude: 18.0944);
  final places = FakePlaceDirectory([
    Place(
      name: 'Kotor',
      country: 'Montenegro',
      countryCode: 'ME',
      location: kotor,
      population: 13510,
    ),
  ]);
  PhotoMetadata at(int hour, GeoPoint location) => PhotoMetadata(
    takenAt: DateTime(2026, 9, 27, hour),
    utcOffset: const Duration(hours: 2),
    location: location,
  );
  final metadata = FakePhotoMetadataReader({
    'a.jpg': at(9, kotor),
    'b.jpg': at(10, kotor),
    'c.jpg': at(14, dubrovnik),
  });
  const shared = ['/shared/a.jpg', '/shared/b.jpg', '/shared/c.jpg'];
  // testNow is September 29, 2026.
  final montenegro = Trip(
    id: 'me',
    title: 'Montenegro',
    startDate: DateTime(2026, 9, 26),
    endDate: DateTime(2026, 9, 30),
  );
  final iceland = Trip(
    id: 'is',
    title: 'Iceland',
    startDate: DateTime(2026, 2, 1),
    endDate: DateTime(2026, 2, 9),
  );

  Future<({FakeEntryRepository entries, FakePhotoLibrary library})> open(
    WidgetTester tester, {
    List<Trip>? trips,
  }) async {
    final entries = FakeEntryRepository();
    final library = FakePhotoLibrary();
    var id = 0;
    await pumpApp(
      tester,
      SharedPhotosScreen(
        services: testServices(
          trips: FakeTripRepository(trips ?? [montenegro]),
          entries: entries,
          photoLibrary: library,
          photoMetadataReader: metadata,
          placeDirectory: places,
          newId: () => 'e${id++}',
        ),
        paths: shared,
      ),
    );
    return (entries: entries, library: library);
  }

  group('SharedPhotosScreen', () {
    testWidgets('shows one card per group with place, date and time', (
      tester,
    ) async {
      await open(tester);

      expect(find.text('Kotor'), findsOneWidget);
      expect(find.text('Unknown place'), findsOneWidget);
      expect(find.textContaining('Sun, Sep 27, 2026'), findsNWidgets(2));
      expect(find.text('Save 2 entries'), findsOneWidget);
    });

    testWidgets('leaves out an unchecked group', (tester) async {
      await open(tester);

      await tester.tap(find.byKey(const Key('shared-group-1')));
      await tester.pumpAndSettle();

      expect(find.text('Save 1 entry'), findsOneWidget);
    });

    testWidgets('imports the photos and saves one entry per group', (
      tester,
    ) async {
      final (:entries, :library) = await open(tester);

      await tester.tap(find.text('Save 2 entries'));
      await tester.pumpAndSettle();

      expect(library.sources, shared);
      expect([for (final entry in entries.entries) entry.photoPaths], [
        ['photos/imported1.jpg', 'photos/imported2.jpg'],
        ['photos/imported3.jpg'],
      ]);
      expect([for (final entry in entries.entries) entry.placeName], [
        'Kotor',
        null,
      ]);
      expect({for (final entry in entries.entries) entry.tripId}, {'me'});
    });

    testWidgets('opens the trip after saving', (tester) async {
      await open(tester);

      await tester.tap(find.text('Save 2 entries'));
      await tester.pumpAndSettle();

      expect(find.byType(TripDetailScreen), findsOneWidget);
      expect(find.byType(SharedPhotosScreen), findsNothing);
    });

    testWidgets('lets the traveler choose the trip first', (tester) async {
      final (:entries, library: _) = await open(tester, trips: [iceland]);

      expect(find.text('Which trip is this for?'), findsOneWidget);
      await tester.tap(find.text('Iceland'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save 2 entries'));
      await tester.pumpAndSettle();

      expect({for (final entry in entries.entries) entry.tripId}, {'is'});
    });

    testWidgets('offers to create a trip when there is none', (tester) async {
      await open(tester, trips: const []);

      expect(
        find.text('There is no trip yet. Create one to save where you are.'),
        findsOneWidget,
      );
      await tester.tap(find.text('New trip'));
      await tester.pumpAndSettle();

      expect(find.byType(TripFormScreen), findsOneWidget);
    });
  });
}
