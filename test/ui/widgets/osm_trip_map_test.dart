import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trailtale/domain/geo_point.dart';
import 'package:trailtale/domain/trip_map.dart';
import 'package:trailtale/ui/widgets/osm_trip_map.dart';

import '../../support/pump_app.dart';

/// A 1 × 1 transparent PNG, so tests never load tiles from the network.
final _transparentPng = Uint8List.fromList([
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, //
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, //
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00, //
  0x0D, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00, //
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, //
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
]);

class _OfflineTileProvider extends TileProvider {
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      MemoryImage(_transparentPng);
}

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
          tileProvider: _OfflineTileProvider(),
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
      expect(layer.urlTemplate, 'https://tile.openstreetmap.org/{z}/{x}/{y}.png');
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
