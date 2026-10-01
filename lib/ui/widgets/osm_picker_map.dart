import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../../domain/geo_point.dart';
import 'picker_map.dart';

/// The picker map on OpenStreetMap tiles.
class OsmPickerMap extends StatelessWidget {
  const OsmPickerMap({
    super.key,
    required this.controller,
    required this.initialCenter,
    required this.initialZoom,
    required this.onCenterChanged,
    this.tileProvider,
  });

  final PickerMapController controller;
  final GeoPoint initialCenter;
  final double initialZoom;
  final ValueChanged<GeoPoint> onCenterChanged;

  /// Tile source; only replaced in tests.
  final TileProvider? tileProvider;

  @override
  Widget build(BuildContext context) => const SizedBox();
}

/// Turns a map center into a valid [GeoPoint]: longitude wrapped to
/// −180…180, latitude clamped to −90…90.
GeoPoint mapCenterToGeoPoint({
  required double latitude,
  required double longitude,
}) => throw UnimplementedError();
