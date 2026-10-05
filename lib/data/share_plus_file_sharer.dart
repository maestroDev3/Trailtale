import 'dart:io';

import 'package:share_plus/share_plus.dart';

import '../domain/file_sharer.dart';

/// Opens the Android share sheet with a file.
class SharePlusFileSharer implements FileSharer {
  @override
  Future<void> shareFile(File file, {required String subject}) =>
      shareFiles([file], subject: subject);

  @override
  Future<void> shareFiles(List<File> files, {required String subject}) async {
    await SharePlus.instance.share(
      ShareParams(
        files: [
          for (final file in files)
            XFile(file.path, mimeType: mimeTypeFor(file.path)),
        ],
        subject: subject,
      ),
    );
  }
}

/// The MIME type share targets (e.g. Instagram) need to accept a file.
String? mimeTypeFor(String path) =>
    path.toLowerCase().endsWith('.png') ? 'image/png' : null;
