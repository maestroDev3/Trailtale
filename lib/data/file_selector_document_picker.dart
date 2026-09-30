import 'dart:io';

import 'package:file_selector/file_selector.dart';

import '../domain/document_picker.dart';

/// Picks a backup ZIP with the system's document picker (also shows Google
/// Drive), no storage permission needed.
class FileSelectorDocumentPicker implements DocumentPicker {
  static const _zip = XTypeGroup(
    label: 'ZIP',
    extensions: ['zip'],
    mimeTypes: ['application/zip', 'application/x-zip-compressed'],
  );

  @override
  Future<File?> pickBackup() async {
    final file = await openFile(acceptedTypeGroups: const [_zip]);
    return file == null ? null : File(file.path);
  }
}
