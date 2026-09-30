import 'dart:io';

import 'package:share_plus/share_plus.dart';

import '../domain/file_sharer.dart';

/// Opens the Android share sheet with a file.
class SharePlusFileSharer implements FileSharer {
  @override
  Future<void> shareFile(File file, {required String subject}) async {
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], subject: subject),
    );
  }
}
