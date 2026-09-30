import 'dart:io';

import '../domain/id_generator.dart';
import '../domain/photo_library.dart';

/// Stores photos as files in `<documents>/photos/<id>.<extension>`.
class FilePhotoLibrary implements PhotoLibrary {
  FilePhotoLibrary({required this.documents, required this.newId});

  static const folder = 'photos';

  final Directory documents;
  final IdGenerator newId;

  @override
  Future<String> importPhoto(String sourcePath) async {
    final relativePath = '$folder/${newId()}.${_extensionOf(sourcePath)}';
    final target = fileFor(relativePath);
    await target.parent.create(recursive: true);
    await File(sourcePath).copy(target.path);
    return relativePath;
  }

  @override
  File fileFor(String relativePath) {
    final segments = relativePath.split('/');
    if (relativePath.startsWith('/') || segments.contains('..')) {
      throw ArgumentError.value(
        relativePath,
        'relativePath',
        'must stay inside the documents directory',
      );
    }
    return File('${documents.path}/$relativePath');
  }

  @override
  Future<void> deletePhotos(Iterable<String> relativePaths) async {
    for (final path in relativePaths) {
      final file = fileFor(path);
      if (await file.exists()) await file.delete();
    }
  }
}

/// Lower-case extension of the file name in [path], `jpg` if it has none.
String _extensionOf(String path) {
  final name = path.split(Platform.pathSeparator).last.split('/').last;
  final dot = name.lastIndexOf('.');
  if (dot <= 0 || dot == name.length - 1) return 'jpg';
  return name.substring(dot + 1).toLowerCase();
}
