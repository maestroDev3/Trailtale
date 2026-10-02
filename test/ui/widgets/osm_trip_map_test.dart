import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
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

  Future<List<String>> pumpMap(
    WidgetTester tester, {
    List<MapPoint>? mapPoints,
  }) async {
    final opened = <String>[];
    await pumpApp(
      tester,
      Scaffold(
        body: OsmTripMap(
          points: mapPoints ?? points,
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

    testWidgets('draws the route below the markers in the route color', (
      tester,
    ) async {
      await pumpMap(tester);

      final layer = tester.widget<PolylineLayer>(find.byType(PolylineLayer));
      final leg = layer.polylines.single;
      final context = tester.element(find.byType(FlutterMap));
      expect(leg.color, Theme.of(context).colorScheme.secondary);
      expect(leg.strokeWidth, 4);
      expect(leg.pattern, const StrokePattern.solid());
      expect(leg.points.first.latitude, 38.7223);
      expect(leg.points.last.latitude, 41.1579);

      final children = tester
          .widget<FlutterMap>(find.byType(FlutterMap))
          .children;
      expect(
        children.indexWhere((child) => child is PolylineLayer),
        lessThan(children.indexWhere((child) => child is MarkerLayer)),
      );
    });

    testWidgets('draws long legs dashed', (tester) async {
      await pumpMap(
        tester,
        mapPoints: [
          ...points,
          MapPoint(
            number: 3,
            entryId: 'kotor',
            location: GeoPoint(latitude: 42.4247, longitude: 18.7712),
            label: 'Kotor',
          ),
        ],
      );

      final polylines = tester
          .widget<PolylineLayer>(find.byType(PolylineLayer))
          .polylines;
      expect(polylines, hasLength(2));
      expect(polylines[0].pattern, const StrokePattern.solid());
      expect(polylines[1].pattern, isNot(const StrokePattern.solid()));
    });

    testWidgets('draws no route for a single point', (tester) async {
      await pumpMap(tester, mapPoints: [points.first]);

      expect(find.byType(PolylineLayer), findsNothing);
    });

    testWidgets('fits the camera to points that arrive after the first frame', (
      tester,
    ) async {
      final mapPoints = ValueNotifier<List<MapPoint>>(const []);
      addTearDown(mapPoints.dispose);
      await pumpApp(
        tester,
        Scaffold(
          body: ValueListenableBuilder(
            valueListenable: mapPoints,
            builder: (context, value, _) => OsmTripMap(
              points: value,
              onOpenEntry: (_) {},
              tileProvider: OfflineTileProvider(),
            ),
          ),
        ),
      );

      mapPoints.value = points;
      await tester.pumpAndSettle();

      final camera = MapCamera.of(tester.element(find.byType(MarkerLayer)));
      expect(camera.zoom, greaterThan(5));
      for (final point in points) {
        expect(
          camera.visibleBounds.contains(
            LatLng(point.location.latitude, point.location.longitude),
          ),
          isTrue,
        );
      }
    });

    testWidgets('fits the camera to points known from the start', (
      tester,
    ) async {
      await pumpMap(tester);

      final camera = MapCamera.of(tester.element(find.byType(MarkerLayer)));
      expect(camera.zoom, greaterThan(5));
      expect(
        camera.visibleBounds.contains(const LatLng(41.1579, -8.6291)),
        isTrue,
      );
    });
  });
}
