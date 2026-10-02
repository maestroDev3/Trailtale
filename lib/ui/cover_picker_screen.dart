import 'package:flutter/material.dart';

import '../domain/entry.dart';
import '../domain/trip.dart';
import '../domain/trip_overview.dart';
import '../l10n/app_localizations.dart';
import 'app_services.dart';

/// Lets the traveler choose the cover photo of [trip] among the photos of
/// its [entries], or go back to the automatic cover.
class CoverPickerScreen extends StatelessWidget {
  const CoverPickerScreen({
    super.key,
    required this.services,
    required this.trip,
    required this.entries,
  });

  final AppServices services;
  final Trip trip;
  final List<Entry> entries;

  Future<void> _save(BuildContext context, Trip changed) async {
    await services.tripRepository.saveTrip(changed);
    if (context.mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final photos = tripPhotos(entries);
    final current = coverPhotoOf(entries, chosen: trip.coverPhotoPath);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.chooseCover),
        actions: [
          TextButton(
            onPressed: () =>
                _save(context, trip.copyWith(clearCoverPhoto: true)),
            child: Text(l10n.automaticCover),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
        ),
        itemCount: photos.length,
        itemBuilder: (context, index) {
          final path = photos[index];
          return _CoverOption(
            key: Key('cover-option-$path'),
            services: services,
            path: path,
            selected: path == current,
            onTap: () => _save(context, trip.copyWith(coverPhotoPath: path)),
          );
        },
      ),
    );
  }
}

class _CoverOption extends StatelessWidget {
  const _CoverOption({
    super.key,
    required this.services,
    required this.path,
    required this.selected,
    required this.onTap,
  });

  final AppServices services;
  final String path;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.file(
                services.photoLibrary.fileFor(path),
                fit: BoxFit.cover,
                cacheWidth: 360,
                errorBuilder: (context, error, stackTrace) => ColoredBox(
                  color: colorScheme.surfaceContainerHighest,
                  child: Icon(
                    Icons.broken_image_outlined,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              if (selected) ...[
                DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(color: colorScheme.primary, width: 4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: CircleAvatar(
                    radius: 12,
                    backgroundColor: colorScheme.primary,
                    child: Icon(
                      Icons.check,
                      size: 16,
                      color: colorScheme.onPrimary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
