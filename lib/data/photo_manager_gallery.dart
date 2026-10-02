import 'dart:typed_data';

import 'package:photo_manager/photo_manager.dart';

import '../domain/photo_gallery.dart';

/// Reads the device's photos through Android's media store (package
/// `photo_manager`). Original files are requested with
/// `MediaStore.setRequireOriginal`, so their GPS position is kept when
/// `ACCESS_MEDIA_LOCATION` is granted.
class PhotoManagerGallery implements PhotoGallery {
  final _assets = <String, AssetEntity>{};

  /// Media store column with the capture time in milliseconds; falls back to
  /// the time the file was added (seconds) for photos without one.
  static const _takenAt = 'COALESCE(datetaken, date_added * 1000)';

  /// Upper bound for "no end", far after any real capture time.
  static const _farFuture = 8640000000000000;

  @override
  Future<GalleryAccess> requestAccess() async {
    final state = await PhotoManager.requestPermissionExtend(
      requestOption: const PermissionRequestOption(
        androidPermission: AndroidPermission(
          type: RequestType.image,
          mediaLocation: true,
        ),
      ),
    );
    return switch (state) {
      PermissionState.authorized => GalleryAccess.full,
      PermissionState.limited => GalleryAccess.limited,
      _ => GalleryAccess.denied,
    };
  }

  @override
  Future<List<GalleryPhoto>> photos({
    DateTime? from,
    DateTime? until,
    required int page,
    required int pageSize,
  }) async {
    final start = from?.millisecondsSinceEpoch ?? 0;
    final end = until?.millisecondsSinceEpoch ?? _farFuture;
    final assets = await PhotoManager.getAssetListPaged(
      page: page,
      pageCount: pageSize,
      type: RequestType.image,
      filterOption: CustomFilter.sql(
        where: '$_takenAt >= $start AND $_takenAt < $end',
        orderBy: [const OrderByItem.desc(_takenAt)],
      ),
    );
    for (final asset in assets) {
      _assets[asset.id] = asset;
    }
    return [
      for (final asset in assets)
        GalleryPhoto(id: asset.id, takenAt: asset.createDateTime),
    ];
  }

  /// Returns the media store entry for [id], cached after the first lookup.
  Future<AssetEntity?> _asset(String id) async {
    final cached = _assets[id];
    if (cached != null) return cached;
    final asset = await AssetEntity.fromId(id);
    if (asset != null) _assets[id] = asset;
    return asset;
  }

  @override
  Future<Uint8List?> thumbnail(String id) async =>
      (await _asset(id))
          ?.thumbnailDataWithSize(const ThumbnailSize.square(300));

  @override
  Future<String?> originalFile(String id) async =>
      (await (await _asset(id))?.originFile)?.path;

  @override
  Future<void> selectMorePhotos() =>
      PhotoManager.presentLimited(type: RequestType.image);

  @override
  Future<bool> saveImage(Uint8List bytes, {required String title}) =>
      throw UnimplementedError();
}
