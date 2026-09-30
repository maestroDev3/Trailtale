import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trailtale/domain/entry.dart';
import 'package:trailtale/domain/trip.dart';
import 'package:trailtale/ui/home_screen.dart';
import 'package:trailtale/ui/trip_detail_screen.dart';

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
      expect(find.text('No trips yet'), findsOneWidget);
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
    testWidgets('show local date and time, note and place name', (
      tester,
    ) async {
      await openLisbon(tester, entries: [breakfast]);

      expect(find.textContaining('May 1, 2026'), findsWidgets);
      expect(find.textContaining('8:30'), findsOneWidget);
      expect(find.text('Pastéis de nata'), findsOneWidget);
      expect(find.text('Belém'), findsOneWidget);
      expect(find.text('No entries yet'), findsNothing);
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

    testWidgets('can be added with the New entry button', (tester) async {
      await openLisbon(tester);

      expect(find.widgetWithText(FloatingActionButton, 'New entry'), findsOne);
    });
  });
}
