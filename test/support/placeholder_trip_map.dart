import 'package:flutter/material.dart';
import 'package:trailtale/domain/trip_map.dart';

/// Stands in for the real map in widget tests (no network): lists the points
/// as buttons “Marker n: label”.
class PlaceholderTripMap extends StatelessWidget {
  const PlaceholderTripMap({
    super.key,
    required this.points,
    required this.onOpenEntry,
    this.interactive = true,
    this.fitPadding = 48,
    this.sharp = false,
  });

  final List<MapPoint> points;
  final ValueChanged<String> onOpenEntry;
  final bool interactive;
  final double fitPadding;
  final bool sharp;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      child: Wrap(
        children: [
          for (final point in points)
            TextButton(
              onPressed: () => onOpenEntry(point.entryId),
              child: Text('Marker ${point.number}: ${point.label}'),
            ),
        ],
      ),
    );
  }
}
