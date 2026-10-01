import 'package:flutter/material.dart';
import 'package:trailtale/domain/geo_point.dart';
import 'package:trailtale/ui/widgets/picker_map.dart';

/// A [PickerMapBuilder] for widget tests (no network). Shows its center as
/// “Map center: lat, lng”; with [panTo], a “Pan map” button simulates the
/// user moving the map there.
PickerMapBuilder placeholderPickerMap({GeoPoint? panTo}) =>
    ({
      required controller,
      required initialCenter,
      required initialZoom,
      required onCenterChanged,
    }) => _PlaceholderPickerMap(
      controller: controller,
      initialCenter: initialCenter,
      onCenterChanged: onCenterChanged,
      panTo: panTo,
    );

class _PlaceholderPickerMap extends StatefulWidget {
  const _PlaceholderPickerMap({
    required this.controller,
    required this.initialCenter,
    required this.onCenterChanged,
    required this.panTo,
  });

  final PickerMapController controller;
  final GeoPoint initialCenter;
  final ValueChanged<GeoPoint> onCenterChanged;
  final GeoPoint? panTo;

  @override
  State<_PlaceholderPickerMap> createState() => _PlaceholderPickerMapState();
}

class _PlaceholderPickerMapState extends State<_PlaceholderPickerMap> {
  late GeoPoint _center = widget.initialCenter;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_follow);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_follow);
    super.dispose();
  }

  void _follow() {
    if (widget.controller.target case final target?) _moveTo(target.center);
  }

  void _moveTo(GeoPoint center) {
    setState(() => _center = center);
    widget.onCenterChanged(center);
  }

  @override
  Widget build(BuildContext context) {
    final latitude = _center.latitude.toStringAsFixed(4);
    final longitude = _center.longitude.toStringAsFixed(4);
    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      child: Align(
        alignment: Alignment.topLeft,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Map center: $latitude, $longitude'),
            if (widget.panTo case final target?)
              TextButton(
                onPressed: () => _moveTo(target),
                child: const Text('Pan map'),
              ),
          ],
        ),
      ),
    );
  }
}
