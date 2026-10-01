import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trailtale/domain/geo_point.dart';
import 'package:trailtale/ui/widgets/picker_map.dart';

import '../../support/placeholder_picker_map.dart';
import '../../support/pump_app.dart';

void main() {
  group('placeholderPickerMap', () {
    testWidgets('shows its center, follows the controller and pans', (
      tester,
    ) async {
      final centers = <GeoPoint>[];
      final controller = PickerMapController();
      addTearDown(controller.dispose);
      final build = placeholderPickerMap(
        panTo: GeoPoint(latitude: 42.4, longitude: 18.7),
      );
      await pumpApp(
        tester,
        Scaffold(
          body: build(
            controller: controller,
            initialCenter: GeoPoint(latitude: 1, longitude: 2),
            initialZoom: 3,
            onCenterChanged: centers.add,
          ),
        ),
      );

      expect(find.text('Map center: 1.0000, 2.0000'), findsOneWidget);

      controller.moveTo(GeoPoint(latitude: 38.7223, longitude: -9.1393));
      await tester.pump();
      expect(find.text('Map center: 38.7223, -9.1393'), findsOneWidget);

      await tester.tap(find.text('Pan map'));
      await tester.pump();
      expect(find.text('Map center: 42.4000, 18.7000'), findsOneWidget);
      expect(centers, [
        GeoPoint(latitude: 38.7223, longitude: -9.1393),
        GeoPoint(latitude: 42.4, longitude: 18.7),
      ]);
    });
  });
}
