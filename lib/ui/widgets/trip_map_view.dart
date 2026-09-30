import 'package:flutter/widgets.dart';

import '../../domain/trip_map.dart';

/// Builds the map of a trip. Screens only use this builder, so the map
/// provider stays swappable and tests can use a placeholder.
typedef TripMapBuilder = Widget Function({
  required List<MapPoint> points,
  required ValueChanged<String> onOpenEntry,
  bool interactive,
});
