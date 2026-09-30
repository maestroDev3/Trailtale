import 'dart:io';

/// Lets the user choose a backup file, e.g. from Google Drive or Downloads.
abstract interface class DocumentPicker {
  /// Returns the chosen backup file, or `null` if the user cancelled.
  Future<File?> pickBackup();
}
