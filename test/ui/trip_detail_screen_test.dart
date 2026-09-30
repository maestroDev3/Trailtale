import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trailtale/domain/entry.dart';
import 'package:trailtale/domain/geo_point.dart';
import 'package:trailtale/domain/trip.dart';
import 'package:trailtale/ui/entry_form_screen.dart';
import 'package:trailtale/ui/home_screen.dart';
import 'package:trailtale/ui/trip_detail_screen.dart';
import 'package:trailtale/ui/trip_map_screen.dart';
import 'package:trailtale/ui/widgets/photo_thumbnail.dart';
import 'package:trailtale/ui/widgets/trip_cover.dart';

import '../support/fake_entry_repository.dart';
import '../support/fake_photo_library.dart';
import '../support/fake_trip_repository.dart';
import '../support/placeholder_trip_map.dart';
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
    time: DateTime.utc(2026, 5, 1, 7, 30),
    utcOffset: const Duration(hours: 1),
    note: 'Pastéis de nata',
    placeName: 'Belém',
  );
  final dinner = Entry(
    id: 'dinner',
    tripId: 'lisbon',
    time: DateTime.utc(2026, 5, 2, 19),
    utcOffset: const Duration(hours: 1),
    note: 'Sardines',
  );

  Future<(FakeTripRepository, FakeEntryRepository)> openLisbon(
    WidgetTester tester, {
    List<Entry> entries = const [],
  }) async {
    final trips = FakeTripRepository([lisbon]);
    final entryRepository = FakeEntryRepository(entries);
    await pumpApp(
      tester,
      HomeScreen(
        services: testServices(trips: trips, entries: entryRepository),
      ),
    );
    await tester.tap(find.text('Lisbon'));
    await tester.pumpAndSettle();
    return (trips, entryRepository);
  }

  group('TripDetailScreen', () {
    testWidgets('opens from the trip card with title and dates', (
      tester,
    ) async {
      await openLisbon(tester);

      expect(find.byType(TripDetailScreen), findsOneWidget);
      expect(find.text('Lisbon'), findsWidgets);
      expect(find.text('May 1, 2026 – May 4, 2026'), findsOneWidget);
    });

    testWidgets('shows that there are no entries yet', (tester) async {
      await openLisbon(tester);

      expect(find.text('No entries yet'), findsOneWidget);
    });

    testWidgets('edits the trip and shows the new values', (tester) async {
      final (trips, _) = await openLisbon(tester);

      await tester.tap(find.byTooltip('Edit trip'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Porto');
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();

      expect(trips.trips, [lisbon.copyWith(title: 'Porto')]);
      expect(find.byType(TripDetailScreen), findsOneWidget);
      expect(find.text('Porto'), findsWidgets);
    });

    testWidgets('keeps the trip when deleting is cancelled', (tester) async {
      final (trips, _) = await openLisbon(tester);

      await tester.tap(find.byTooltip('Delete trip'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();

      expect(trips.trips, [lisbon]);
      expect(find.byType(TripDetailScreen), findsOneWidget);
    });

    testWidgets('deletes the trip after confirmation and returns to the list', (
      tester,
    ) async {
      final (trips, _) = await openLisbon(tester);

      await tester.tap(find.byTooltip('Delete trip'));
      await tester.pumpAndSettle();
      expect(find.text('Delete “Lisbon”?'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(trips.trips, isEmpty);
      expect(find.byType(TripDetailScreen), findsNothing);
      expect(find.text('Every trip tells a tale'), findsOneWidget);
    });

    testWidgets('deleting the trip also deletes its entries', (tester) async {
      final (_, entries) = await openLisbon(
        tester,
        entries: [breakfast, dinner],
      );

      await tester.tap(find.byTooltip('Delete trip'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(entries.entries, isEmpty);
    });
  });

  group('TripDetailScreen entries', () {
    testWidgets('show local time, note and place name', (tester) async {
      await openLisbon(tester, entries: [breakfast]);

      expect(find.textContaining('8:30'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Text &&
              (widget.data ?? '').contains('8:30') &&
              (widget.data ?? '').contains('May'),
        ),
        findsNothing,
      );
      expect(find.text('Pastéis de nata'), findsOneWidget);
      expect(find.text('Belém'), findsOneWidget);
      expect(find.text('No entries yet'), findsNothing);
    });

    testWidgets('are grouped under a header per trip day', (tester) async {
      await openLisbon(tester, entries: [dinner, breakfast]);

      expect(find.text('Day 1'), findsOneWidget);
      expect(find.text('Friday, May 1'), findsOneWidget);
      expect(find.text('Day 2'), findsOneWidget);
      expect(find.text('Saturday, May 2'), findsOneWidget);
      final tops = [
        find.text('Day 1'),
        find.text('Pastéis de nata'),
        find.text('Day 2'),
        find.text('Sardines'),
      ].map((finder) => tester.getTopLeft(finder).dy).toList();
      expect(tops, orderedEquals([...tops]..sort()));
    });

    testWidgets('outside the trip dates show only the date', (tester) async {
      await openLisbon(
        tester,
        entries: [
          Entry(
            id: 'arrival',
            tripId: 'lisbon',
            time: DateTime.utc(2026, 4, 26, 16),
            utcOffset: const Duration(hours: 1),
            note: 'Flight',
          ),
        ],
      );

      expect(find.text('Sun, Apr 26, 2026'), findsOneWidget);
      expect(find.textContaining('Day'), findsNothing);
    });

    testWidgets('appear in chronological order', (tester) async {
      await openLisbon(tester, entries: [dinner, breakfast]);

      final breakfastTop = tester.getTopLeft(find.text('Pastéis de nata')).dy;
      final dinnerTop = tester.getTopLeft(find.text('Sardines')).dy;
      expect(breakfastTop, lessThan(dinnerTop));
    });

    testWidgets('update when entries change', (tester) async {
      final (_, entries) = await openLisbon(tester);

      await entries.saveEntry(dinner);
      await tester.pumpAndSettle();

      expect(find.text('Sardines'), findsOneWidget);
      expect(find.text('No entries yet'), findsNothing);
    });

    testWidgets('show one thumbnail per photo', (tester) async {
      await openLisbon(
        tester,
        entries: [
          breakfast.copyWith(photoPaths: ['photos/1.jpg', 'photos/2.jpg']),
        ],
      );

      expect(find.byType(PhotoThumbnail), findsNWidgets(2));
      expect(find.textContaining('+'), findsNothing);
    });

    testWidgets('show at most four thumbnails and a badge for the rest', (
      tester,
    ) async {
      await openLisbon(
        tester,
        entries: [
          breakfast.copyWith(
            photoPaths: [for (var i = 1; i <= 6; i++) 'photos/$i.jpg'],
          ),
        ],
      );

      expect(find.byType(PhotoThumbnail), findsNWidgets(4));
      expect(find.text('+2'), findsOneWidget);
    });

    testWidgets('show a placeholder for a missing photo file', (tester) async {
      await openLisbon(
        tester,
        entries: [
          breakfast.copyWith(photoPaths: ['photos/missing.jpg']),
        ],
      );

      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.broken_image_outlined), findsOneWidget);
    });

    testWidgets('deleting the trip deletes the photos of its entries', (
      tester,
    ) async {
      final library = FakePhotoLibrary();
      final trips = FakeTripRepository([lisbon]);
      await pumpApp(
        tester,
        HomeScreen(
          services: testServices(
            trips: trips,
            entries: FakeEntryRepository([
              breakfast.copyWith(photoPaths: ['photos/1.jpg']),
            ]),
            photoLibrary: library,
          ),
        ),
      );
      await tester.tap(find.text('Lisbon'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Delete trip'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(library.deleted, ['photos/1.jpg']);
    });

    testWidgets('can be added with the New entry button', (tester) async {
      await openLisbon(tester);

      expect(find.widgetWithText(FloatingActionButton, 'New entry'), findsOne);
    });
  });

  group('TripDetailScreen summary', () {
    final inLisbon = Entry(
      id: 'lisbon-entry',
      tripId: 'lisbon',
      time: DateTime.utc(2026, 5, 1, 9),
      utcOffset: const Duration(hours: 1),
      placeName: 'Lisbon',
      location: GeoPoint(latitude: 38.7223, longitude: -9.1393),
      photoPaths: ['photos/1.jpg', 'photos/2.jpg'],
    );
    final inPorto = Entry(
      id: 'porto-entry',
      tripId: 'lisbon',
      time: DateTime.utc(2026, 5, 2, 9),
      utcOffset: const Duration(hours: 1),
      placeName: 'Porto',
      location: GeoPoint(latitude: 41.1579, longitude: -8.6291),
    );

    Finder stat(String key, String text) =>
        find.descendant(of: find.byKey(Key(key)), matching: find.text(text));

    testWidgets('shows days, entries, places, photos and kilometers', (
      tester,
    ) async {
      await openLisbon(tester, entries: [inLisbon, inPorto]);

      expect(stat('summary-days', '4'), findsOneWidget);
      expect(stat('summary-days', 'days'), findsOneWidget);
      expect(stat('summary-entries', '2'), findsOneWidget);
      expect(stat('summary-entries', 'entries'), findsOneWidget);
      expect(stat('summary-places', '2'), findsOneWidget);
      expect(stat('summary-places', 'places'), findsOneWidget);
      expect(stat('summary-photos', '2'), findsOneWidget);
      expect(stat('summary-photos', 'photos'), findsOneWidget);
      expect(stat('summary-distance', '274'), findsOneWidget);
      expect(stat('summary-distance', 'km'), findsOneWidget);
    });

    testWidgets('uses singular labels', (tester) async {
      await openLisbon(tester, entries: [inPorto]);

      expect(stat('summary-entries', 'entry'), findsOneWidget);
      expect(stat('summary-places', 'place'), findsOneWidget);
      expect(stat('summary-photos', 'photos'), findsOneWidget);
    });

    testWidgets('updates when entries change', (tester) async {
      final (_, entries) = await openLisbon(tester, entries: [inLisbon]);
      expect(stat('summary-distance', '0'), findsOneWidget);

      await entries.saveEntry(inPorto);
      await tester.pumpAndSettle();

      expect(stat('summary-entries', '2'), findsOneWidget);
      expect(stat('summary-distance', '274'), findsOneWidget);
    });

    testWidgets('does not overflow with large fonts', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await openLisbon(tester, entries: [inLisbon, inPorto]);

      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('summary-distance')), findsOneWidget);
    });
  });

  group('TripDetailScreen page', () {
    Entry at(
      String id,
      int hour,
      String place, {
      List<String> photos = const [],
    }) => Entry(
      id: id,
      tripId: 'lisbon',
      time: DateTime.utc(2026, 5, 1, hour),
      utcOffset: Duration.zero,
      placeName: place,
      photoPaths: photos,
    );

    testWidgets('shows the first photo as cover', (tester) async {
      await openLisbon(
        tester,
        entries: [
          at('a', 8, 'Belém', photos: ['photos/cover.jpg']),
        ],
      );

      final cover = tester.widget<TripCover>(find.byType(TripCover));
      expect(cover.file?.path, endsWith('photos/cover.jpg'));
    });

    testWidgets('shows the cover placeholder without photos', (tester) async {
      await openLisbon(tester);

      expect(find.byKey(const Key('cover-placeholder')), findsOneWidget);
    });

    testWidgets('shows the route of places in visiting order', (tester) async {
      await openLisbon(
        tester,
        entries: [
          at('b', 12, 'Sintra'),
          at('a', 8, 'Lisbon'),
          at('c', 18, 'Porto'),
        ],
      );

      final strip = find.byKey(const Key('route-strip'));
      expect(strip, findsOneWidget);
      final lefts = ['Lisbon', 'Sintra', 'Porto']
          .map(
            (name) => tester
                .getTopLeft(
                  find.descendant(of: strip, matching: find.text(name)),
                )
                .dx,
          )
          .toList();
      expect(lefts, orderedEquals([...lefts]..sort()));
    });

    testWidgets('shortens a long route', (tester) async {
      await openLisbon(
        tester,
        entries: [
          for (final (index, place) in [
            'Lisbon',
            'Sintra',
            'Cascais',
            'Évora',
            'Coimbra',
            'Porto',
          ].indexed)
            at('e$index', 6 + index, place),
        ],
      );

      final strip = find.byKey(const Key('route-strip'));
      expect(find.descendant(of: strip, matching: find.text('+2')), findsOne);
      expect(
        find.descendant(of: strip, matching: find.text('Coimbra')),
        findsNothing,
      );
    });

    testWidgets('shows no route with fewer than two places', (tester) async {
      await openLisbon(tester, entries: [at('a', 8, 'Lisbon')]);

      expect(find.byKey(const Key('route-strip')), findsNothing);
    });

    testWidgets('goes back with the round back button', (tester) async {
      await openLisbon(tester);

      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();

      expect(find.byType(TripDetailScreen), findsNothing);
      expect(find.text('Your trips'), findsOneWidget);
    });
  });

  group('TripDetailScreen map', () {
    final atBelem = Entry(
      id: 'belem',
      tripId: 'lisbon',
      time: DateTime.utc(2026, 5, 1, 9),
      utcOffset: const Duration(hours: 1),
      placeName: 'Belém',
      location: GeoPoint(latitude: 38.6916, longitude: -9.2160),
    );
    final atAlfama = Entry(
      id: 'alfama',
      tripId: 'lisbon',
      time: DateTime.utc(2026, 5, 1, 17),
      utcOffset: const Duration(hours: 1),
      placeName: 'Alfama',
      location: GeoPoint(latitude: 38.7117, longitude: -9.1300),
    );

    Future<void> tapMarker(WidgetTester tester, String text) async {
      await tester.ensureVisible(find.text(text));
      await tester.tap(find.text(text));
      await tester.pumpAndSettle();
    }

    testWidgets('shows the located entries on a map', (tester) async {
      await openLisbon(tester, entries: [atAlfama, atBelem]);

      expect(find.byType(PlaceholderTripMap), findsOneWidget);
      expect(find.text('Marker 1: Belém'), findsOneWidget);
      expect(find.text('Marker 2: Alfama'), findsOneWidget);
    });

    testWidgets('shows no map without located entries', (tester) async {
      await openLisbon(tester, entries: [breakfast]);

      expect(find.byType(PlaceholderTripMap), findsNothing);
      expect(find.byTooltip('Open map'), findsNothing);
    });

    testWidgets('opens the entry of a tapped marker', (tester) async {
      await openLisbon(tester, entries: [atBelem]);

      await tapMarker(tester, 'Marker 1: Belém');

      expect(find.byType(EntryFormScreen), findsOneWidget);
      expect(find.text('Edit entry'), findsOneWidget);
    });

    testWidgets('opens the full-screen map', (tester) async {
      await openLisbon(tester, entries: [atBelem, atAlfama]);

      await tester.ensureVisible(find.byTooltip('Open map'));
      await tester.tap(find.byTooltip('Open map'));
      await tester.pumpAndSettle();

      expect(find.byType(TripMapScreen), findsOneWidget);
      expect(find.text('Marker 2: Alfama'), findsOneWidget);

      await tapMarker(tester, 'Marker 2: Alfama');
      expect(find.byType(EntryFormScreen), findsOneWidget);
    });
  });
}
