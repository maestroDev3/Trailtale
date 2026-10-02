import 'package:flutter_test/flutter_test.dart';

import '../support/fake_temporary_files.dart';

void main() {
  group('FakeTemporaryFiles', () {
    test('records written files', () async {
      final files = FakeTemporaryFiles();

      final file = await files.write('trip.png', [1, 2, 3]);

      expect(file.path, endsWith('trip.png'));
      expect(files.written['trip.png'], [1, 2, 3]);
    });
  });
}
