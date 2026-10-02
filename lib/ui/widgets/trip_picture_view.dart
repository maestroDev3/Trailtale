import 'dart:io';

import 'package:flutter/material.dart';

import '../../domain/trip_picture.dart';

/// Formats of the shareable trip picture.
enum TripPictureFormat {
  story(Size(360, 640)),
  post(Size(360, 450));

  const TripPictureFormat(this.logicalSize);

  /// Rendering scale: 360 logical pixels become 1080 image pixels.
  static const pixelRatio = 3.0;

  final Size logicalSize;

  Size get pixelSize => logicalSize * pixelRatio;
}

/// The shareable picture of a trip.
class TripPictureView extends StatelessWidget {
  const TripPictureView({
    super.key,
    required this.picture,
    required this.format,
    required this.photoFile,
  });

  final TripPicture picture;
  final TripPictureFormat format;
  final File Function(String path) photoFile;

  @override
  Widget build(BuildContext context) => const SizedBox();
}
