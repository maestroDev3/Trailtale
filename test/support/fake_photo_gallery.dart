import 'dart:typed_data';

import 'package:trailtale/domain/photo_gallery.dart';

/// [PhotoGallery] for tests with an in-memory list of [GalleryPhoto]s.
class FakePhotoGallery implements PhotoGallery {
  FakePhotoGallery({
    List<GalleryPhoto> photos = const [],
    this.access = GalleryAccess.full,
  }) : stored = [...photos];

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
    throw UnimplementedError();
  }

  @override
  Future<Uint8List?> thumbnail(String id) async => null;

  @override
  Future<String?> originalFile(String id) async => null;

  @override
  Future<void> selectMorePhotos() async => selectMoreCount++;
}
