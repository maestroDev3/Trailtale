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
    String? region,
  }) : region = region == '' ? null : region;

  final String name;
  final String country;
  final String countryCode;
  final GeoPoint location;
  final int population;

  /// Other spellings and names in other languages, e.g. “Lissabon”.
  final List<String> alternateNames;

  /// First administrative level, e.g. “Kotor Municipality”, if known.
  final String? region;

  /// Region and country, shown under the name in suggestions.
  String get detail => region == null ? country : '$region, $country';

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
/// once from the whole list (about 170,000 places, so built in the
/// background and kept lean: one folded search text per place).
class PlaceIndex {
  PlaceIndex(Iterable<Place> places)
    : _places = List.of(places, growable: false),
      _searchTexts = [
        for (final place in places)
          [
            '',
            foldText(place.name),
            for (final name in place.alternateNames) foldText(name),
          ].join(_separator),
      ];

  /// Radius within which [nearest] accepts a place.
  static const nearestRadiusMeters = 30000.0;

  /// Latitude difference beyond which a place is surely farther away than
  /// [nearestRadiusMeters] (one degree of latitude is about 111 km).
  static const _nearestLatitudeBand = nearestRadiusMeters / 111000 + 0.01;

  /// Separates the names in a search text; never part of a name.
  static const _separator = '\u0001';

  final List<Place> _places;

  /// Per place: the folded name, then the folded alternate names, each
  /// preceded by [_separator].
  final List<String> _searchTexts;

  /// Places whose name, a word of it or an alternate name starts with
  /// [query] (case and accents ignored): exact names first, then exact
  /// alternate names, then name prefixes, then other matches; within each
  /// group the most populous first. Needs at least two characters.
  List<Place> search(String query, {int limit = 8}) {
    final folded = foldText(query.trim());
    if (folded.length < 2) return const [];
    final namePrefix = '$_separator$folded';
    final exactName = '$namePrefix$_separator';
    final wordPrefixes = [' $folded', '-$folded'];
    final matches = <(int, Place)>[];
    for (var i = 0; i < _searchTexts.length; i++) {
      final text = _searchTexts[i];
      final int rank;
      if (text.startsWith(namePrefix)) {
        rank = text.startsWith(exactName) || text == namePrefix ? 0 : 2;
      } else if (text.contains(namePrefix)) {
        rank = text.contains(exactName) || text.endsWith(namePrefix) ? 1 : 3;
      } else if (text.contains(wordPrefixes[0]) ||
          text.contains(wordPrefixes[1])) {
        rank = 3;
      } else {
        continue;
      }
      matches.add((rank, _places[i]));
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
    for (final place in _places) {
      final location = place.location;
      if ((location.latitude - point.latitude).abs() > _nearestLatitudeBand) {
        continue;
      }
      final distance = location.distanceTo(point);
      if (distance <= bestDistance) {
        best = place;
        bestDistance = distance;
      }
    }
    return best;
  }
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
  final lower = text.toLowerCase();
  if (lower.codeUnits.every((unit) => unit < 128)) return lower;
  final buffer = StringBuffer();
  for (final char in lower.split('')) {
    buffer.write(_accents[char] ?? char);
  }
  return buffer.toString();
}

/// Source of the place list, e.g. the bundled asset.
abstract interface class PlaceDirectory {
  /// Loads the places once and returns the index.
  Future<PlaceIndex> load();
}
