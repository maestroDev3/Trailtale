import 'dart:math';

import 'entry.dart';
import 'geo_point.dart';

/// A numbered point on the trip map, standing for one entry.
class MapPoint {
  const MapPoint({
    required this.number,
    required this.entryId,
    required this.location,
    required this.label,
  });

  /// 1 for the first place visited, 2 for the next, …
  final int number;
  final String entryId;
  final GeoPoint location;

  /// Place name, else the note's first line, else empty.
  final String label;
}

/// The map area that shows all points.
class MapBounds {
  const MapBounds({
    required this.south,
    required this.west,
    required this.north,
    required this.east,
  });

  final double south;
  final double west;
  final double north;
  final double east;
}

/// One point per entry with a location, numbered in chronological order.
List<MapPoint> tripMapPoints(List<Entry> entries) {
  final located = [
    for (final entry in sortEntriesChronologically(entries))
      if (entry.location case final location?) (entry, location),
  ];
  return [
    for (final (index, (entry, location)) in located.indexed)
      MapPoint(
        number: index + 1,
        entryId: entry.id,
        location: location,
        label: entry.placeName ?? entry.note.split('\n').first,
      ),
  ];
}

/// Smallest span in degrees, so a single point is not zoomed in endlessly.
const _minimumSpan = 0.02;

/// The bounds around [points], `null` without points.
MapBounds? boundsOf(List<MapPoint> points) {
  if (points.isEmpty) return null;
  final latitudes = points.map((point) => point.location.latitude);
  final longitudes = points.map((point) => point.location.longitude);
  var south = latitudes.reduce(min);
  var north = latitudes.reduce(max);
  var west = longitudes.reduce(min);
  var east = longitudes.reduce(max);
  if (north - south < _minimumSpan) {
    final middle = (north + south) / 2;
    south = middle - _minimumSpan / 2;
    north = middle + _minimumSpan / 2;
  }
  if (east - west < _minimumSpan) {
    final middle = (east + west) / 2;
    west = middle - _minimumSpan / 2;
    east = middle + _minimumSpan / 2;
  }
  return MapBounds(south: south, west: west, north: north, east: east);
}
