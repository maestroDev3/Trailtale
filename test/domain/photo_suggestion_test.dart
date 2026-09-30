import 'package:flutter_test/flutter_test.dart';
import 'package:trailtale/domain/geo_point.dart';
import 'package:trailtale/domain/photo_metadata.dart';
import 'package:trailtale/domain/photo_suggestion.dart';

void main() {
  final belem = GeoPoint(latitude: 38.6916, longitude: -9.216);
  final alfama = GeoPoint(latitude: 38.7117, longitude: -9.13);

  group('suggestFromPhotos', () {
    test('suggests nothing without photos', () {
      final suggestion = suggestFromPhotos(const []);

      expect(suggestion.takenAt, isNull);
      expect(suggestion.utcOffset, isNull);
      expect(suggestion.location, isNull);
      expect(suggestion.isEmpty, isTrue);
    });

    test('suggests nothing for photos without metadata', () {
      final suggestion = suggestFromPhotos(const [
        PhotoMetadata(),
        PhotoMetadata(),
      ]);

      expect(suggestion.isEmpty, isTrue);
    });

    test('suggests the earliest capture time with its offset', () {
      final suggestion = suggestFromPhotos([
        PhotoMetadata(
          takenAt: DateTime(2026, 5, 2, 12),
          utcOffset: const Duration(hours: 2),
        ),
        PhotoMetadata(
          takenAt: DateTime(2026, 5, 2, 9, 15),
          utcOffset: const Duration(hours: 1),
        ),
        const PhotoMetadata(),
      ]);

      expect(suggestion.takenAt, DateTime(2026, 5, 2, 9, 15));
      expect(suggestion.utcOffset, const Duration(hours: 1));
      expect(suggestion.isEmpty, isFalse);
    });

    test('suggests the location of the earliest photo that has one', () {
      final suggestion = suggestFromPhotos([
        PhotoMetadata(takenAt: DateTime(2026, 5, 2, 15), location: alfama),
        PhotoMetadata(takenAt: DateTime(2026, 5, 2, 8)),
        PhotoMetadata(takenAt: DateTime(2026, 5, 2, 10), location: belem),
      ]);

      expect(suggestion.takenAt, DateTime(2026, 5, 2, 8));
      expect(suggestion.location, belem);
    });

    test('uses a location from a photo without capture time', () {
      final suggestion = suggestFromPhotos([PhotoMetadata(location: belem)]);

      expect(suggestion.takenAt, isNull);
      expect(suggestion.location, belem);
    });
  });
}
