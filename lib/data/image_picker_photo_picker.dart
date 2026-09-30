import 'package:image_picker/image_picker.dart';

import '../domain/photo_picker.dart';

/// Picks images with the Android system photo picker, which needs no storage
/// or media permission.
class ImagePickerPhotoPicker implements PhotoPicker {
  ImagePickerPhotoPicker([ImagePicker? picker])
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<List<String>> pickImages() async {
    final files = await _picker.pickMultiImage(requestFullMetadata: true);
    return [for (final file in files) file.path];
  }
}
