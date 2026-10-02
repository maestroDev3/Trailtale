import 'dart:io';

/// Short-lived files, e.g. a picture handed to the share sheet.
abstract interface class TemporaryFiles {
  /// Writes [bytes] to a temporary file called [name] (made safe for file
  /// systems) and returns it; an existing file of that name is replaced.
  Future<File> write(String name, List<int> bytes);
}
