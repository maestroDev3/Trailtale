import 'package:flutter/widgets.dart';

import '../../domain/geo_point.dart';

/// Lets a screen move the picker map, e.g. to a search result.
class PickerMapController extends ChangeNotifier {
  ({GeoPoint center, double zoom})? _target;

  /// The latest requested camera position, `null` before the first move.
  ({GeoPoint center, double zoom})? get target => _target;

  /// Moves the map to [center] at [zoom].
  void moveTo(GeoPoint center, {double zoom = 15}) {
    _target = (center: center, zoom: zoom);
    notifyListeners();
  }
}

/// Builds the map in which the user picks a place by moving it under a
/// fixed crosshair. Screens only use this builder, so the map provider stays
/// swappable and tests can use a placeholder.
typedef PickerMapBuilder = Widget Function({
  required PickerMapController controller,
  required GeoPoint initialCenter,
  required double initialZoom,
  required ValueChanged<GeoPoint> onCenterChanged,
});
