import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import '../domain/geo_point.dart';
import '../domain/place.dart';

/// Reads the bundled, gzipped city list (`assets/places/cities.tsv.gz`):
/// name, country, country code, latitude, longitude, population, alternate
/// names separated by `|`, region (optional eighth field). The index is built
/// in a background isolate so the UI stays smooth.
class AssetPlaceDirectory implements PlaceDirectory {
  AssetPlaceDirectory({required this.loadBytes});

  /// Loads the raw gzipped bytes (e.g. from the asset bundle).
  final Future<List<int>> Function() loadBytes;

  Future<PlaceIndex>? _index;

  @override
  Future<PlaceIndex> load() => _index ??= _read();

  Future<PlaceIndex> _read() async {
    final bytes = await loadBytes();
    return Isolate.run(() => _buildIndex(bytes));
  }

  static PlaceIndex _buildIndex(List<int> bytes) {
    final text = utf8.decode(gzip.decode(bytes));
    // Countries and regions repeat a lot; share one string each.
    final shared = <String, String>{};
    String intern(String value) => shared.putIfAbsent(value, () => value);
    return PlaceIndex([
      for (final line in const LineSplitter().convert(text))
        if (line.isNotEmpty) _parse(line, intern),
    ]);
  }

  static Place _parse(String line, String Function(String) intern) {
    final fields = line.split('\t');
    final alternates = fields.length > 6 ? fields[6] : '';
    final region = fields.length > 7 ? fields[7] : '';
    return Place(
      name: fields[0],
      country: intern(fields[1]),
      countryCode: intern(fields[2]),
      region: region.isEmpty ? null : intern(region),
      location: GeoPoint(
        latitude: double.parse(fields[3]),
        longitude: double.parse(fields[4]),
      ),
      population: int.parse(fields[5]),
      alternateNames: alternates.isEmpty ? const [] : alternates.split('|'),
    );
  }
}
