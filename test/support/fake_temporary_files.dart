import 'dart:io';

import 'package:trailtale/domain/temporary_files.dart';

/// [TemporaryFiles] for tests that keeps the bytes in memory.
class FakeTemporaryFiles implements TemporaryFiles {
  /// Written bytes by file name.
  final written = <String, List<int>>{};

  @override
  Future<File> write(String name, List<int> bytes) =>
      throw UnimplementedError();
}
