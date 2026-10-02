import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:image/image.dart' as img;

import '../domain/slideshow_document.dart';

/// Decodes photos with Flutter's image codec (JPEG, HEIC, PNG …, EXIF
/// orientation applied) at a reduced size and encodes them as JPEG
/// (package `image`) in a background isolate.
class CodecPhotoShrinker implements PhotoShrinker {
  /// JPEG quality of the shrunk photos.
  static const quality = 82;

  @override
  Future<List<int>?> shrink(String path, {required int maxSide}) async {
    try {
      final buffer = await ui.ImmutableBuffer.fromUint8List(
        await File(path).readAsBytes(),
      );
      final codec = await ui.instantiateImageCodecWithSize(
        buffer,
        getTargetSize: (width, height) {
          final scale = min(1.0, maxSide / max(width, height));
          return ui.TargetImageSize(
            width: max(1, (width * scale).round()),
            height: max(1, (height * scale).round()),
          );
        },
      );
      final frame = await codec.getNextFrame();
      final image = frame.image;
      final width = image.width;
      final height = image.height;
      final pixels = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      image.dispose();
      codec.dispose();
      if (pixels == null) return null;
      final bytes = pixels.buffer;
      return Isolate.run(
        () => img.encodeJpg(
          img.Image.fromBytes(
            width: width,
            height: height,
            bytes: bytes,
            numChannels: 4,
            order: img.ChannelOrder.rgba,
          ),
          quality: quality,
        ),
      );
    } on Exception {
      return null;
    }
  }
}
