import 'dart:io';

import 'package:trailtale/domain/photo_library.dart';

/// In-memory [PhotoLibrary] for widget tests that records what happened.
class FakePhotoLibrary implements PhotoLibrary {
  var _counter = 0;

  /// Relative paths returned by [importPhoto], in order.
  final imported = <String>[];

  /// Relative paths passed to [deletePhotos], in order.
  final deleted = <String>[];

  @override
  Future<String> importPhoto(String sourcePath) async {
    final path = 'photos/imported${++_counter}.jpg';
    imported.add(path);
    return path;
  }

  @override
  File fileFor(String relativePath) =>
      File('/nonexistent/trailtale/$relativePath');

  @override
  Future<void> deletePhotos(Iterable<String> relativePaths) async {
    deleted.addAll(relativePaths);
  }
}
