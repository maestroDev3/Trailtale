import 'dart:async';

import 'package:geolocator/geolocator.dart';

import '../domain/geo_point.dart';
import '../domain/position_service.dart';

/// One fresh position fix through package `geolocator`, only while the app
/// is in use; its background service is removed from the manifest.
class GeolocatorPositionService implements PositionService {
  /// How long to wait for a fix before giving up.
  static const timeLimit = Duration(seconds: 20);

  @override
  Future<PositionResult> currentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return const PositionServiceOff();
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    switch (permission) {
      case LocationPermission.denied:
        return const PositionDenied(permanently: false);
      case LocationPermission.deniedForever:
        return const PositionDenied(permanently: true);
      case LocationPermission.whileInUse ||
          LocationPermission.always ||
          LocationPermission.unableToDetermine:
        break;
    }
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: AndroidSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: timeLimit,
        ),
      );
      return PositionFound(
        GeoPoint(latitude: position.latitude, longitude: position.longitude),
        accuracyMeters: position.accuracy,
      );
    } on LocationServiceDisabledException {
      return const PositionServiceOff();
    } on PermissionDeniedException {
      return const PositionDenied(permanently: false);
    } on TimeoutException {
      return const PositionUnavailable();
    } on Exception {
      return const PositionUnavailable();
    }
  }

  @override
  Future<void> openAppSettings() => Geolocator.openAppSettings();

  @override
  Future<void> openLocationSettings() => Geolocator.openLocationSettings();
}
