import 'package:trailtale/domain/place.dart';

/// [PlaceDirectory] for widget tests with a few known places.
class FakePlaceDirectory implements PlaceDirectory {
  FakePlaceDirectory([List<Place>? places]) : places = places ?? const [];

  final List<Place> places;

  @override
  Future<PlaceIndex> load() async => PlaceIndex(places);
}
