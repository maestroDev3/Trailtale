import 'dart:typed_data';

import 'trip.dart';

/// How much of the device's photo gallery the user lets Trailtale see.
enum GalleryAccess {
  /// All photos.
  full,

  /// Only the photos the user selected (Android 14 and later).
  limited,

  /// No photos; the system photo picker is the fallback.
  denied,
}

/// A photo in the device's gallery, identified by the gallery's own [id].
class GalleryPhoto {
  const GalleryPhoto({required this.id, required this.takenAt});

  final String id;

  /// Local wall-clock time the photo was taken.
  final DateTime takenAt;
}

/// The device's photo gallery. Unlike the system photo picker it hands out
/// the original files, so their GPS position survives.
abstract interface class PhotoGallery {
  /// Asks the user for access if needed and returns what was granted.
  Future<GalleryAccess> requestAccess();

  /// Returns one page of photos taken at or after [from] and before [until],
  /// newest first.
  Future<List<GalleryPhoto>> photos({
    DateTime? from,
    DateTime? until,
    required int page,
    required int pageSize,
  });

  /// Returns a small preview image, or `null` if none is available.
  Future<Uint8List?> thumbnail(String id);

  /// Returns the path of the photo's original file with all metadata
  /// (including its location), or `null` if it is unavailable.
  Future<String?> originalFile(String id);

  /// Lets the user change which photos are visible with limited access.
  Future<void> selectMorePhotos();

  /// Saves a PNG picture to the gallery; returns whether it worked.
  Future<bool> saveImage(Uint8List bytes, {required String title});
}

/// The time span whose photos belong to [trip]: from the start of its first
/// day until the start of the day after its last day, in local time.
({DateTime from, DateTime until}) tripPhotoPeriod(Trip trip) {
  final start = trip.startDate;
  final end = trip.endDate;
  return (
    from: DateTime(start.year, start.month, start.day),
    until: DateTime(end.year, end.month, end.day + 1),
  );
}
