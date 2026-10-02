import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trailtale/domain/trip.dart';
import 'package:trailtale/ui/home_screen.dart';
import 'package:trailtale/ui/trip_form_screen.dart';

import '../support/fake_trip_repository.dart';
import '../support/pump_app.dart';
import '../support/test_services.dart';

void main() {
  final now = testNow;
  String newId() => 'id-1';

  Future<FakeTripRepository> openNewTripForm(WidgetTester tester) async {
    final repository = FakeTripRepository();
    await pumpApp(
      tester,
      HomeScreen(
        services: testServices(trips: repository, newId: newId),
      ),
    );
    await tester.tap(find.widgetWithText(FloatingActionButton, 'New trip'));
    await tester.pumpAndSettle();
    return repository;
  }

  group('TripFormScreen for a new trip', () {
    testWidgets('opens with an empty title and today as dates', (tester) async {
      await openNewTripForm(tester);

      expect(find.byType(TripFormScreen), findsOneWidget);
      final title = tester.widget<TextField>(find.byType(TextField));
      expect(title.controller?.text, isEmpty);
      expect(find.text('Sep 29, 2026'), findsOneWidget);
    });

    testWidgets('does not save without a title', (tester) async {
      final repository = await openNewTripForm(tester);

      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a title'), findsOneWidget);
      expect(repository.trips, isEmpty);
      expect(find.byType(TripFormScreen), findsOneWidget);
    });

    testWidgets('saves a new trip and returns to the list', (tester) async {
      final repository = await openNewTripForm(tester);

      await tester.enterText(find.byType(TextField), 'Lisbon');
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();

      expect(repository.trips, [
        Trip(id: 'id-1', title: 'Lisbon', startDate: now, endDate: now),
      ]);
      expect(find.byType(TripFormScreen), findsNothing);
      expect(find.text('Lisbon'), findsOneWidget);
    });

    testWidgets('opens a date range picker when tapping the dates', (
      tester,
    ) async {
      await openNewTripForm(tester);

      await tester.tap(find.text('Sep 29, 2026'));
      await tester.pumpAndSettle();

      expect(find.byType(DateRangePickerDialog), findsOneWidget);
    });
  });

  group('TripFormScreen for an existing trip', () {
    final lisbon = Trip(
      id: 'lisbon',
      title: 'Lisbon',
      startDate: DateTime(2026, 5, 1),
      endDate: DateTime(2026, 5, 4),
    );

    testWidgets('is prefilled and replaces the trip when saving', (
      tester,
    ) async {
      final repository = FakeTripRepository([lisbon]);
      await pumpApp(
        tester,
        TripFormScreen(
          services: testServices(trips: repository),
          trip: lisbon,
        ),
      );

      expect(find.text('Edit trip'), findsOneWidget);
      expect(find.text('Lisbon'), findsOneWidget);
      expect(find.text('May 1, 2026 – May 4, 2026'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Porto');
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();

      expect(repository.trips, [lisbon.copyWith(title: 'Porto')]);
    });

    testWidgets('keeps the chosen cover when saving', (tester) async {
      final withCover = lisbon.copyWith(coverPhotoPath: 'photos/tram.jpg');
      final repository = FakeTripRepository([withCover]);
      await pumpApp(
        tester,
        TripFormScreen(
          services: testServices(trips: repository),
          trip: withCover,
        ),
      );

      await tester.enterText(find.byType(TextField), 'Porto');
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();

      expect(repository.trips.single.coverPhotoPath, 'photos/tram.jpg');
    });
  });
}
