import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:trailtale/domain/photo_gallery.dart';

import '../support/fake_photo_gallery.dart';

void main() {
  GalleryPhoto photo(String id, DateTime takenAt) =>
      GalleryPhoto(id: id, takenAt: takenAt);

  group('FakePhotoGallery', () {
    final gallery = FakePhotoGallery(
      photos: [
        photo('a', DateTime(2026, 9, 25, 12)),
        photo('b', DateTime(2026, 9, 27, 9)),
        photo('c', DateTime(2026, 9, 28, 18)),
        photo('d', DateTime(2026, 9, 30, 8)),
      ],
    );

    test('returns photos newest first', () async {
      final photos = await gallery.photos(page: 0, pageSize: 10);

      expect([for (final p in photos) p.id], ['d', 'c', 'b', 'a']);
    });

    test('filters by period, including from and excluding until', () async {
      final photos = await gallery.photos(
        from: DateTime(2026, 9, 27, 9),
        until: DateTime(2026, 9, 30, 8),
        page: 0,
        pageSize: 10,
      );

      expect([for (final p in photos) p.id], ['c', 'b']);
    });

    test('pages through the photos', () async {
      final first = await gallery.photos(page: 0, pageSize: 3);
      final second = await gallery.photos(page: 1, pageSize: 3);
      final third = await gallery.photos(page: 2, pageSize: 3);

      expect([for (final p in first) p.id], ['d', 'c', 'b']);
      expect([for (final p in second) p.id], ['a']);
      expect(third, isEmpty);
    });

    test('hands out original files and counts access requests', () async {
      final gallery = FakePhotoGallery(
        photos: [photo('a', DateTime(2026, 9, 25))],
        access: GalleryAccess.limited,
      );

      expect(await gallery.requestAccess(), GalleryAccess.limited);
      expect(gallery.accessRequests, 1);
      expect(await gallery.originalFile('a'), '/gallery/a.jpg');
      expect(await gallery.originalFile('missing'), isNull);
    });

    test('records saved images with their title', () async {
      final gallery = FakePhotoGallery();

      final saved = await gallery.saveImage(
        Uint8List.fromList([1, 2]),
        title: 'Montenegro',
      );

      expect(saved, isTrue);
      expect(gallery.savedImages.single.title, 'Montenegro');
      expect(gallery.savedImages.single.bytes, [1, 2]);
    });
  });
}
