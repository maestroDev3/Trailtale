import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trailtale/domain/geo_point.dart';
import 'package:trailtale/ui/widgets/osm_picker_map.dart';
import 'package:trailtale/ui/widgets/picker_map.dart';

import '../../support/offline_tiles.dart';
import '../../support/pump_app.dart';

void main() {
  final kotor = GeoPoint(latitude: 42.4247, longitude: 18.7712);

  Future<({List<GeoPoint> centers, PickerMapController controller})> pumpMap(
    WidgetTester tester,
  ) async {
    final centers = <GeoPoint>[];
    final controller = PickerMapController();
    addTearDown(controller.dispose);
    await pumpApp(
      tester,
      Scaffold(
        body: OsmPickerMap(
          controller: controller,
          initialCenter: kotor,
          initialZoom: 15,
          onCenterChanged: centers.add,
          tileProvider: OfflineTileProvider(),
        ),
      ),
    );
    return (centers: centers, controller: controller);
  }

  group('OsmPickerMap', () {
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

    testWidgets('follows the controller and reports the new center', (
      tester,
    ) async {
      final (:centers, :controller) = await pumpMap(tester);

      controller.moveTo(
        GeoPoint(latitude: 38.7223, longitude: -9.1393),
        zoom: 13,
      );
      await tester.pumpAndSettle();

      expect(centers.last.latitude, closeTo(38.7223, 0.0001));
      expect(centers.last.longitude, closeTo(-9.1393, 0.0001));
    });

    testWidgets('reports a new center when the map is dragged', (tester) async {
      final (:centers, controller: _) = await pumpMap(tester);

      await tester.timedDrag(
        find.byType(FlutterMap),
        const Offset(-200, 0),
        const Duration(milliseconds: 300),
      );
      await tester.pumpAndSettle();

      expect(centers, isNotEmpty);
      expect(centers.last.longitude, greaterThan(kotor.longitude));
    });

    testWidgets('cannot be rotated', (tester) async {
      await pumpMap(tester);

      final options = tester
          .widget<FlutterMap>(find.byType(FlutterMap))
          .options;
      expect(options.interactionOptions.flags & InteractiveFlag.rotate, 0);
    });
  });

  group('mapCenterToGeoPoint', () {
    test('wraps longitudes and clamps latitudes', () {
      final point = mapCenterToGeoPoint(latitude: 95, longitude: 190);

      expect(point.latitude, 90);
      expect(point.longitude, closeTo(-170, 0.000001));
      expect(
        mapCenterToGeoPoint(latitude: -91, longitude: -540).longitude,
        closeTo(180, 0.000001),
      );
    });

    test('keeps ordinary positions', () {
      final point = mapCenterToGeoPoint(latitude: 42.4247, longitude: 18.7712);

      expect(point, GeoPoint(latitude: 42.4247, longitude: 18.7712));
    });
  });
}
