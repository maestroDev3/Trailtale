import 'package:flutter_test/flutter_test.dart';
import 'package:trailtale/data/share_plus_file_sharer.dart';

void main() {
  group('mimeTypeFor', () {
    test('is image/png for PNG files', () {
      expect(mimeTypeFor('/tmp/shared/Montenegro.png'), 'image/png');
      expect(mimeTypeFor('/tmp/shared/TRIP.PNG'), 'image/png');
    });

    test('is unknown for other files', () {
      expect(mimeTypeFor('/tmp/backup.zip'), isNull);
    });
  });
}
