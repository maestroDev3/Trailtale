import 'package:flutter/material.dart';

import '../domain/entry.dart';
import '../domain/trip_overview.dart';
import '../domain/trip_picture.dart';
import '../l10n/app_localizations.dart';
import 'app_services.dart';

/// Lets the traveler choose up to [TripPicture.maxPhotos] photos of the trip
/// for the trip picture, numbered in the order they are tapped.
///
/// Returns the chosen paths, an empty list for "Automatic", or `null` when
/// the traveler goes back.
class PicturePhotoChooser extends StatefulWidget {
  const PicturePhotoChooser({
    super.key,
    required this.services,
    required this.entries,
    required this.selected,
  });

  final AppServices services;
  final List<Entry> entries;

  /// The photos selected when the chooser opens.
  final List<String> selected;

  @override
  State<PicturePhotoChooser> createState() => _PicturePhotoChooserState();
}

class _PicturePhotoChooserState extends State<PicturePhotoChooser> {
  late final List<String> _selected = [...widget.selected];

  void _toggle(String path) {
    if (_selected.remove(path)) {
      setState(() {});
      return;
    }
    if (_selected.length >= TripPicture.maxPhotos) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)
                  .picturePhotoLimit(TripPicture.maxPhotos),
            ),
          ),
        );
      return;
    }
    setState(() => _selected.add(path));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final photos = tripPhotos(widget.entries);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.choosePicturePhotos),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(const <String>[]),
            child: Text(l10n.picturePhotosAutomatic),
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
          final position = _selected.indexOf(path);
          return _PhotoOption(
            key: Key('picture-photo-$path'),
            services: widget.services,
            path: path,
            number: position < 0 ? null : position + 1,
            onTap: () => _toggle(path),
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: _selected.isEmpty
                ? null
                : () => Navigator.of(context).pop([..._selected]),
            child: Text(l10n.useChosenPhotos(_selected.length)),
          ),
        ),
      ),
    );
  }
}

class _PhotoOption extends StatelessWidget {
  const _PhotoOption({
    super.key,
    required this.services,
    required this.path,
    required this.number,
    required this.onTap,
  });

  final AppServices services;
  final String path;

  /// Position in the selection (1-based), `null` when not selected.
  final int? number;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final number = this.number;
    return Semantics(
      button: true,
      selected: number != null,
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
              if (number != null) ...[
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
                    child: Text(
                      number.toString(),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colorScheme.onPrimary,
                      ),
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
