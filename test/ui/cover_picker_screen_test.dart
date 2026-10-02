import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trailtale/domain/entry.dart';
import 'package:trailtale/domain/trip.dart';
import 'package:trailtale/domain/trip_overview.dart';
import 'package:trailtale/ui/cover_picker_screen.dart';

import '../support/fake_trip_repository.dart';
import '../support/pump_app.dart';
import '../support/test_services.dart';

void main() {
  final montenegro = Trip(
    id: 'me',
    title: 'Montenegro',
    startDate: DateTime(2026, 9, 26),
    endDate: DateTime(2026, 9, 30),
  );
  Entry entry(String id, int day, List<String> photos) => Entry(
    id: id,
    tripId: 'me',
    time: DateTime.utc(2026, 9, day, 9),
    utcOffset: Duration.zero,
    photoPaths: photos,
  );
  final entries = [
    entry('late', 28, ['photos/beach.jpg', 'photos/old-town.jpg']),
    entry('early', 26, ['photos/airport.jpg']),
    entry('again', 29, ['photos/old-town.jpg']),
  ];

  Finder option(String path) => find.byKey(Key('cover-option-$path'));

  Future<(FakeTripRepository, Future<void>)> openPicker(
    WidgetTester tester, {
    Trip? trip,
  }) async {
    final current = trip ?? montenegro;
    final trips = FakeTripRepository([current]);
    final services = testServices(trips: trips);
    late Future<void> closed;
    await pumpApp(
      tester,
      Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => closed = Navigator.of(context).push<void>(
              MaterialPageRoute(
                builder: (_) => CoverPickerScreen(
                  services: services,
                  trip: current,
                  entries: entries,
                ),
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return (trips, closed);
  }

  group('tripPhotos', () {
    test('lists every photo once in time order', () {
      expect(tripPhotos(entries), [
        'photos/airport.jpg',
        'photos/beach.jpg',
        'photos/old-town.jpg',
      ]);
    });
  });

  group('CoverPickerScreen', () {
    testWidgets('shows each photo once in time order', (tester) async {
      await openPicker(tester);

      expect(find.text('Choose cover'), findsOneWidget);
      final airport = tester.getTopLeft(option('photos/airport.jpg'));
      final beach = tester.getTopLeft(option('photos/beach.jpg'));
      expect(option('photos/old-town.jpg'), findsOneWidget);
      expect(airport.dx, lessThan(beach.dx));
    });

    testWidgets('marks the current cover', (tester) async {
      await openPicker(
        tester,
        trip: montenegro.copyWith(coverPhotoPath: 'photos/beach.jpg'),
      );

      expect(
        find.descendant(
          of: option('photos/beach.jpg'),
          matching: find.byIcon(Icons.check),
        ),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('marks the automatic cover when none is chosen', (
      tester,
    ) async {
      await openPicker(tester);

      expect(
        find.descendant(
          of: option('photos/airport.jpg'),
          matching: find.byIcon(Icons.check),
        ),
        findsOneWidget,
      );
    });

    testWidgets('saves the tapped photo as cover and closes', (tester) async {
      final (trips, closed) = await openPicker(tester);

      await tester.tap(option('photos/old-town.jpg'));
      await tester.pumpAndSettle();

      expect(trips.trips.single.coverPhotoPath, 'photos/old-town.jpg');
      expect(find.byType(CoverPickerScreen), findsNothing);
      await closed;
    });

    testWidgets('goes back to the automatic cover', (tester) async {
      final (trips, _) = await openPicker(
        tester,
        trip: montenegro.copyWith(coverPhotoPath: 'photos/beach.jpg'),
      );

      await tester.tap(find.text('Automatic'));
      await tester.pumpAndSettle();

      expect(trips.trips.single.coverPhotoPath, isNull);
      expect(find.byType(CoverPickerScreen), findsNothing);
    });
  });
}
