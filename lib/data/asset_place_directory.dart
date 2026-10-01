import 'dart:convert';
import 'dart:io';

import '../domain/geo_point.dart';
import '../domain/place.dart';

/// Reads the bundled, gzipped city list (`assets/places/cities.tsv.gz`):
/// name, country, country code, latitude, longitude, population, alternate
/// names separated by `|`.
class AssetPlaceDirectory implements PlaceDirectory {
  AssetPlaceDirectory({required this.loadBytes});

  /// Loads the raw gzipped bytes (e.g. from the asset bundle).
  final Future<List<int>> Function() loadBytes;

  Future<PlaceIndex>? _index;

  @override
  Future<PlaceIndex> load() => _index ??= _read();

  Future<PlaceIndex> _read() async {
    final text = utf8.decode(gzip.decode(await loadBytes()));
    return PlaceIndex([
      for (final line in const LineSplitter().convert(text))
        if (line.isNotEmpty) _parse(line),
    ]);
  }

  static Place _parse(String line) {
    final fields = line.split('\t');
    final alternates = fields.length > 6 ? fields[6] : '';
    return Place(
      name: fields[0],
      country: fields[1],
      countryCode: fields[2],
      location: GeoPoint(
        latitude: double.parse(fields[3]),
        longitude: double.parse(fields[4]),
      ),
      population: int.parse(fields[5]),
      alternateNames: alternates.isEmpty ? const [] : alternates.split('|'),
    );
  }
}
