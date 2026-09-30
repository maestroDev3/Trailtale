import 'entry.dart';
import 'geo_point.dart';
import 'trip.dart';

/// Key figures of a trip for an overview at a glance.
class TripSummary {
  const TripSummary({
    required this.dayCount,
    required this.entryCount,
    required this.placeCount,
    required this.photoCount,
    required this.distanceMeters,
  });

  final int dayCount;
  final int entryCount;

  /// Number of distinct place names.
  final int placeCount;
  final int photoCount;

  /// Straight-line distance between consecutive located entries.
  final double distanceMeters;
}

/// Summarizes [trip] with its [entries]: places are distinct place names
/// (case and surrounding spaces ignored), the distance sums great-circle
/// distances between consecutive entries with a location in time order.
TripSummary summarizeTrip(Trip trip, List<Entry> entries) {
  final chronological = sortEntriesChronologically(entries);
  final places = {
    for (final entry in chronological)
      if (entry.placeName case final name?) name.trim().toLowerCase(),
  };
  final locations = chronological
      .map((entry) => entry.location)
      .whereType<GeoPoint>()
      .toList();
  var distance = 0.0;
  for (var i = 1; i < locations.length; i++) {
    distance += locations[i - 1].distanceTo(locations[i]);
  }
  return TripSummary(
    dayCount: trip.dayCount,
    entryCount: entries.length,
    placeCount: places.length,
    photoCount: entries.fold(0, (sum, entry) => sum + entry.photoPaths.length),
    distanceMeters: distance,
  );
}
