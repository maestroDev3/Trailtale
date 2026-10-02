import 'dart:typed_data';

import 'package:trailtale/domain/photo_gallery.dart';

/// [PhotoGallery] for tests with an in-memory list of [GalleryPhoto]s.
class FakePhotoGallery implements PhotoGallery {
  FakePhotoGallery({
    List<GalleryPhoto> photos = const [],
    this.access = GalleryAccess.full,
    this.missingOriginals = const {},
  }) : stored = [...photos];

  /// Ids whose original file is unavailable (e.g. only in the cloud).
  final Set<String> missingOriginals;

  /// The photos in the gallery, in any order.
  final List<GalleryPhoto> stored;

  /// What [requestAccess] answers.
  GalleryAccess access;

  /// How often access was requested.
  var accessRequests = 0;

  /// How often [selectMorePhotos] was called.
  var selectMoreCount = 0;

  @override
  Future<GalleryAccess> requestAccess() async {
    accessRequests++;
    return access;
  }

  @override
  Future<List<GalleryPhoto>> photos({
    DateTime? from,
    DateTime? until,
    required int page,
    required int pageSize,
  }) async {
    final matching = [
      for (final photo in stored)
        if ((from == null || !photo.takenAt.isBefore(from)) &&
            (until == null || photo.takenAt.isBefore(until)))
          photo,
    ]..sort((a, b) => b.takenAt.compareTo(a.takenAt));
    return matching.skip(page * pageSize).take(pageSize).toList();
  }

  @override
  Future<Uint8List?> thumbnail(String id) async => null;

  @override
  Future<String?> originalFile(String id) async =>
      stored.any((photo) => photo.id == id) && !missingOriginals.contains(id)
      ? '/gallery/$id.jpg'
      : null;

  @override
  Future<void> selectMorePhotos() async => selectMoreCount++;

  @override
  Future<bool> saveImage(Uint8List bytes, {required String title}) =>
      throw UnimplementedError();
}
