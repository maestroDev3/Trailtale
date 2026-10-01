import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../domain/photo_gallery.dart';
import '../domain/trip.dart';
import '../l10n/app_localizations.dart';

/// Lets the user choose photos from the device's gallery, starting with the
/// photos taken during [trip]; returns the chosen photo ids in the order
/// they were selected.
class GalleryPickerScreen extends StatefulWidget {
  const GalleryPickerScreen({
    super.key,
    required this.gallery,
    required this.trip,
    this.access = GalleryAccess.full,
    this.pageSize = 60,
  });

  final PhotoGallery gallery;
  final Trip trip;
  final GalleryAccess access;
  final int pageSize;

  @override
  State<GalleryPickerScreen> createState() => _GalleryPickerScreenState();
}

class _GalleryPickerScreenState extends State<GalleryPickerScreen> {
  var _onlyTrip = true;
  final _photos = <GalleryPhoto>[];
  var _nextPage = 0;
  var _hasMore = true;
  var _loading = false;

  /// Increased on every reload so answers to older requests are dropped.
  var _generation = 0;
  final _selected = <String>[];
  final _thumbnails = <String, Future<Uint8List?>>{};

  @override
  void initState() {
    super.initState();
    unawaited(_loadMore());
  }

  void _reload({required bool onlyTrip}) {
    setState(() {
      _onlyTrip = onlyTrip;
      _generation++;
      _photos.clear();
      _thumbnails.clear();
      _nextPage = 0;
      _hasMore = true;
      _loading = false;
    });
    unawaited(_loadMore());
  }

  Future<void> _loadMore() async {
    if (_loading || !_hasMore) return;
    _loading = true;
    final generation = _generation;
    final period = _onlyTrip ? tripPhotoPeriod(widget.trip) : null;
    final page = await widget.gallery.photos(
      from: period?.from,
      until: period?.until,
      page: _nextPage,
      pageSize: widget.pageSize,
    );
    if (!mounted || generation != _generation) return;
    setState(() {
      _photos.addAll(page);
      _nextPage++;
      _hasMore = page.length == widget.pageSize;
      _loading = false;
    });
  }

  void _toggle(String id) {
    setState(() {
      if (!_selected.remove(id)) _selected.add(id);
    });
  }

  Future<void> _selectMore() async {
    await widget.gallery.selectMorePhotos();
    if (!mounted) return;
    _reload(onlyTrip: _onlyTrip);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final empty = _photos.isEmpty && !_hasMore;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.galleryPickerTitle)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.access == GalleryAccess.limited)
            _LimitedAccessHint(onSelectMore: _selectMore),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: SegmentedButton<bool>(
              segments: [
                ButtonSegment(value: true, label: Text(l10n.galleryThisTrip)),
                ButtonSegment(value: false, label: Text(l10n.galleryAllPhotos)),
              ],
              selected: {_onlyTrip},
              onSelectionChanged: (selection) =>
                  _reload(onlyTrip: selection.first),
            ),
          ),
          Expanded(
            child: empty
                ? _EmptyGallery(
                    onlyTrip: _onlyTrip,
                    onShowAll: () => _reload(onlyTrip: false),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(4),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 4,
                          crossAxisSpacing: 4,
                        ),
                    itemCount: _photos.length,
                    itemBuilder: (context, index) {
                      if (index >= _photos.length - 1) unawaited(_loadMore());
                      final photo = _photos[index];
                      return _GalleryTile(
                        key: ValueKey('gallery-photo-${photo.id}'),
                        photo: photo,
                        thumbnail: _thumbnails[photo.id] ??= widget.gallery
                            .thumbnail(photo.id),
                        selected: _selected.contains(photo.id),
                        onTap: () => _toggle(photo.id),
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: _selected.isEmpty
                ? null
                : () => Navigator.of(context).pop([..._selected]),
            child: Text(l10n.galleryAddPhotos(_selected.length)),
          ),
        ),
      ),
    );
  }
}

class _LimitedAccessHint extends StatelessWidget {
  const _LimitedAccessHint({required this.onSelectMore});

  final VoidCallback onSelectMore;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                l10n.galleryLimitedAccess,
                style: theme.textTheme.bodyMedium,
              ),
            ),
            TextButton(
              onPressed: onSelectMore,
              child: Text(l10n.gallerySelectMore),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyGallery extends StatelessWidget {
  const _EmptyGallery({required this.onlyTrip, required this.onShowAll});

  final bool onlyTrip;
  final VoidCallback onShowAll;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              onlyTrip ? l10n.galleryNoTripPhotos : l10n.galleryNoPhotos,
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            if (onlyTrip) ...[
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: onShowAll,
                child: Text(l10n.galleryShowAllPhotos),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _GalleryTile extends StatelessWidget {
  const _GalleryTile({
    super.key,
    required this.photo,
    required this.thumbnail,
    required this.selected,
    required this.onTap,
  });

  final GalleryPhoto photo;
  final Future<Uint8List?> thumbnail;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    return Semantics(
      container: true,
      button: true,
      selected: selected,
      excludeSemantics: true,
      label: l10n.galleryPhotoLabel(
        photo.takenAt,
        photo.takenAt,
        selected.toString(),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: colorScheme.surfaceContainerHighest),
            FutureBuilder<Uint8List?>(
              future: thumbnail,
              builder: (context, snapshot) => switch (snapshot.data) {
                final bytes? => Image.memory(
                  bytes,
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                  errorBuilder: (context, error, stackTrace) =>
                      const SizedBox.shrink(),
                ),
                null => const SizedBox.shrink(),
              },
            ),
            if (selected)
              DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: colorScheme.primary, width: 4),
                ),
              ),
            Positioned(
              top: 6,
              right: 6,
              child: selected
                  ? CircleAvatar(
                      radius: 12,
                      backgroundColor: colorScheme.primary,
                      child: Icon(
                        Icons.check,
                        size: 16,
                        color: colorScheme.onPrimary,
                      ),
                    )
                  : Icon(Icons.circle_outlined, color: colorScheme.surface),
            ),
          ],
        ),
      ),
    );
  }
}
