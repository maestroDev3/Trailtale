import 'dart:math';

/// A position on earth (WGS 84), e.g. where an entry happened.
///
/// The optional [name] is a human-readable label such as a city.
class GeoPoint {
  /// Creates a validated point; throws [ArgumentError] for coordinates out of
  /// range or not finite.
  factory GeoPoint({
    required double latitude,
    required double longitude,
    String? name,
  }) {
    if (!latitude.isFinite || latitude < -90 || latitude > 90) {
      throw ArgumentError.value(latitude, 'latitude', 'must be in -90…90');
    }
    if (!longitude.isFinite || longitude < -180 || longitude > 180) {
      throw ArgumentError.value(longitude, 'longitude', 'must be in -180…180');
    }
    final trimmedName = name?.trim();
    return GeoPoint._(
      latitude,
      longitude,
      trimmedName == null || trimmedName.isEmpty ? null : trimmedName,
    );
  }

  const GeoPoint._(this.latitude, this.longitude, this.name);

  /// Mean earth radius used for distances, in meters.
  static const earthRadiusMeters = 6371000.0;

  final double latitude;
  final double longitude;
  final String? name;

  /// Great-circle distance to [other] in meters (haversine formula).
  double distanceTo(GeoPoint other) {
    final lat1 = _radians(latitude);
    final lat2 = _radians(other.latitude);
    final deltaLat = lat2 - lat1;
    final deltaLon = _radians(other.longitude - longitude);
    final a =
        pow(sin(deltaLat / 2), 2) +
        cos(lat1) * cos(lat2) * pow(sin(deltaLon / 2), 2);
    return 2 * earthRadiusMeters * asin(sqrt(a));
  }

  @override
  bool operator ==(Object other) =>
      other is GeoPoint &&
      other.latitude == latitude &&
      other.longitude == longitude &&
      other.name == name;

  @override
  int get hashCode => Object.hash(latitude, longitude, name);

  @override
  String toString() => 'GeoPoint($latitude, $longitude, $name)';
}

double _radians(double degrees) => degrees * pi / 180;
