import 'package:flutter_test/flutter_test.dart';
import 'package:trailtale/domain/file_names.dart';

void main() {
  group('safeFileName', () {
    test('replaces unsafe characters', () {
      expect(safeFileName('Lisbon & Porto.png'), 'Lisbon---Porto.png');
      expect(safeFileName('a/b:c.png'), 'a-b-c.png');
    });

    test('names a file without letters "file"', () {
      expect(safeFileName('.png'), 'file.png');
      expect(safeFileName(''), 'file');
    });
  });
}
