import 'geo_point.dart';

/// Result of reading latitude and longitude typed in by the user.
sealed class CoordinatesInput {
  const CoordinatesInput();
}

/// Both fields were left empty; coordinates are optional.
final class NoCoordinates extends CoordinatesInput {
  const NoCoordinates();
}

/// Both fields hold valid coordinates.
final class ValidCoordinates extends CoordinatesInput {
  const ValidCoordinates(this.point);

  final GeoPoint point;
}

/// Why typed coordinates cannot be used.
enum CoordinatesError { incomplete, outOfRange }

/// The fields cannot be turned into a [GeoPoint].
final class InvalidCoordinates extends CoordinatesInput {
  const InvalidCoordinates(this.error);

  final CoordinatesError error;

  @override
  bool operator ==(Object other) =>
      other is InvalidCoordinates && other.error == error;

  @override
  int get hashCode => error.hashCode;
}

/// Reads optional coordinates from two text fields. A comma is accepted as
/// decimal separator.
CoordinatesInput parseCoordinates(String latitudeText, String longitudeText) {
  final latitudeTrimmed = latitudeText.trim();
  final longitudeTrimmed = longitudeText.trim();
  if (latitudeTrimmed.isEmpty && longitudeTrimmed.isEmpty) {
    return const NoCoordinates();
  }
  if (latitudeTrimmed.isEmpty || longitudeTrimmed.isEmpty) {
    return const InvalidCoordinates(CoordinatesError.incomplete);
  }
  final latitude = double.tryParse(latitudeTrimmed.replaceAll(',', '.'));
  final longitude = double.tryParse(longitudeTrimmed.replaceAll(',', '.'));
  if (latitude == null ||
      longitude == null ||
      !latitude.isFinite ||
      !longitude.isFinite ||
      latitude.abs() > 90 ||
      longitude.abs() > 180) {
    return const InvalidCoordinates(CoordinatesError.outOfRange);
  }
  return ValidCoordinates(GeoPoint(latitude: latitude, longitude: longitude));
}
