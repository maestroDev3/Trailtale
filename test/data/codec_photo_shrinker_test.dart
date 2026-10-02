import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:trailtale/data/codec_photo_shrinker.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;

  setUp(() => directory = Directory.systemTemp.createTempSync('shrink_'));
  tearDown(() => directory.deleteSync(recursive: true));

  group('CodecPhotoShrinker', () {
    testWidgets('returns a JPEG of at most the given side, same aspect', (
      tester,
    ) async {
      final file = File('${directory.path}/wide.png')
        ..writeAsBytesSync(img.encodePng(img.Image(width: 400, height: 200)));

      final jpeg = await tester.runAsync(
        () => CodecPhotoShrinker().shrink(file.path, maxSide: 100),
      );

      final decoded = img.decodeJpg(Uint8List.fromList(jpeg ?? const []));
      expect(decoded?.width, 100);
      expect(decoded?.height, 50);
    });

    testWidgets('keeps a small photo at its size', (tester) async {
      final file = File('${directory.path}/small.png')
        ..writeAsBytesSync(img.encodePng(img.Image(width: 40, height: 30)));

      final jpeg = await tester.runAsync(
        () => CodecPhotoShrinker().shrink(file.path, maxSide: 100),
      );

      final decoded = img.decodeJpg(Uint8List.fromList(jpeg ?? const []));
      expect(decoded?.width, 40);
      expect(decoded?.height, 30);
    });

    testWidgets('returns null for a file that is not an image', (tester) async {
      final file = File('${directory.path}/note.txt')
        ..writeAsStringSync('hello');

      final jpeg = await tester.runAsync(
        () => CodecPhotoShrinker().shrink(file.path, maxSide: 100),
      );

      expect(jpeg, isNull);
    });
  });
}
