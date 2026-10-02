import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:trailtale/data/directory_temporary_files.dart';

void main() {
  late Directory directory;

  setUp(
    () => directory = Directory.systemTemp.createTempSync('trailtale_tmp_'),
  );
  tearDown(() => directory.deleteSync(recursive: true));

  group('DirectoryTemporaryFiles', () {
    test('writes the bytes into its directory', () async {
      final files = DirectoryTemporaryFiles(directory);

      final file = await files.write('Montenegro.png', [1, 2, 3]);

      expect(file.parent.path, directory.path);
      expect(file.readAsBytesSync(), [1, 2, 3]);
    });

    test('replaces an existing file', () async {
      final files = DirectoryTemporaryFiles(directory);
      await files.write('trip.png', [1, 2, 3]);

      final file = await files.write('trip.png', [9]);

      expect(file.readAsBytesSync(), [9]);
    });

    test('keeps only safe characters in the file name', () async {
      final files = DirectoryTemporaryFiles(directory);

      final file = await files.write('Lisbon & Porto.png', [1]);

      expect(file.uri.pathSegments.last, 'Lisbon---Porto.png');
    });
  });
}
