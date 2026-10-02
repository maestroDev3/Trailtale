import 'dart:io';

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

/// Keeps letters, digits, `-` and `_` in the name and its extension; every
/// other character becomes `-`.
String safeFileName(String name) {
  final dot = name.lastIndexOf('.');
  final (base, extension) = dot <= 0
      ? (name, '')
      : (name.substring(0, dot), name.substring(dot + 1));
  String clean(String text) => text.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '-');
  final cleanBase = clean(base);
  final safeBase = cleanBase.isEmpty ? 'file' : cleanBase;
  return extension.isEmpty ? safeBase : '$safeBase.${clean(extension)}';
}
