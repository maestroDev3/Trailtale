import 'geo_point.dart';

/// Outcome of asking for the device's current position.
sealed class PositionResult {
  const PositionResult();
}

/// A position fix; [accuracyMeters] is the radius of likely error.
final class PositionFound extends PositionResult {
  const PositionFound(this.location, {required this.accuracyMeters});

  final GeoPoint location;
  final double accuracyMeters;
}

/// The user did not allow location access; [permanently] means Android
/// will not ask again, only the app settings can change it.
final class PositionDenied extends PositionResult {
  const PositionDenied({required this.permanently});

  final bool permanently;
}

/// Location is turned off on the device.
final class PositionServiceOff extends PositionResult {
  const PositionServiceOff();
}

/// No position could be determined in time.
final class PositionUnavailable extends PositionResult {
  const PositionUnavailable();
}

/// The device's current position, only while the app is in use (never in
/// the background).
abstract interface class PositionService {
  /// Asks for access if needed and returns one fresh position fix.
  Future<PositionResult> currentPosition();

  /// Opens the app's system settings (to allow blocked location access).
  Future<void> openAppSettings();

  /// Opens the device's location settings (to turn location on).
  Future<void> openLocationSettings();
}
