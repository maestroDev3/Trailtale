import 'geo_point.dart';
import 'trip.dart';
import 'entry.dart';

/// A place of the trip, in visiting order.
class TripStop {
  const TripStop({required this.name, this.location});

  final String name;

  /// Location of the first located entry with this name, if any.
  final GeoPoint? location;
}

/// What a shareable picture of a trip shows.
class TripPicture {
  const TripPicture({
    required this.title,
    required this.startDate,
    required this.endDate,
    required this.dayCount,
    required this.stops,
    required this.distanceMeters,
    required this.photoPaths,
  });

  final String title;
  final DateTime startDate;
  final DateTime endDate;
  final int dayCount;
  final List<TripStop> stops;
  final double distanceMeters;

  /// Relative photo paths, at most [maxPhotos].
  final List<String> photoPaths;

  int get placeCount => stops.length;
}

/// Builds the content of a trip picture.
TripPicture buildTripPicture(
  Trip trip,
  List<Entry> entries, {
  required bool leaveOutEnds,
}) => throw UnimplementedError();

/// Positions the [locations] in a box of [width] × [height].
List<({double x, double y})?> layoutRoute(
  List<GeoPoint?> locations, {
  required double width,
  required double height,
  required double margin,
}) => throw UnimplementedError();
