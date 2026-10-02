/// A stop slide with its texts already localized.
class SlideText {
  const SlideText({
    required this.number,
    required this.name,
    required this.dateText,
    required this.notes,
    this.photoPath,
  });

  final int number;
  final String name;
  final String dateText;
  final List<String> notes;

  /// Absolute path of the photo shown behind the slide, if any.
  final String? photoPath;
}

/// Everything a slideshow file shows, with localized texts, so writers only
/// lay it out.
class SlideshowDocument {
  const SlideshowDocument({
    required this.title,
    required this.dateText,
    required this.factsText,
    required this.stops,
    required this.closingTitle,
    required this.wordmark,
    this.coverPhotoPath,
  });

  final String title;
  final String dateText;
  final String factsText;

  /// Absolute path of the title slide's photo, if any.
  final String? coverPhotoPath;
  final List<SlideText> stops;
  final String closingTitle;
  final String wordmark;
}

/// Writes a slideshow file, e.g. a PDF.
abstract interface class SlideshowWriter {
  /// Returns the file's bytes.
  Future<List<int>> write(SlideshowDocument document);
}

/// Makes photos small enough to embed, e.g. at most [maxSide] pixels.
abstract interface class PhotoShrinker {
  /// Returns a JPEG of the photo at [path], or `null` if it can't be read.
  Future<List<int>?> shrink(String path, {required int maxSide});
}
