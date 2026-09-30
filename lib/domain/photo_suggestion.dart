import 'geo_point.dart';
import 'photo_metadata.dart';

/// What the photos of an entry suggest for its time and place.
class PhotoSuggestion {
  const PhotoSuggestion({this.takenAt, this.utcOffset, this.location});

  /// Earliest capture time (local wall-clock time) among the photos.
  final DateTime? takenAt;

  /// Offset recorded with [takenAt], if any.
  final Duration? utcOffset;

  /// Position of the earliest photo that has one.
  final GeoPoint? location;

  /// Whether the photos suggest nothing at all.
  bool get isEmpty => takenAt == null && location == null;
}

/// Derives time and place for an entry from the metadata of its photos:
/// the earliest capture time with its offset, and the location of the
/// earliest photo that has one (photos without time count as latest).
PhotoSuggestion suggestFromPhotos(List<PhotoMetadata> photos) {
  final byTime = [...photos]
    ..sort((a, b) {
      final (timeA, timeB) = (a.takenAt, b.takenAt);
      return switch ((timeA, timeB)) {
        (null, null) => 0,
        (null, _) => 1,
        (_, null) => -1,
        (final x?, final y?) => x.compareTo(y),
      };
    });
  final earliest = byTime.where((photo) => photo.takenAt != null).firstOrNull;
  return PhotoSuggestion(
    takenAt: earliest?.takenAt,
    utcOffset: earliest?.utcOffset,
    location: byTime
        .map((photo) => photo.location)
        .whereType<GeoPoint>()
        .firstOrNull,
  );
}
