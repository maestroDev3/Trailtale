import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:trailtale/data/exif_photo_metadata_reader.dart';
import 'package:trailtale/domain/photo_metadata.dart';

void main() {
  final reader = ExifPhotoMetadataReader();

  Future<PhotoMetadata> read(String name) =>
      reader.read(File('test/fixtures/$name'));

  group('ExifPhotoMetadataReader', () {
    test('reads capture time, offset and position', () async {
      final metadata = await read('photo_with_gps.jpg');

      expect(metadata.takenAt, DateTime(2026, 5, 2, 9, 15, 30));
      expect(metadata.utcOffset, const Duration(hours: 1));
      expect(metadata.location?.latitude, closeTo(38.7128, 0.0001));
      expect(metadata.location?.longitude, closeTo(-9.136, 0.0001));
    });

    test('reads southern latitudes and eastern longitudes', () async {
      final metadata = await read('photo_southern_east.jpg');

      expect(metadata.utcOffset, const Duration(hours: 11));
      expect(metadata.location?.latitude, closeTo(-33.8568, 0.0001));
      expect(metadata.location?.longitude, closeTo(151.2153, 0.0001));
    });

    test('reads the capture time without offset and position', () async {
      final metadata = await read('photo_date_only.jpg');

      expect(metadata.takenAt, DateTime(2025, 10, 24, 18, 5));
      expect(metadata.utcOffset, isNull);
      expect(metadata.location, isNull);
    });

    test('ignores an invalid capture time', () async {
      final metadata = await read('photo_invalid_date.jpg');

      expect(metadata.takenAt, isNull);
    });

    test('returns empty metadata for a photo without EXIF', () async {
      expect(await read('photo_no_exif.jpg'), const PhotoMetadata());
    });

    test('returns empty metadata for a file that is not an image', () async {
      expect(await read('not_an_image.jpg'), const PhotoMetadata());
    });

    test('returns empty metadata for a missing file', () async {
      expect(await read('does_not_exist.jpg'), const PhotoMetadata());
    });
  });

  group('parseExifOffset', () {
    test('parses positive, negative and half-hour offsets', () {
      expect(parseExifOffset('+01:00'), const Duration(hours: 1));
      expect(
        parseExifOffset('-03:30'),
        const Duration(hours: -3, minutes: -30),
      );
      expect(parseExifOffset('+05:45'), const Duration(hours: 5, minutes: 45));
    });

    test('rejects malformed offsets', () {
      expect(parseExifOffset(''), isNull);
      expect(parseExifOffset('01:00'), isNull);
      expect(parseExifOffset('+25:00'), isNull);
    });
  });
}
