import '../domain/slideshow_document.dart';

/// Decodes photos with Flutter's image codec (JPEG, HEIC, PNG …) at a
/// reduced size and encodes them as JPEG (package `image`).
class CodecPhotoShrinker implements PhotoShrinker {
  @override
  Future<List<int>?> shrink(String path, {required int maxSide}) =>
      throw UnimplementedError();
}
