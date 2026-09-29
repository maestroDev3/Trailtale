import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trailtale/domain/trip.dart';
import 'package:trailtale/ui/home_screen.dart';
import 'package:trailtale/ui/trip_detail_screen.dart';

import '../support/fake_trip_repository.dart';
import '../support/pump_app.dart';

void main() {
  final lisbon = Trip(
    id: 'lisbon',
    title: 'Lisbon',
    startDate: DateTime(2026, 5, 1),
    endDate: DateTime(2026, 5, 4),
  );

  Future<FakeTripRepository> openLisbon(WidgetTester tester) async {
    final repository = FakeTripRepository([lisbon]);
    await pumpApp(
      tester,
      HomeScreen(tripRepository: repository, newId: () => 'id'),
    );
    await tester.tap(find.text('Lisbon'));
    await tester.pumpAndSettle();
    return repository;
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
      final repository = await openLisbon(tester);

      await tester.tap(find.byTooltip('Edit trip'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Porto');
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();

      expect(repository.trips, [lisbon.copyWith(title: 'Porto')]);
      expect(find.byType(TripDetailScreen), findsOneWidget);
      expect(find.text('Porto'), findsWidgets);
    });

    testWidgets('keeps the trip when deleting is cancelled', (tester) async {
      final repository = await openLisbon(tester);

      await tester.tap(find.byTooltip('Delete trip'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();

      expect(repository.trips, [lisbon]);
      expect(find.byType(TripDetailScreen), findsOneWidget);
    });

    testWidgets('deletes the trip after confirmation and returns to the list', (
      tester,
    ) async {
      final repository = await openLisbon(tester);

      await tester.tap(find.byTooltip('Delete trip'));
      await tester.pumpAndSettle();
      expect(find.text('Delete “Lisbon”?'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(repository.trips, isEmpty);
      expect(find.byType(TripDetailScreen), findsNothing);
      expect(find.text('No trips yet'), findsOneWidget);
    });
  });
}
