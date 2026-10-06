import 'entry.dart';
import 'geo_point.dart';
import 'photo_metadata.dart';
import 'place.dart';

/// A photo another app shared to Trailtale, with what it says about itself.
class SharedPhoto {
  const SharedPhoto({required this.path, required this.metadata});

  /// Where the shared copy lies (absolute path).
  final String path;
  final PhotoMetadata metadata;
}

/// Photos taken close together – one suggested entry.
class PhotoGroup {
  const PhotoGroup({
    required this.photoPaths,
    required this.takenAt,
    required this.utcOffset,
    required this.location,
  });

  final List<String> photoPaths;

  /// Local wall-clock time of the earliest photo.
  final DateTime takenAt;

  /// Offset recorded with [takenAt]; `null` means the device's offset.
  final Duration? utcOffset;
  final GeoPoint? location;
}

/// Groups shared photos into suggested entries.
List<PhotoGroup> groupSharedPhotos(
  List<SharedPhoto> photos, {
  required DateTime now,
}) => throw UnimplementedError();

/// The entry for [group] with the imported [photoPaths].
Entry entryFromGroup(
  PhotoGroup group, {
  required String id,
  required String tripId,
  required List<String> photoPaths,
  required Place? nearestPlace,
}) => throw UnimplementedError();
