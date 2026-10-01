import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trailtale/domain/geo_point.dart';
import 'package:trailtale/domain/place.dart';
import 'package:trailtale/domain/position_service.dart';
import 'package:trailtale/ui/place_picker_screen.dart';

import '../support/fake_place_directory.dart';
import '../support/fake_position_service.dart';
import '../support/placeholder_picker_map.dart';
import '../support/pump_app.dart';
import '../support/test_services.dart';

final kotor = Place(
  name: 'Kotor',
  country: 'Montenegro',
  countryCode: 'ME',
  location: GeoPoint(latitude: 42.4207, longitude: 18.7682),
  population: 5345,
);
final lisbon = Place(
  name: 'Lisbon',
  country: 'Portugal',
  countryCode: 'PT',
  location: GeoPoint(latitude: 38.7223, longitude: -9.1393),
  population: 517802,
);
final beach = GeoPoint(latitude: 42.4231, longitude: 18.76);
final ocean = GeoPoint(latitude: 38.5, longitude: -12);
final hotel = PositionFound(
  GeoPoint(latitude: 42.4247, longitude: 18.7712),
  accuracyMeters: 8,
);

/// Opens the picker from a host page and returns its result once closed.
Future<Future<PickedPlace?>> pumpPicker(
  WidgetTester tester, {
  GeoPoint? initialCenter,
  GeoPoint? panTo,
  FakePositionService? positions,
}) async {
  final services = testServices(
    placeDirectory: FakePlaceDirectory([kotor, lisbon]),
    positionService: positions ?? FakePositionService(hotel),
    pickerMap: placeholderPickerMap(panTo: panTo),
  );
  late Future<PickedPlace?> result;
  await pumpApp(
    tester,
    Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () {
              result = Navigator.of(context).push<PickedPlace>(
                MaterialPageRoute(
                  builder: (_) => PlacePickerScreen(
                    services: services,
                    initialCenter: initialCenter,
                    initialZoom: 15,
                  ),
                ),
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return result;
}

void main() {
  group('PlacePickerScreen', () {
    testWidgets('shows a crosshair, the center and the nearest town', (
      tester,
    ) async {
      await pumpPicker(tester, initialCenter: lisbon.location);

      expect(find.text('Pick a place'), findsOneWidget);
      expect(find.byKey(const Key('picker-crosshair')), findsOneWidget);
      expect(find.text('38.7223, -9.1393'), findsOneWidget);
      expect(find.text('Near Lisbon, Portugal'), findsOneWidget);
    });

    testWidgets('updates while the map is panned', (tester) async {
      await pumpPicker(tester, initialCenter: lisbon.location, panTo: beach);

      await tester.tap(find.text('Pan map'));
      await tester.pumpAndSettle();

      expect(find.text('42.4231, 18.7600'), findsOneWidget);
      expect(find.text('Near Kotor, Montenegro'), findsOneWidget);
    });

    testWidgets('says when no town is nearby', (tester) async {
      await pumpPicker(tester, initialCenter: lisbon.location, panTo: ocean);

      await tester.tap(find.text('Pan map'));
      await tester.pumpAndSettle();

      expect(find.text('No town nearby'), findsOneWidget);
    });

    testWidgets('returns the center and the nearest town', (tester) async {
      final result = await pumpPicker(
        tester,
        initialCenter: lisbon.location,
        panTo: beach,
      );

      await tester.tap(find.text('Pan map'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Use this place'));
      await tester.pumpAndSettle();

      final picked = await result;
      expect(picked?.location, beach);
      expect(picked?.nearestPlace, kotor);
    });

    testWidgets('returns nothing when going back', (tester) async {
      final result = await pumpPicker(tester, initialCenter: lisbon.location);

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(await result, isNull);
    });

    testWidgets('moves the map to a town chosen in the search', (tester) async {
      await pumpPicker(tester, initialCenter: lisbon.location);

      await tester.enterText(
        find.widgetWithText(TextField, 'Search a town'),
        'kot',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Kotor'));
      await tester.pumpAndSettle();

      expect(find.text('Map center: 42.4207, 18.7682'), findsOneWidget);
      expect(find.text('Near Kotor, Montenegro'), findsOneWidget);
    });

    testWidgets('moves the map to my position', (tester) async {
      await pumpPicker(tester, initialCenter: lisbon.location);

      await tester.tap(find.byTooltip('My position'));
      await tester.pumpAndSettle();

      expect(find.text('42.4247, 18.7712'), findsOneWidget);
    });

    testWidgets('explains why my position is not available', (tester) async {
      await pumpPicker(
        tester,
        initialCenter: lisbon.location,
        positions: FakePositionService(const PositionServiceOff()),
      );

      await tester.tap(find.byTooltip('My position'));
      await tester.pumpAndSettle();

      expect(find.text('Location is turned off'), findsOneWidget);
      expect(find.text('38.7223, -9.1393'), findsOneWidget);
    });

    testWidgets('starts at my position without an initial center', (
      tester,
    ) async {
      final positions = FakePositionService(hotel);
      await pumpPicker(tester, positions: positions);

      expect(positions.requests, 1);
      expect(find.text('42.4247, 18.7712'), findsOneWidget);
    });

    testWidgets('stays on the world view quietly when no position is found', (
      tester,
    ) async {
      await pumpPicker(
        tester,
        positions: FakePositionService(
          const PositionDenied(permanently: false),
        ),
      );

      expect(find.text('20.0000, 0.0000'), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
    });
  });
}
