import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../domain/trip_map.dart';
import 'osm_tiles.dart';

/// The trip map on OpenStreetMap tiles with the route and numbered markers.
///
/// Follows the OSM tile usage policy: app-specific User-Agent, visible
/// attribution, tiles cached by `flutter_map`, no bulk download.
class OsmTripMap extends StatelessWidget {
  const OsmTripMap({
    super.key,
    required this.points,
    required this.onOpenEntry,
    this.interactive = true,
    this.tileProvider,
  });

  final List<MapPoint> points;
  final ValueChanged<String> onOpenEntry;

  /// Whether the map can be panned and zoomed (markers work either way).
  final bool interactive;

  /// Tile source; only replaced in tests.
  final TileProvider? tileProvider;

  @override
  Widget build(BuildContext context) {
    final bounds = boundsOf(points);
    final legs = routeLegs(points);
    final routeColor = Theme.of(context).colorScheme.secondary;
    return FlutterMap(
      options: MapOptions(
        initialCenter: const LatLng(0, 0),
        initialZoom: 2,
        initialCameraFit: bounds == null
            ? null
            : CameraFit.bounds(
                bounds: LatLngBounds(
                  LatLng(bounds.south, bounds.west),
                  LatLng(bounds.north, bounds.east),
                ),
                padding: const EdgeInsets.all(48),
              ),
        interactionOptions: InteractionOptions(
          flags: interactive
              ? InteractiveFlag.all & ~InteractiveFlag.rotate
              : InteractiveFlag.none,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: osmTileUrl,
          userAgentPackageName: osmUserAgentPackageName,
          tileProvider: tileProvider,
        ),
        if (legs.isNotEmpty)
          PolylineLayer(
            polylines: [
              for (final leg in legs)
                Polyline(
                  points: [
                    LatLng(leg.start.latitude, leg.start.longitude),
                    LatLng(leg.end.latitude, leg.end.longitude),
                  ],
                  color: routeColor,
                  strokeWidth: 4,
                  strokeCap: StrokeCap.round,
                  // Long legs are probably flights or ferries, not the way
                  // actually travelled.
                  pattern: leg.isLong
                      ? StrokePattern.dashed(segments: const [12, 10])
                      : const StrokePattern.solid(),
                ),
            ],
          ),
        MarkerLayer(
          markers: [
            for (final point in points)
              Marker(
                point: LatLng(
                  point.location.latitude,
                  point.location.longitude,
                ),
                width: 36,
                height: 36,
                child: _NumberMarker(
                  point: point,
                  onTap: () => onOpenEntry(point.entryId),
                ),
              ),
          ],
        ),
        const OsmAttribution(),
      ],
    );
  }
}

class _NumberMarker extends StatelessWidget {
  const _NumberMarker({required this.point, required this.onTap});

  final MapPoint point;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: point.label.isEmpty ? point.number.toString() : point.label,
      button: true,
      excludeSemantics: true,
      child: Material(
        color: theme.colorScheme.primary,
        shape: CircleBorder(
          side: BorderSide(color: theme.colorScheme.onPrimary, width: 2),
        ),
        elevation: 3,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Center(
            child: Text(
              point.number.toString(),
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
