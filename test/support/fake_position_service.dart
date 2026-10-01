import 'package:trailtale/domain/position_service.dart';

/// [PositionService] for tests.
class FakePositionService implements PositionService {
  FakePositionService([this.result = const PositionUnavailable()]);

  /// What [currentPosition] returns.
  PositionResult result;

  @override
  Future<PositionResult> currentPosition() async =>
      throw UnimplementedError();

  @override
  Future<void> openAppSettings() async => throw UnimplementedError();

  @override
  Future<void> openLocationSettings() async => throw UnimplementedError();
}
