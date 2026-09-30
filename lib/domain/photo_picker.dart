/// Lets the user choose images, e.g. from the gallery.
abstract interface class PhotoPicker {
  /// Returns the file paths of the chosen images; empty when cancelled.
  Future<List<String>> pickImages();
}
