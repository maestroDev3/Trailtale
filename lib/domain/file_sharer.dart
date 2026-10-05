import 'dart:io';

/// Hands a file to other apps (e.g. Google Drive, mail) via the system's
/// share sheet.
abstract interface class FileSharer {
  Future<void> shareFile(File file, {required String subject});

  /// Shares [files] together, e.g. the pictures of an Instagram carousel.
  Future<void> shareFiles(List<File> files, {required String subject});
}
