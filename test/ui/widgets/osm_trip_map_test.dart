import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trailtale/domain/geo_point.dart';
import 'package:trailtale/domain/trip_map.dart';
import 'package:trailtale/ui/widgets/osm_trip_map.dart';

import '../../support/offline_tiles.dart';
import '../../support/pump_app.dart';

void main() {
  final points = [
    MapPoint(
      number: 1,
      entryId: 'lisbon',
      location: GeoPoint(latitude: 38.7223, longitude: -9.1393),
      label: 'Lisbon',
    ),
    MapPoint(
      number: 2,
      entryId: 'porto',
      location: GeoPoint(latitude: 41.1579, longitude: -8.6291),
      label: 'Porto',
    ),
  ];

  Future<List<String>> pumpMap(WidgetTester tester) async {
    final opened = <String>[];
    await pumpApp(
      tester,
      Scaffold(
        body: OsmTripMap(
          points: points,
          onOpenEntry: opened.add,
          tileProvider: OfflineTileProvider(),
        ),
      ),
    );
    return opened;
  }

  group('OsmTripMap', () {
    testWidgets('loads OpenStreetMap tiles with the app user agent', (
      tester,
    ) async {
      await pumpMap(tester);

      final layer = tester.widget<TileLayer>(find.byType(TileLayer));
      expect(
        layer.urlTemplate,
        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      );
      expect(
        layer.tileProvider.headers['User-Agent'],
        contains('de.maestrodev.trailtale'),
      );
    });

    testWidgets('always shows the OpenStreetMap attribution', (tester) async {
      await pumpMap(tester);

      expect(find.text('© OpenStreetMap contributors'), findsOneWidget);
    });

    testWidgets('shows a numbered marker per point', (tester) async {
      await pumpMap(tester);

      expect(find.byType(MarkerLayer), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.bySemanticsLabel('Porto'), findsOneWidget);
    });

    testWidgets('opens the entry of a tapped marker', (tester) async {
      final opened = await pumpMap(tester);

      await tester.tap(find.text('2'));
      await tester.pump();

      expect(opened, ['porto']);
    });

    testWidgets('fits the camera to all points', (tester) async {
      await pumpMap(tester);

      final map = tester.widget<FlutterMap>(find.byType(FlutterMap));
      expect(map.options.initialCameraFit, isNotNull);
    });
  });
}
