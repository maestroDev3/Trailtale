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

/// A photo on its own slide (only the photo).
class PhotoSlideText {
  const PhotoSlideText({required this.photoPath});

  /// Absolute path of the photo.
  final String photoPath;
}

/// A day slide (e.g. “Day 1 · Kotor”) followed by its photo slides.
class DaySlideText {
  const DaySlideText({
    required this.heading,
    required this.dateText,
    required this.notes,
    this.photoPath,
    this.photos = const [],
    this.stops = const [],
  });

  final String heading;
  final String dateText;
  final List<String> notes;

  /// Absolute path of the day's title photo, if any.
  final String? photoPath;
  final List<PhotoSlideText> photos;

  /// Stops within the day, each written like a day after the day's own
  /// slides (empty for a day at one place).
  final List<DaySlideText> stops;
}

/// Everything a slideshow file shows, with localized texts, so writers only
/// lay it out.
class SlideshowDocument {
  const SlideshowDocument({
    required this.title,
    required this.dateText,
    required this.factsText,
    required this.stops,
    this.days = const [],
    required this.closingTitle,
    required this.wordmark,
    this.coverPhotoPath,
  });

  final String title;
  final String dateText;
  final String factsText;

  /// Absolute path of the title slide's photo, if any.
  final String? coverPhotoPath;

  /// The stops, listed on the closing slide.
  final List<SlideText> stops;

  /// The days with their photos.
  final List<DaySlideText> days;
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
