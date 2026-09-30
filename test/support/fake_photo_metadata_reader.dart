import 'dart:io';

import 'package:trailtale/domain/photo_metadata.dart';

/// [PhotoMetadataReader] for widget tests: returns the metadata registered
/// for a file name, empty metadata otherwise.
class FakePhotoMetadataReader implements PhotoMetadataReader {
  FakePhotoMetadataReader([this.byFileName = const {}]);

  /// Metadata per file name (last path segment).
  final Map<String, PhotoMetadata> byFileName;

  @override
  Future<PhotoMetadata> read(File file) async =>
      byFileName[file.uri.pathSegments.last] ?? const PhotoMetadata();
}
