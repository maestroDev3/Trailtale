import 'package:flutter_test/flutter_test.dart';
import 'package:trailtale/domain/geo_point.dart';
import 'package:trailtale/domain/position_service.dart';

import '../support/fake_position_service.dart';

void main() {
  group('FakePositionService', () {
    test('returns the configured result and counts requests', () async {
      final found = PositionFound(
        GeoPoint(latitude: 42.4247, longitude: 18.7712),
        accuracyMeters: 12,
      );
      final service = FakePositionService(found);

      expect(await service.currentPosition(), same(found));
      service.result = const PositionServiceOff();
      expect(await service.currentPosition(), isA<PositionServiceOff>());
      expect(service.requests, 2);
    });

    test('records which settings were opened', () async {
      final service = FakePositionService();

      await service.openAppSettings();
      await service.openLocationSettings();
      await service.openAppSettings();

      expect(service.openedSettings, ['app', 'location', 'app']);
    });
  });
}
