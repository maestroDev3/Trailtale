import 'dart:io';

import 'package:flutter/material.dart';

import '../../domain/trip_picture.dart';
import '../../l10n/app_localizations.dart';
import '../formatting.dart';
import '../theme.dart';
import 'trailtale_logo.dart';
import 'trip_dates.dart';

/// Formats of the shareable trip picture.
enum TripPictureFormat {
  /// Instagram story, 9:16.
  story(Size(360, 640)),

  /// Instagram post, 4:5.
  post(Size(360, 450));

  const TripPictureFormat(this.logicalSize);

  /// Rendering scale: 360 logical pixels become 1080 image pixels.
  static const pixelRatio = 3.0;

  final Size logicalSize;

  Size get pixelSize => logicalSize * pixelRatio;
}

/// The shareable picture of a trip in the field journal look: title, dates,
/// photos, a stylized route with numbered pins, the stops and key figures.
///
/// Always light (paper) and independent of the system font size, so the
/// shared image looks the same everywhere.
class TripPictureView extends StatelessWidget {
  const TripPictureView({
    super.key,
    required this.picture,
    required this.format,
    required this.photoFile,
  });

  final TripPicture picture;
  final TripPictureFormat format;

  /// Resolves a relative photo path to its file.
  final File Function(String path) photoFile;

  @override
  Widget build(BuildContext context) {
    final theme = buildLightTheme();
    final story = format == TripPictureFormat.story;
    final hasRoute = picture.stops.any((stop) => stop.location != null);
    final photos = picture.photoPaths.isEmpty
        ? null
        : _PhotoGrid(paths: picture.photoPaths, photoFile: photoFile);
    final route = hasRoute ? _RouteCard(stops: picture.stops) : null;
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
      child: Theme(
        data: theme,
        child: SizedBox.fromSize(
          size: format.logicalSize,
          child: Material(
            color: theme.colorScheme.surface,
            child: Padding(
              padding: EdgeInsets.all(story ? 24 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Heading(picture: picture, maxTitleLines: story ? 2 : 1),
                  SizedBox(height: story ? 16 : 12),
                  if (story) ...[
                    if (photos != null) Expanded(flex: 5, child: photos),
                    if (photos != null && route != null)
                      const SizedBox(height: 12),
                    if (route != null) Expanded(flex: 4, child: route),
                  ] else if (photos != null || route != null)
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (route != null) Expanded(child: route),
                          if (route != null && photos != null)
                            const SizedBox(width: 10),
                          if (photos != null) Expanded(child: photos),
                        ],
                      ),
                    ),
                  if (photos == null && route == null) const Spacer(),
                  SizedBox(height: story ? 14 : 10),
                  _StopList(stops: picture.stops, maxStops: story ? 8 : 5),
                  SizedBox(height: story ? 12 : 8),
                  _Facts(picture: picture),
                  SizedBox(height: story ? 14 : 10),
                  const _Wordmark(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading({required this.picture, required this.maxTitleLines});

  final TripPicture picture;
  final int maxTitleLines;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          picture.title,
          maxLines: maxTitleLines,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.headlineMedium?.copyWith(
            color: theme.colorScheme.onSurface,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          dateRangeText(context, picture.startDate, picture.endDate),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _PhotoGrid extends StatelessWidget {
  const _PhotoGrid({required this.paths, required this.photoFile});

  final List<String> paths;
  final File Function(String path) photoFile;

  Widget _photo(int index) => _Photo(
    key: Key('trip-picture-photo-$index'),
    file: photoFile(paths[index]),
  );

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox.square(dimension: 6);
    Widget column(List<int> indexes) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (position, index) in indexes.indexed) ...[
          if (position > 0) gap,
          Expanded(child: _photo(index)),
        ],
      ],
    );
    return switch (paths.length) {
      1 => _photo(0),
      2 => Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [Expanded(child: _photo(0)), gap, Expanded(child: _photo(1))],
      ),
      3 => Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: 3, child: _photo(0)),
          gap,
          Expanded(flex: 2, child: column([1, 2])),
        ],
      ),
      _ => Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: column([0, 2])),
          gap,
          Expanded(child: column([1, 3])),
        ],
      ),
    };
  }
}

class _Photo extends StatelessWidget {
  const _Photo({super.key, required this.file});

  final File file;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.file(
        file,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            ColoredBox(color: colorScheme.surfaceContainerHighest),
      ),
    );
  }
}

class _RouteCard extends StatelessWidget {
  const _RouteCard({required this.stops});

  final List<TripStop> stops;

  static const _pinSize = 22.0;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      key: const Key('trip-picture-route'),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final positions = layoutRoute(
            [for (final stop in stops) stop.location],
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            margin: _pinSize,
          );
          final trail = [
            for (final position in positions)
              if (position != null) Offset(position.x, position.y),
          ];
          return Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _TrailPainter(trail, color: colorScheme.secondary),
                ),
              ),
              for (final (index, position) in positions.indexed)
                if (position != null)
                  Positioned(
                    left: position.x - _pinSize / 2,
                    top: position.y - _pinSize / 2,
                    child: _Pin(key: Key('trip-picture-pin-${index + 1}'), number: index + 1),
                  ),
            ],
          );
        },
      ),
    );
  }
}

/// Dotted trail through the pins, like the Trailtale mark.
class _TrailPainter extends CustomPainter {
  _TrailPainter(this.points, {required this.color});

  final List<Offset> points;
  final Color color;

  static const _spacing = 7.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..isAntiAlias = true;
    for (var i = 1; i < points.length; i++) {
      final start = points[i - 1];
      final delta = points[i] - start;
      final steps = (delta.distance / _spacing).floor();
      for (var step = 1; step < steps; step++) {
        canvas.drawCircle(start + delta * (step / steps), 1.6, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_TrailPainter oldDelegate) =>
      oldDelegate.points != points || oldDelegate.color != color;
}

class _Pin extends StatelessWidget {
  const _Pin({super.key, required this.number});

  final int number;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: _RouteCard._pinSize,
      height: _RouteCard._pinSize,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        shape: BoxShape.circle,
        border: Border.all(color: theme.colorScheme.onPrimary, width: 2),
      ),
      child: Text(
        number.toString(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _StopList extends StatelessWidget {
  const _StopList({required this.stops, required this.maxStops});

  final List<TripStop> stops;
  final int maxStops;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final shown = stops.take(maxStops).toList();
    final hidden = stops.length - shown.length;
    return Wrap(
      spacing: 10,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final (index, stop) in shown.indexed)
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 150),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  (index + 1).toString(),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    stop.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        if (hidden > 0)
          Text(
            l10n.pictureMoreStops(hidden),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }
}

class _Facts extends StatelessWidget {
  const _Facts({required this.picture});

  final TripPicture picture;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final text = picture.distanceMeters > 0
        ? l10n.pictureFacts(
            picture.dayCount,
            picture.placeCount,
            formatKilometers(picture.distanceMeters, l10n.localeName),
          )
        : l10n.pictureFactsNoDistance(picture.dayCount, picture.placeCount);
    return Text(
      text,
      style: theme.textTheme.titleSmall?.copyWith(
        color: theme.colorScheme.secondary,
      ),
    );
  }
}

class _Wordmark extends StatelessWidget {
  const _Wordmark();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        const TrailtaleLogo(size: 20),
        const SizedBox(width: 8),
        Text(
          AppLocalizations.of(context).appTitle,
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
