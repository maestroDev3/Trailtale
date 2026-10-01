import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../domain/geo_point.dart';
import 'osm_tiles.dart';
import 'picker_map.dart';

/// The picker map on OpenStreetMap tiles: reports its center on every
/// camera change and follows [controller].
class OsmPickerMap extends StatefulWidget {
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
  State<OsmPickerMap> createState() => _OsmPickerMapState();
}

class _OsmPickerMapState extends State<OsmPickerMap> {
  final _map = MapController();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_follow);
  }

  @override
  void didUpdateWidget(OsmPickerMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_follow);
      widget.controller.addListener(_follow);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_follow);
    _map.dispose();
    super.dispose();
  }

  void _follow() {
    final target = widget.controller.target;
    if (target == null) return;
    _map.move(
      LatLng(target.center.latitude, target.center.longitude),
      target.zoom,
    );
  }

  @override
  Widget build(BuildContext context) {
    final center = widget.initialCenter;
    return FlutterMap(
      mapController: _map,
      options: MapOptions(
        initialCenter: LatLng(center.latitude, center.longitude),
        initialZoom: widget.initialZoom,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
        onPositionChanged: (camera, hasGesture) => widget.onCenterChanged(
          mapCenterToGeoPoint(
            latitude: camera.center.latitude,
            longitude: camera.center.longitude,
          ),
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: osmTileUrl,
          userAgentPackageName: osmUserAgentPackageName,
          tileProvider: widget.tileProvider,
        ),
        const OsmAttribution(),
      ],
    );
  }
}

/// Turns a map center into a valid [GeoPoint]: longitude wrapped to
/// −180…180, latitude clamped to −90…90.
GeoPoint mapCenterToGeoPoint({
  required double latitude,
  required double longitude,
}) {
  var wrapped = (longitude + 180) % 360 - 180;
  if (wrapped == -180 && longitude > 0) wrapped = 180;
  return GeoPoint(
    latitude: latitude.clamp(-90, 90).toDouble(),
    longitude: wrapped,
  );
}
