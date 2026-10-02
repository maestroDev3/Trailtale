import 'dart:io';

import '../domain/file_names.dart';
import '../domain/temporary_files.dart';

/// [TemporaryFiles] in one directory, e.g. the app's temporary directory.
class DirectoryTemporaryFiles implements TemporaryFiles {
  DirectoryTemporaryFiles(this.directory);

  final Directory directory;

  @override
  Future<File> write(String name, List<int> bytes) async {
    await directory.create(recursive: true);
    final file = File('${directory.path}/${safeFileName(name)}');
    return file.writeAsBytes(bytes, flush: true);
  }
}
