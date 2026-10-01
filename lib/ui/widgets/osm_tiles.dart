import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// OpenStreetMap's standard tiles. The OSM tile usage policy applies:
/// app-specific User-Agent, visible attribution, tiles cached by
/// `flutter_map`, no bulk download.
const osmTileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

/// Identifies Trailtale in the tile requests' User-Agent.
const osmUserAgentPackageName = 'de.maestrodev.trailtale';

/// “© OpenStreetMap contributors”, always visible as the license requires.
class OsmAttribution extends StatelessWidget {
  const OsmAttribution({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.bottomRight,
      child: Container(
        margin: const EdgeInsets.all(6),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLowest.withValues(
            alpha: 0.85,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          AppLocalizations.of(context).osmAttribution,
          style: theme.textTheme.labelSmall,
        ),
      ),
    );
  }
}
