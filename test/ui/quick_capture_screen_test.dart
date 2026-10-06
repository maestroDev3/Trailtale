import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trailtale/domain/geo_point.dart';
import 'package:trailtale/domain/place.dart';
import 'package:trailtale/domain/position_service.dart';
import 'package:trailtale/domain/trip.dart';
import 'package:trailtale/ui/entry_form_screen.dart';
import 'package:trailtale/ui/quick_capture_screen.dart';
import 'package:trailtale/ui/trip_form_screen.dart';

import '../support/fake_entry_repository.dart';
import '../support/fake_photo_picker.dart';
import '../support/fake_place_directory.dart';
import '../support/fake_position_service.dart';
import '../support/fake_trip_repository.dart';
import '../support/pump_app.dart';
import '../support/test_services.dart';

void main() {
  final kotor = GeoPoint(latitude: 42.4247, longitude: 18.7712);
  final places = FakePlaceDirectory([
    Place(
      name: 'Kotor',
      country: 'Montenegro',
      countryCode: 'ME',
      location: kotor,
      population: 13510,
    ),
  ]);
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

  Future<({FakeEntryRepository entries, FakePhotoPicker picker})> open(
    WidgetTester tester, {
    List<Trip>? trips,
    FakePositionService? positions,
  }) async {
    final entries = FakeEntryRepository();
    final picker = FakePhotoPicker();
    final services = testServices(
      trips: FakeTripRepository(trips ?? [montenegro]),
      entries: entries,
      placeDirectory: places,
      photoPicker: picker,
      positionService:
          positions ??
          FakePositionService(PositionFound(kotor, accuracyMeters: 12)),
    );
    await pumpApp(
      tester,
      Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => QuickCaptureScreen(services: services),
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return (entries: entries, picker: picker);
  }

  group('QuickCaptureScreen', () {
    testWidgets('saves an entry into the running trip without a tap', (
      tester,
    ) async {
      final (:entries, picker: _) = await open(tester);

      final entry = entries.entries.single;
      expect(entry.tripId, 'me');
      expect(entry.placeName, 'Kotor');
      expect(entry.location, kotor);
      expect(entry.localDateTime, DateTime.utc(2026, 9, 29, 10, 30));
    });

    testWidgets('confirms place and time; Done closes the screen', (
      tester,
    ) async {
      await open(tester);

      expect(find.text('Kotor · 10:30 AM'), findsOneWidget);

      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      expect(find.byType(QuickCaptureScreen), findsNothing);
      expect(find.text('open'), findsOneWidget);
    });

    testWidgets('opens the saved entry to add a note', (tester) async {
      final (:entries, picker: _) = await open(tester);

      await tester.tap(find.text('Add note'));
      await tester.pumpAndSettle();

      final form = tester.widget<EntryFormScreen>(find.byType(EntryFormScreen));
      expect(form.entry?.id, entries.entries.single.id);
      expect(find.text('Edit entry'), findsOneWidget);
    });

    testWidgets('opens the saved entry with the photo picker', (tester) async {
      final (:entries, :picker) = await open(tester);

      await tester.tap(find.text('Add photo'));
      await tester.pumpAndSettle();

      final form = tester.widget<EntryFormScreen>(find.byType(EntryFormScreen));
      expect(form.entry?.id, entries.entries.single.id);
      expect(picker.openCount, 1);
    });

    testWidgets('lets the traveler choose the trip when none is running', (
      tester,
    ) async {
      final (:entries, picker: _) = await open(tester, trips: [iceland]);

      expect(entries.entries, isEmpty);
      expect(find.text('Which trip is this for?'), findsOneWidget);

      await tester.tap(find.text('Iceland'));
      await tester.pumpAndSettle();

      expect(entries.entries.single.tripId, 'is');
      expect(find.text('Kotor · 10:30 AM'), findsOneWidget);
    });

    testWidgets('offers to create a trip when there is none', (tester) async {
      final (:entries, picker: _) = await open(tester, trips: const []);

      expect(
        find.text('There is no trip yet. Create one to save where you are.'),
        findsOneWidget,
      );

      await tester.tap(find.text('New trip'));
      await tester.pumpAndSettle();

      expect(find.byType(TripFormScreen), findsOneWidget);
      expect(entries.entries, isEmpty);
    });

    testWidgets('says why without a position and saves nothing', (
      tester,
    ) async {
      final positions = FakePositionService(
        const PositionDenied(permanently: false),
      );
      final (:entries, picker: _) = await open(tester, positions: positions);

      expect(entries.entries, isEmpty);
      expect(find.text('Location access was not allowed'), findsOneWidget);

      positions.result = PositionFound(kotor, accuracyMeters: 12);
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      expect(entries.entries.single.placeName, 'Kotor');
    });

    testWidgets('writes the entry by hand without a position', (tester) async {
      await open(tester, positions: FakePositionService());

      await tester.tap(find.text('Write entry'));
      await tester.pumpAndSettle();

      final form = tester.widget<EntryFormScreen>(find.byType(EntryFormScreen));
      expect(form.entry, isNull);
      expect(form.trip.id, 'me');
    });
  });
}
