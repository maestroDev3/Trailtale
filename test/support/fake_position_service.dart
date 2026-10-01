import 'dart:async';

import 'package:trailtale/domain/position_service.dart';

/// [PositionService] for tests that returns [result] and records calls.
class FakePositionService implements PositionService {
  FakePositionService([this.result = const PositionUnavailable()]);

  /// What [currentPosition] returns.
  PositionResult result;

  /// When set, [currentPosition] waits for it instead of returning [result].
  Completer<PositionResult>? pending;

  /// How often a position was requested.
  var requests = 0;

  /// Settings opened, in order: `app` or `location`.
  final openedSettings = <String>[];

  @override
  Future<PositionResult> currentPosition() async {
    requests++;
    return pending?.future ?? result;
  }

  @override
  Future<void> openAppSettings() async => openedSettings.add('app');

  @override
  Future<void> openLocationSettings() async => openedSettings.add('location');
}
