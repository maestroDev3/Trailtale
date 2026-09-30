import 'dart:io';

import 'package:exif/exif.dart';

import '../domain/geo_point.dart';
import '../domain/photo_metadata.dart';

/// Reads capture time and GPS position from the EXIF data of JPEG and HEIC
/// files (package `exif`, pure Dart).
class ExifPhotoMetadataReader implements PhotoMetadataReader {
  @override
  Future<PhotoMetadata> read(File file) async {
    final Map<String, IfdTag> tags;
    try {
      tags = await readExifFromBytes(await file.readAsBytes());
    } on FileSystemException {
      return const PhotoMetadata();
    }
    if (tags.isEmpty) return const PhotoMetadata();
    final takenAt = _parseDateTime(tags['EXIF DateTimeOriginal']?.printable);
    return PhotoMetadata(
      takenAt: takenAt,
      utcOffset: takenAt == null
          ? null
          : parseExifOffset(tags['EXIF OffsetTimeOriginal']?.printable ?? ''),
      location: _location(tags),
    );
  }
}

/// Parses an EXIF offset such as `+01:00` or `-03:30`; `null` if malformed.
Duration? parseExifOffset(String text) {
  final match = RegExp(r'^([+-])(\d{2}):(\d{2})$').firstMatch(text.trim());
  if (match == null) return null;
  final hours = int.parse(match.group(2) ?? '');
  final minutes = int.parse(match.group(3) ?? '');
  if (hours > 14 || minutes > 59) return null;
  final offset = Duration(hours: hours, minutes: minutes);
  return match.group(1) == '-' ? -offset : offset;
}

/// Parses `yyyy:MM:dd HH:mm:ss` as local wall-clock time.
DateTime? _parseDateTime(String? text) {
  final match = RegExp(
    r'^(\d{4}):(\d{2}):(\d{2}) (\d{2}):(\d{2}):(\d{2})',
  ).firstMatch(text?.trim() ?? '');
  if (match == null) return null;
  final [year, month, day, hour, minute, second] = [
    for (var group = 1; group <= 6; group++) int.parse(match.group(group) ?? ''),
  ];
  if (year < 1900 || month < 1 || month > 12 || day < 1 || day > 31) {
    return null;
  }
  if (hour > 23 || minute > 59 || second > 59) return null;
  return DateTime(year, month, day, hour, minute, second);
}

GeoPoint? _location(Map<String, IfdTag> tags) {
  final latitude = _degrees(
    tags['GPS GPSLatitude'],
    tags['GPS GPSLatitudeRef'],
    negative: 'S',
  );
  final longitude = _degrees(
    tags['GPS GPSLongitude'],
    tags['GPS GPSLongitudeRef'],
    negative: 'W',
  );
  if (latitude == null || longitude == null) return null;
  if (latitude.abs() > 90 || longitude.abs() > 180) return null;
  return GeoPoint(latitude: latitude, longitude: longitude);
}

/// Converts degrees/minutes/seconds ratios to signed decimal degrees.
double? _degrees(IfdTag? value, IfdTag? reference, {required String negative}) {
  final values = value?.values;
  if (values is! IfdRatios || values.ratios.length != 3) return null;
  final [degrees, minutes, seconds] = [
    for (final ratio in values.ratios)
      ratio.denominator == 0 ? double.nan : ratio.toDouble(),
  ];
  final decimal = degrees + minutes / 60 + seconds / 3600;
  if (!decimal.isFinite) return null;
  return reference?.printable.trim().toUpperCase() == negative
      ? -decimal
      : decimal;
}
