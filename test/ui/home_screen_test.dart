import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trailtale/domain/entry.dart';
import 'package:trailtale/domain/geo_point.dart';
import 'package:trailtale/domain/trip.dart';
import 'package:trailtale/ui/home_screen.dart';
import 'package:trailtale/ui/widgets/trailtale_logo.dart';
import 'package:trailtale/ui/widgets/trip_cover.dart';

import '../support/fake_entry_repository.dart';
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
  final alps = Trip(
    id: 'alps',
    title: 'Alps',
    startDate: DateTime(2026, 7, 1),
    endDate: DateTime(2026, 7, 1),
  );

  group('HomeScreen', () {
    testWidgets('shows the app title and the empty trips message', (
      tester,
    ) async {
      await pumpApp(tester, HomeScreen(services: testServices()));

      expect(find.text('Trailtale'), findsWidgets);
      expect(find.text('No trips yet'), findsOneWidget);
    });

    testWidgets('shows the logo, the wordmark and the heading', (tester) async {
      await pumpApp(tester, HomeScreen(services: testServices()));

      expect(find.byType(TrailtaleLogo), findsOneWidget);
      final wordmark = tester.widget<Text>(find.text('Trailtale'));
      expect(wordmark.style?.fontFamily ?? '', isNot(isEmpty));
      expect(find.text('Your trips'), findsOneWidget);
    });

    testWidgets('shows a trip with title, date range and number of days', (
      tester,
    ) async {
      await pumpApp(
        tester,
        HomeScreen(services: testServices(trips: FakeTripRepository([lisbon]))),
      );

      expect(find.text('Lisbon'), findsOneWidget);
      expect(find.text('May 1, 2026 – May 4, 2026'), findsOneWidget);
      expect(find.text('4 days'), findsOneWidget);
      expect(find.text('No trips yet'), findsNothing);
    });

    testWidgets('shows a one-day trip with a single date', (tester) async {
      await pumpApp(
        tester,
        HomeScreen(services: testServices(trips: FakeTripRepository([alps]))),
      );

      expect(find.text('Jul 1, 2026'), findsOneWidget);
      expect(find.text('1 day'), findsOneWidget);
    });

    testWidgets('lists trips newest first', (tester) async {
      await pumpApp(
        tester,
        HomeScreen(
          services: testServices(trips: FakeTripRepository([lisbon, alps])),
        ),
      );

      final alpsTop = tester.getTopLeft(find.text('Alps')).dy;
      final lisbonTop = tester.getTopLeft(find.text('Lisbon')).dy;
      expect(alpsTop, lessThan(lisbonTop));
    });

    testWidgets('updates when the repository changes', (tester) async {
      final repository = FakeTripRepository();
      await pumpApp(
        tester,
        HomeScreen(services: testServices(trips: repository)),
      );

      await repository.saveTrip(lisbon);
      await tester.pumpAndSettle();

      expect(find.text('Lisbon'), findsOneWidget);
      expect(find.text('No trips yet'), findsNothing);
    });

    testWidgets('offers a button to create a new trip', (tester) async {
      await pumpApp(tester, HomeScreen(services: testServices()));

      expect(find.widgetWithText(FloatingActionButton, 'New trip'), findsOne);
    });
  });

  group('pumpApp', () {
    testWidgets('uses the English locale and a phone-sized surface', (
      tester,
    ) async {
      await pumpApp(tester, HomeScreen(services: testServices()));

      final context = tester.element(find.byType(HomeScreen));
      expect(Localizations.localeOf(context), const Locale('en'));
      expect(MediaQuery.sizeOf(context), phoneSize);
    });
  });

  group('HomeScreen overview', () {
    // testNow is Tue, Sep 29, 2026: this trip is on its 4th of 7 days.
    final autumn = Trip(
      id: 'autumn',
      title: 'Autumn in Porto',
      startDate: DateTime(2026, 9, 26),
      endDate: DateTime(2026, 10, 2),
    );
    final lisbonTrip = Trip(
      id: 'lisbon',
      title: 'Lisbon',
      startDate: DateTime(2026, 5, 1),
      endDate: DateTime(2026, 5, 4),
    );
    Entry entry(
      String id,
      String tripId,
      int day, {
      String? place,
      GeoPoint? location,
      List<String> photos = const [],
    }) => Entry(
      id: id,
      tripId: tripId,
      time: DateTime.utc(2026, 9, day, 9),
      utcOffset: const Duration(hours: 1),
      note: id,
      placeName: place,
      location: location,
      photoPaths: photos,
    );
    final ribeira = entry(
      'ribeira',
      'autumn',
      26,
      place: 'Ribeira',
      location: GeoPoint(latitude: 41.1407, longitude: -8.6110),
      photos: ['photos/ribeira.jpg', 'photos/bridge.jpg'],
    );
    final foz = entry(
      'foz',
      'autumn',
      27,
      place: 'Foz',
      location: GeoPoint(latitude: 41.1496, longitude: -8.6760),
    );

    Future<void> pumpHome(
      WidgetTester tester, {
      required List<Trip> trips,
      List<Entry> entries = const [],
      FakeEntryRepository? entryRepository,
    }) {
      return pumpApp(
        tester,
        HomeScreen(
          services: testServices(
            trips: FakeTripRepository(trips),
            entries: entryRepository ?? FakeEntryRepository(entries),
          ),
        ),
      );
    }

    testWidgets('features the running trip with its day and key figures', (
      tester,
    ) async {
      await pumpHome(
        tester,
        trips: [autumn, lisbonTrip],
        entries: [ribeira, foz],
      );

      expect(find.text('On the road · Day 4 of 7'), findsOneWidget);
      expect(find.text('2 entries'), findsOneWidget);
      expect(find.text('2 places'), findsOneWidget);
      expect(find.text('5.5 km'), findsOneWidget);
      expect(find.text('More journeys'), findsOneWidget);
      final featuredTop = tester.getTopLeft(find.text('Autumn in Porto')).dy;
      final headingTop = tester.getTopLeft(find.text('More journeys')).dy;
      final otherTop = tester.getTopLeft(find.text('Lisbon')).dy;
      expect(featuredTop, lessThan(headingTop));
      expect(headingTop, lessThan(otherTop));
    });

    testWidgets('lists trips without a heading when none is running', (
      tester,
    ) async {
      await pumpHome(tester, trips: [lisbonTrip]);

      expect(find.textContaining('On the road'), findsNothing);
      expect(find.text('More journeys'), findsNothing);
      expect(find.text('Lisbon'), findsOneWidget);
    });

    testWidgets('shows the first photo as cover', (tester) async {
      await pumpHome(tester, trips: [autumn], entries: [foz, ribeira]);

      final cover = tester.widget<TripCover>(find.byType(TripCover));
      expect(cover.file?.path, endsWith('photos/ribeira.jpg'));
    });

    testWidgets('shows a placeholder for a trip without photos', (
      tester,
    ) async {
      await pumpHome(tester, trips: [lisbonTrip]);

      expect(tester.widget<TripCover>(find.byType(TripCover)).file, isNull);
      expect(find.byKey(const Key('cover-placeholder')), findsOneWidget);
    });

    testWidgets('shows days and distance on the list cards', (tester) async {
      await pumpHome(
        tester,
        trips: [
          Trip(
            id: 'autumn',
            title: 'Porto',
            startDate: DateTime(2025, 10, 24),
            endDate: DateTime(2025, 10, 27),
          ),
        ],
        entries: [ribeira, foz],
      );

      expect(find.text('4 days · 5.5 km'), findsOneWidget);
    });

    testWidgets('updates the cover when entries change', (tester) async {
      final entries = FakeEntryRepository();
      await pumpHome(tester, trips: [autumn], entryRepository: entries);

      await entries.saveEntry(ribeira);
      await tester.pumpAndSettle();

      final cover = tester.widget<TripCover>(find.byType(TripCover));
      expect(cover.file?.path, endsWith('photos/ribeira.jpg'));
    });

    testWidgets('opens the featured trip', (tester) async {
      await pumpHome(tester, trips: [autumn], entries: [ribeira]);

      await tester.tap(find.text('Autumn in Porto'));
      await tester.pumpAndSettle();

      expect(find.byTooltip('Edit trip'), findsOneWidget);
    });
  });
}
