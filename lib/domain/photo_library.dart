import 'dart:io';

/// Keeps the app's own copies of photos, so entries do not break when the
/// user deletes or moves a photo in the gallery.
///
/// Entries only store the relative paths this library returns.
abstract interface class PhotoLibrary {
  /// Copies the image at [sourcePath] into the library and returns its
  /// relative path.
  Future<String> importPhoto(String sourcePath);

  /// The file behind a relative path returned by [importPhoto].
  File fileFor(String relativePath);

  /// Deletes the given photos; paths whose files are gone are ignored.
  Future<void> deletePhotos(Iterable<String> relativePaths);
}
