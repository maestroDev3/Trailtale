import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:trailtale/data/file_photo_library.dart';

void main() {
  late Directory root;
  late Directory documents;
  late Directory gallery;
  late FilePhotoLibrary library;
  var counter = 0;

  setUp(() {
    root = Directory.systemTemp.createTempSync('trailtale_photos_');
    documents = Directory('${root.path}/documents')..createSync();
    gallery = Directory('${root.path}/gallery')..createSync();
    counter = 0;
    library = FilePhotoLibrary(
      documents: documents,
      newId: () => 'photo${++counter}',
    );
  });

  tearDown(() => root.deleteSync(recursive: true));

  File galleryImage(String name, List<int> bytes) =>
      File('${gallery.path}/$name')..writeAsBytesSync(bytes);

  group('FilePhotoLibrary.importPhoto', () {
    test('copies the image into the photos folder and returns its path', () async {
      final source = galleryImage('IMG_0001.JPG', [1, 2, 3]);

      final path = await library.importPhoto(source.path);

      expect(path, 'photos/photo1.jpg');
      expect(
        File('${documents.path}/photos/photo1.jpg').readAsBytesSync(),
        [1, 2, 3],
      );
      expect(source.existsSync(), isTrue);
    });

    test('keeps the extension in lower case', () async {
      final source = galleryImage('picture.HEIC', [4]);

      expect(await library.importPhoto(source.path), 'photos/photo1.heic');
    });

    test('uses .jpg for a source without extension', () async {
      final source = galleryImage('image', [5]);

      expect(await library.importPhoto(source.path), 'photos/photo1.jpg');
    });

    test('gives every imported photo its own file', () async {
      final source = galleryImage('a.png', [6]);

      final first = await library.importPhoto(source.path);
      final second = await library.importPhoto(source.path);

      expect(first, isNot(second));
    });
  });

  group('FilePhotoLibrary.fileFor', () {
    test('resolves a relative path inside the documents directory', () {
      expect(
        library.fileFor('photos/photo1.jpg').path,
        '${documents.path}/photos/photo1.jpg',
      );
    });

    test('rejects paths that leave the documents directory', () {
      expect(() => library.fileFor('../secret.jpg'), throwsArgumentError);
      expect(() => library.fileFor('photos/../../x.jpg'), throwsArgumentError);
      expect(() => library.fileFor('/etc/passwd'), throwsArgumentError);
    });
  });

  group('FilePhotoLibrary.deletePhotos', () {
    test('removes the files and ignores missing ones', () async {
      final path = await library.importPhoto(galleryImage('a.jpg', [7]).path);

      await library.deletePhotos([path, 'photos/missing.jpg']);

      expect(library.fileFor(path).existsSync(), isFalse);
    });
  });
}
