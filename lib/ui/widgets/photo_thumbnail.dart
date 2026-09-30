import 'dart:io';

import 'package:flutter/material.dart';

/// Square, rounded preview of a stored photo; shows a placeholder icon if the
/// file cannot be read (e.g. it was removed).
class PhotoThumbnail extends StatelessWidget {
  const PhotoThumbnail({super.key, required this.file, required this.size});

  final File file;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final pixels = (size * MediaQuery.devicePixelRatioOf(context)).round();
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox.square(
        dimension: size,
        child: Image.file(
          file,
          fit: BoxFit.cover,
          cacheWidth: pixels,
          errorBuilder: (context, error, stackTrace) => ColoredBox(
            color: colorScheme.surfaceContainerHighest,
            child: Icon(
              Icons.broken_image_outlined,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
