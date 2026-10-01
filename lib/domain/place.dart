import 'geo_point.dart';

/// A city from the bundled place list.
class Place {
  const Place({
    required this.name,
    required this.country,
    required this.countryCode,
    required this.location,
    required this.population,
    this.alternateNames = const [],
  });

  final String name;
  final String country;
  final String countryCode;
  final GeoPoint location;
  final int population;

  /// Other spellings and names in other languages, e.g. “Lissabon”.
  final List<String> alternateNames;

  /// Name with country, as shown in suggestions: “Lisbon, Portugal”.
  String get label => '$name, $country';

  @override
  bool operator ==(Object other) =>
      other is Place &&
      other.name == name &&
      other.countryCode == countryCode &&
      other.location == location;

  @override
  int get hashCode => Object.hash(name, countryCode, location);

  @override
  String toString() => 'Place($label)';
}

/// Searches places by name and finds the nearest place to a position; built
/// once from the whole list.
class PlaceIndex {
  PlaceIndex(Iterable<Place> places)
    : _entries = [
        for (final place in places)
          _IndexedPlace(place, foldText(place.name), [
            for (final name in place.alternateNames) foldText(name),
          ]),
      ];

  /// Radius within which [nearest] accepts a place.
  static const nearestRadiusMeters = 30000.0;

  final List<_IndexedPlace> _entries;

  /// Places whose name, a word of it or an alternate name starts with
  /// [query] (case and accents ignored): exact names first, then the most
  /// populous. Needs at least two characters.
  List<Place> search(String query, {int limit = 8}) {
    final folded = foldText(query.trim());
    if (folded.length < 2) return const [];
    final matches = <(int, Place)>[];
    for (final entry in _entries) {
      final rank = entry.rank(folded);
      if (rank != null) matches.add((rank, entry.place));
    }
    matches.sort((a, b) {
      final byRank = a.$1.compareTo(b.$1);
      return byRank != 0 ? byRank : b.$2.population.compareTo(a.$2.population);
    });
    return [for (final (_, place) in matches.take(limit)) place];
  }

  /// The place closest to [point] within [nearestRadiusMeters], or `null`.
  Place? nearest(GeoPoint point) {
    Place? best;
    var bestDistance = nearestRadiusMeters;
    for (final entry in _entries) {
      final distance = entry.place.location.distanceTo(point);
      if (distance <= bestDistance) {
        best = entry.place;
        bestDistance = distance;
      }
    }
    return best;
  }
}

class _IndexedPlace {
  _IndexedPlace(this.place, this.name, this.alternates);

  final Place place;
  final String name;
  final List<String> alternates;

  /// 0 exact name, 1 exact alternate, 2 name prefix, 3 other match.
  int? rank(String query) {
    if (name == query) return 0;
    if (alternates.contains(query)) return 1;
    if (name.startsWith(query)) return 2;
    if (_wordStarts(name, query) ||
        alternates.any(
          (alternate) =>
              alternate.startsWith(query) || _wordStarts(alternate, query),
        )) {
      return 3;
    }
    return null;
  }

  static bool _wordStarts(String text, String query) =>
      text.split(RegExp(r'[\s\-]+')).any((word) => word.startsWith(query));
}

const _accents = {
  'à': 'a', 'á': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a', 'å': 'a', 'ā': 'a', //
  'ă': 'a', 'ą': 'a', 'æ': 'ae', 'ç': 'c', 'ć': 'c', 'č': 'c', 'ď': 'd', //
  'đ': 'd', 'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e', 'ē': 'e', 'ė': 'e', //
  'ę': 'e', 'ě': 'e', 'ğ': 'g', 'ì': 'i', 'í': 'i', 'î': 'i', 'ï': 'i', //
  'ī': 'i', 'ı': 'i', 'ł': 'l', 'ľ': 'l', 'ñ': 'n', 'ń': 'n', 'ň': 'n', //
  'ò': 'o', 'ó': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o', 'ø': 'o', 'ō': 'o', //
  'ő': 'o', 'œ': 'oe', 'ř': 'r', 'ś': 's', 'š': 's', 'ş': 's', 'ș': 's', //
  'ß': 'ss', 'ť': 't', 'ţ': 't', 'ț': 't', 'ù': 'u', 'ú': 'u', 'û': 'u', //
  'ü': 'u', 'ū': 'u', 'ů': 'u', 'ű': 'u', 'ų': 'u', 'ý': 'y', 'ÿ': 'y', //
  'ź': 'z', 'ż': 'z', 'ž': 'z',
};

/// Lower case without accents, so “São” matches “sao”.
String foldText(String text) {
  final buffer = StringBuffer();
  for (final char in text.toLowerCase().split('')) {
    buffer.write(_accents[char] ?? char);
  }
  return buffer.toString();
}

/// Source of the place list, e.g. the bundled asset.
abstract interface class PlaceDirectory {
  /// Loads the places once and returns the index.
  Future<PlaceIndex> load();
}
