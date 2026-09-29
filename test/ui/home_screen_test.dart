import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trailtale/domain/trip.dart';
import 'package:trailtale/ui/home_screen.dart';

import '../support/fake_trip_repository.dart';
import '../support/pump_app.dart';

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
      await pumpApp(tester, HomeScreen(tripRepository: FakeTripRepository()));

      expect(find.text('Trailtale'), findsWidgets);
      expect(find.text('No trips yet'), findsOneWidget);
    });

    testWidgets('shows a trip with title, date range and number of days', (
      tester,
    ) async {
      await pumpApp(
        tester,
        HomeScreen(tripRepository: FakeTripRepository([lisbon])),
      );

      expect(find.text('Lisbon'), findsOneWidget);
      expect(find.text('May 1, 2026 – May 4, 2026'), findsOneWidget);
      expect(find.text('4 days'), findsOneWidget);
      expect(find.text('No trips yet'), findsNothing);
    });

    testWidgets('shows a one-day trip with a single date', (tester) async {
      await pumpApp(
        tester,
        HomeScreen(tripRepository: FakeTripRepository([alps])),
      );

      expect(find.text('Jul 1, 2026'), findsOneWidget);
      expect(find.text('1 day'), findsOneWidget);
    });

    testWidgets('lists trips newest first', (tester) async {
      await pumpApp(
        tester,
        HomeScreen(tripRepository: FakeTripRepository([lisbon, alps])),
      );

      final alpsTop = tester.getTopLeft(find.text('Alps')).dy;
      final lisbonTop = tester.getTopLeft(find.text('Lisbon')).dy;
      expect(alpsTop, lessThan(lisbonTop));
    });

    testWidgets('updates when the repository changes', (tester) async {
      final repository = FakeTripRepository();
      await pumpApp(tester, HomeScreen(tripRepository: repository));

      await repository.saveTrip(lisbon);
      await tester.pumpAndSettle();

      expect(find.text('Lisbon'), findsOneWidget);
      expect(find.text('No trips yet'), findsNothing);
    });

    testWidgets('offers a button to create a new trip', (tester) async {
      await pumpApp(tester, HomeScreen(tripRepository: FakeTripRepository()));

      expect(find.widgetWithText(FloatingActionButton, 'New trip'), findsOne);
    });
  });

  group('pumpApp', () {
    testWidgets('uses the English locale and a phone-sized surface', (
      tester,
    ) async {
      await pumpApp(tester, HomeScreen(tripRepository: FakeTripRepository()));

      final context = tester.element(find.byType(HomeScreen));
      expect(Localizations.localeOf(context), const Locale('en'));
      expect(MediaQuery.sizeOf(context), phoneSize);
    });
  });
}
