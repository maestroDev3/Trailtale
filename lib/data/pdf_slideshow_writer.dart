import '../domain/slideshow_document.dart';

/// Lays out a [SlideshowDocument] as a 16:9 PDF (package `pdf`).
class PdfSlideshowWriter implements SlideshowWriter {
  PdfSlideshowWriter({required this.shrinker, this.compress = true});

  final PhotoShrinker shrinker;
  final bool compress;

  /// Longest side of embedded photos in pixels.
  static const photoMaxSide = 1600;

  @override
  Future<List<int>> write(SlideshowDocument document) =>
      throw UnimplementedError();
}
