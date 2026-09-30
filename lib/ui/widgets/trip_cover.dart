import 'dart:io';

import 'package:flutter/material.dart';

/// A trip's cover photo, filling its box; an illustrated placeholder when
/// the trip has no photo yet or the file cannot be read.
class TripCover extends StatelessWidget {
  const TripCover({super.key, required this.file});

  /// The cover photo, `null` if the trip has no photos.
  final File? file;

  @override
  Widget build(BuildContext context) {
    final file = this.file;
    if (file == null) {
      return const _CoverPlaceholder(key: Key('cover-placeholder'));
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 400.0;
        return Image.file(
          file,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          cacheWidth: (width * MediaQuery.devicePixelRatioOf(context)).round(),
          errorBuilder: (context, error, stackTrace) =>
              const _CoverPlaceholder(),
        );
      },
    );
  }
}

class _CoverPlaceholder extends StatelessWidget {
  const _CoverPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: scheme.secondaryContainer,
      child: Center(
        child: Icon(
          Icons.landscape_outlined,
          size: 32,
          color: scheme.onSecondaryContainer,
        ),
      ),
    );
  }
}
