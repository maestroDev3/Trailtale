import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../domain/entry.dart';
import '../domain/trip.dart';
import '../domain/trip_picture.dart';
import '../l10n/app_localizations.dart';
import 'app_services.dart';
import 'formatting.dart';
import 'picture_photo_chooser.dart';
import 'widgets/trip_picture_view.dart';

/// What the share picture screen makes.
enum _Mode { story, post, carousel }

/// One picture of the carousel with its texts.
typedef _CarouselPicture = ({
  TripPicture picture,
  String? subtitle,
  String? facts,
});

/// Shows the shareable picture of [trip] in Story or Post format, or a
/// carousel (overview plus one picture per day), and shares it or saves it
/// to the gallery as PNGs in full resolution.
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
  /// Time the preview gets to load its map tiles and photos after a change,
  /// before it can be shared.
  static const settleTime = Duration(milliseconds: 1500);

  /// Most pictures an Instagram carousel takes.
  static const maxCarouselPictures = 20;

  final _pictureKey = GlobalKey();
  final _carouselKeys = <GlobalKey>[];
  var _mode = _Mode.story;
  var _leaveOutEnds = false;
  var _busy = false;
  var _settling = true;
  Timer? _settleTimer;
  late final StreamSubscription<List<Entry>> _entriesSubscription;
  var _entries = const <Entry>[];

  /// Photos chosen by hand; empty means the automatic pick.
  var _chosenPhotos = const <String>[];

  @override
  void initState() {
    super.initState();
    _entriesSubscription = widget.services.entryRepository
        .watchEntries(widget.trip.id)
        .listen((entries) => _change(() => _entries = entries));
    _restartSettling();
  }

  @override
  void dispose() {
    _settleTimer?.cancel();
    unawaited(_entriesSubscription.cancel());
    super.dispose();
  }

  void _restartSettling() {
    _settleTimer?.cancel();
    _settling = true;
    _settleTimer = Timer(settleTime, () {
      if (mounted) setState(() => _settling = false);
    });
  }

  /// Applies a change to the picture and gives it time to load again.
  void _change(VoidCallback change) {
    setState(() {
      change();
      _restartSettling();
    });
  }

  TripPicture get _picture => buildTripPicture(
    widget.trip,
    _entries,
    leaveOutEnds: _leaveOutEnds,
    chosenPhotos: _chosenPhotos,
  );

  TripPictureFormat get _format =>
      _mode == _Mode.story ? TripPictureFormat.story : TripPictureFormat.post;

  /// The overview and the day pictures, at most [maxCarouselPictures]; the
  /// flag says whether days were left out.
  (List<_CarouselPicture>, bool) _carousel(
    AppLocalizations l10n,
    TripPicture overview,
  ) {
    final days = buildDayPictures(
      widget.trip,
      _entries,
      leaveOutEnds: _leaveOutEnds,
    );
    final shown = days.take(maxCarouselPictures - 1);
    return (
      [
        (picture: overview, subtitle: null, facts: null),
        for (final day in shown)
          (
            picture: TripPicture(
              title: switch (day.dayNumber) {
                final number? => l10n.tripDayTitle(number),
                null => l10n.tripSingleDate(day.day),
              },
              startDate: day.picture.startDate,
              endDate: day.picture.endDate,
              dayCount: day.picture.dayCount,
              stops: day.picture.stops,
              distanceMeters: day.picture.distanceMeters,
              photoPaths: day.picture.photoPaths,
            ),
            subtitle: day.dayNumber == null ? '' : l10n.tripDayDate(day.day),
            facts: dayPictureFactsText(l10n, day.picture),
          ),
      ],
      days.length > shown.length,
    );
  }

  GlobalKey _carouselKey(int index) {
    while (_carouselKeys.length <= index) {
      _carouselKeys.add(GlobalKey());
    }
    return _carouselKeys[index];
  }

  Future<void> _choosePhotos() async {
    final chosen = await Navigator.of(context).push<List<String>>(
      MaterialPageRoute(
        builder: (_) => PicturePhotoChooser(
          services: widget.services,
          entries: _entries,
          selected: _picture.photoPaths,
        ),
      ),
    );
    if (chosen == null || !mounted) return;
    _change(() => _chosenPhotos = chosen);
  }

  /// Renders the shown picture(s) at [TripPictureFormat.pixelRatio] as PNG
  /// bytes; their photos and map tiles were loaded while they were shown.
  Future<List<Uint8List>?> _renderAll(int carouselCount) async {
    final keys = _mode == _Mode.carousel
        ? [for (var i = 0; i < carouselCount; i++) _carouselKey(i)]
        : [_pictureKey];
    final pictures = <Uint8List>[];
    for (final key in keys) {
      final png = await _render(key);
      if (png == null) return null;
      pictures.add(png);
    }
    return pictures;
  }

  Future<Uint8List?> _render(GlobalKey key) async {
    if (key.currentContext?.findRenderObject()
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

  /// Number of pictures in the shown carousel.
  var _carouselCount = 0;

  Future<void> _withPictures(
    Future<void> Function(List<Uint8List> pngs) use,
  ) async {
    setState(() => _busy = true);
    try {
      final pngs = await _renderAll(_carouselCount);
      if (!mounted) return;
      if (pngs == null) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context).pictureRenderFailed),
            ),
          );
        return;
      }
      await use(pngs);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// File title of picture [index]: the trip title, numbered in a
  /// carousel (“Montenegro-01”).
  String _title(int index) => _mode == _Mode.carousel
      ? '${widget.trip.title}-${(index + 1).toString().padLeft(2, '0')}'
      : widget.trip.title;

  Future<void> _share() => _withPictures((pngs) async {
    final services = widget.services;
    final files = [
      for (final (index, png) in pngs.indexed)
        await services.temporaryFiles.write('${_title(index)}.png', png),
    ];
    if (_mode == _Mode.carousel) {
      await services.fileSharer.shareFiles(files, subject: widget.trip.title);
    } else {
      await services.fileSharer.shareFile(
        files.single,
        subject: widget.trip.title,
      );
    }
  });

  Future<void> _save() => _withPictures((pngs) async {
    var saved = true;
    for (final (index, png) in pngs.indexed) {
      saved &= await widget.services.photoGallery.saveImage(
        png,
        title: _title(index),
      );
    }
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
    final picture = _picture;
    final canExport = !_busy && !_settling;
    final (carousel, carouselCapped) = _mode == _Mode.carousel
        ? _carousel(l10n, picture)
        : (const <_CarouselPicture>[], false);
    _carouselCount = carousel.length;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.sharePicture)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: SegmentedButton<_Mode>(
              segments: [
                ButtonSegment(
                  value: _Mode.story,
                  label: Text(l10n.pictureStoryFormat),
                ),
                ButtonSegment(
                  value: _Mode.post,
                  label: Text(l10n.picturePostFormat),
                ),
                ButtonSegment(
                  value: _Mode.carousel,
                  label: Text(l10n.pictureCarouselFormat),
                ),
              ],
              selected: {_mode},
              onSelectionChanged: (selection) =>
                  _change(() => _mode = selection.first),
            ),
          ),
          SwitchListTile(
            title: Text(l10n.pictureLeaveOutEnds),
            value: _leaveOutEnds,
            onChanged: (value) => _change(() => _leaveOutEnds = value),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: Text(l10n.choosePicturePhotos),
            subtitle: Text(
              _chosenPhotos.isEmpty
                  ? l10n.picturePhotosAutomatic
                  : l10n.picturePhotosChosen(picture.photoPaths.length),
            ),
            onTap: _choosePhotos,
          ),
          Expanded(
            child: _mode == _Mode.carousel
                ? _CarouselPreview(
                    pictures: carousel,
                    capped: carouselCapped
                        ? l10n.pictureCarouselLimit(maxCarouselPictures)
                        : null,
                    keyOf: _carouselKey,
                    services: services,
                  )
                : Padding(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: FittedBox(
                        child: _PictureFrame(
                          boundaryKey: _pictureKey,
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
                  onPressed: canExport ? _save : null,
                  icon: const Icon(Icons.download_outlined),
                  label: Text(l10n.saveToGallery),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: canExport ? _share : null,
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

/// A picture with a soft shadow, rendered through [boundaryKey].
class _PictureFrame extends StatelessWidget {
  const _PictureFrame({required this.boundaryKey, required this.child});

  final GlobalKey boundaryKey;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.18),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: RepaintBoundary(key: boundaryKey, child: child),
    );
  }
}

/// All carousel pictures below each other. A plain scroll view (not a lazy
/// list) keeps every picture built and painted, so each can be rendered.
class _CarouselPreview extends StatelessWidget {
  const _CarouselPreview({
    required this.pictures,
    required this.capped,
    required this.keyOf,
    required this.services,
  });

  final List<_CarouselPicture> pictures;

  /// Hint that days were left out, if any.
  final String? capped;
  final GlobalKey Function(int index) keyOf;
  final AppServices services;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const format = TripPictureFormat.post;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (capped case final hint?) ...[
            Text(
              hint,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
          ],
          for (final (index, item) in pictures.indexed) ...[
            if (index > 0) const SizedBox(height: 16),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 300),
              child: AspectRatio(
                aspectRatio:
                    format.logicalSize.width / format.logicalSize.height,
                child: FittedBox(
                  child: _PictureFrame(
                    boundaryKey: keyOf(index),
                    child: TripPictureView(
                      picture: item.picture,
                      format: format,
                      photoFile: services.photoLibrary.fileFor,
                      routeMap: services.tripMap,
                      subtitle: item.subtitle,
                      facts: item.facts,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
