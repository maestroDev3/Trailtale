import 'dart:io';

import 'geo_point.dart';

/// What a photo file tells about when and where it was taken.
class PhotoMetadata {
  const PhotoMetadata({this.takenAt, this.utcOffset, this.location});

  /// Local wall-clock time of the capture (fields as shown on the camera).
  final DateTime? takenAt;

  /// Offset of [takenAt] from UTC, if the camera recorded it.
  final Duration? utcOffset;

  /// Where the photo was taken, if the camera recorded it.
  final GeoPoint? location;

  @override
  bool operator ==(Object other) =>
      other is PhotoMetadata &&
      other.takenAt == takenAt &&
      other.utcOffset == utcOffset &&
      other.location == location;

  @override
  int get hashCode => Object.hash(takenAt, utcOffset, location);

  @override
  String toString() => 'PhotoMetadata($takenAt, $utcOffset, $location)';
}

/// Reads [PhotoMetadata] from photo files; behind an interface so tests can
/// use a fake instead of real images.
abstract interface class PhotoMetadataReader {
  /// Reads the metadata of [file]; returns empty metadata if the file has
  /// none or cannot be read.
  Future<PhotoMetadata> read(File file);
}
