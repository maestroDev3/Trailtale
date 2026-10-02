import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../domain/entry.dart';
import '../domain/trip.dart';
import '../domain/trip_picture.dart';
import '../l10n/app_localizations.dart';
import 'app_services.dart';
import 'picture_photo_chooser.dart';
import 'widgets/trip_picture_view.dart';

/// Shows the shareable picture of [trip] in Story or Post format and shares
/// it or saves it to the gallery as a PNG in full resolution.
class SharePictureScreen extends StatefulWidget {
  const SharePictureScreen({
    super.key,
    required this.services,
    required this.trip,
  });

  final AppServices services;
  final Trip trip;

  @override
  State<SharePictureScreen> createState() => _SharePictureScreenState();
}

class _SharePictureScreenState extends State<SharePictureScreen> {
  final _pictureKey = GlobalKey();
  var _format = TripPictureFormat.story;
  var _leaveOutEnds = false;
  var _busy = false;
  TripPicture? _picture;
  List<Entry> _entries = const [];

  /// Photos chosen by hand; empty means the automatic pick.
  var _chosenPhotos = const <String>[];

  Future<void> _choosePhotos() async {
    final chosen = await Navigator.of(context).push<List<String>>(
      MaterialPageRoute(
        builder: (_) => PicturePhotoChooser(
          services: widget.services,
          entries: _entries,
          selected: _picture?.photoPaths ?? const [],
        ),
      ),
    );
    if (chosen == null || !mounted) return;
    setState(() => _chosenPhotos = chosen);
  }

  /// Renders the picture at [TripPictureFormat.pixelRatio] as PNG bytes,
  /// after its photos are loaded.
  Future<Uint8List?> _render() async {
    final picture = _picture;
    if (picture != null) {
      for (final path in picture.photoPaths) {
        await precacheImage(
          FileImage(widget.services.photoLibrary.fileFor(path)),
          context,
          onError: (error, stackTrace) {},
        );
        if (!mounted) return null;
      }
    }
    if (_pictureKey.currentContext?.findRenderObject()
        case final RenderRepaintBoundary boundary) {
      final image = await boundary.toImage(
        pixelRatio: TripPictureFormat.pixelRatio,
      );
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      return data?.buffer.asUint8List();
    }
    return null;
  }

  Future<void> _withPicture(Future<void> Function(Uint8List png) use) async {
    setState(() => _busy = true);
    try {
      final png = await _render();
      if (png != null && mounted) await use(png);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _share() => _withPicture((png) async {
    final services = widget.services;
    final file = await services.temporaryFiles.write(
      '${widget.trip.title}.png',
      png,
    );
    await services.fileSharer.shareFile(file, subject: widget.trip.title);
  });

  Future<void> _save() => _withPicture((png) async {
    final saved = await widget.services.photoGallery.saveImage(
      png,
      title: widget.trip.title,
    );
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(saved ? l10n.savedToGallery : l10n.saveToGalleryFailed),
        ),
      );
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final services = widget.services;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.sharePicture)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: SegmentedButton<TripPictureFormat>(
              segments: [
                ButtonSegment(
                  value: TripPictureFormat.story,
                  label: Text(l10n.pictureStoryFormat),
                ),
                ButtonSegment(
                  value: TripPictureFormat.post,
                  label: Text(l10n.picturePostFormat),
                ),
              ],
              selected: {_format},
              onSelectionChanged: (selection) =>
                  setState(() => _format = selection.first),
            ),
          ),
          SwitchListTile(
            title: Text(l10n.pictureLeaveOutEnds),
            value: _leaveOutEnds,
            onChanged: (value) => setState(() => _leaveOutEnds = value),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: Text(l10n.choosePicturePhotos),
            subtitle: Text(
              _chosenPhotos.isEmpty
                  ? l10n.picturePhotosAutomatic
                  : l10n.picturePhotosChosen(_chosenPhotos.length),
            ),
            onTap: _choosePhotos,
          ),
          Expanded(
            child: StreamBuilder<List<Entry>>(
              stream: services.entryRepository.watchEntries(widget.trip.id),
              builder: (context, snapshot) {
                _entries = snapshot.data ?? const [];
                final picture = buildTripPicture(
                  widget.trip,
                  _entries,
                  leaveOutEnds: _leaveOutEnds,
                  chosenPhotos: _chosenPhotos,
                );
                _picture = picture;
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: FittedBox(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).colorScheme.shadow
                                  .withValues(alpha: 0.18),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: RepaintBoundary(
                          key: _pictureKey,
                          child: TripPictureView(
                            picture: picture,
                            format: _format,
                            photoFile: services.photoLibrary.fileFor,
                            routeMap: services.tripMap,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _busy ? null : _save,
                  icon: const Icon(Icons.download_outlined),
                  label: Text(l10n.saveToGallery),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _busy ? null : _share,
                  icon: const Icon(Icons.share_outlined),
                  label: Text(l10n.shareAction),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
