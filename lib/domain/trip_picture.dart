import 'entry.dart';
import 'geo_point.dart';
import 'trip.dart';

/// A place of the trip, in visiting order.
class TripStop {
  const TripStop({required this.name, this.location});

  final String name;

  /// Location of the first located entry with this name, if any.
  final GeoPoint? location;
}

/// What a shareable picture of a trip shows.
class TripPicture {
  const TripPicture({
    required this.title,
    required this.startDate,
    required this.endDate,
    required this.dayCount,
    required this.stops,
    required this.distanceMeters,
    required this.photoPaths,
  });

  final String title;
  final DateTime startDate;
  final DateTime endDate;
  final int dayCount;
  final List<TripStop> stops;
  final double distanceMeters;

  /// Most photos a picture shows.
  static const maxPhotos = 4;

  /// Relative photo paths, at most [maxPhotos].
  final List<String> photoPaths;

  int get placeCount => stops.length;
}

/// Builds the content of a trip picture: stops are the place names in
/// visiting order (case and surrounding spaces ignored); with
/// [leaveOutEnds] the first and last stop and their entries are left out,
/// e.g. to keep one's home private.
TripPicture buildTripPicture(
  Trip trip,
  List<Entry> entries, {
  required bool leaveOutEnds,
  List<String> chosenPhotos = const [],
}) {
  String key(String name) => name.trim().toLowerCase();
  final chronological = sortEntriesChronologically(entries);
  final names = <String, String>{};
  final locations = <String, GeoPoint>{};
  for (final entry in chronological) {
    if (entry.placeName case final name?) {
      final placeKey = key(name);
      names.putIfAbsent(placeKey, () => name);
      if (entry.location case final location?) {
        locations.putIfAbsent(placeKey, () => location);
      }
    }
  }
  var keys = names.keys.toList();
  final leftOut = <String>{};
  if (leaveOutEnds && keys.isNotEmpty) {
    leftOut.addAll({keys.first, keys.last});
    keys = keys.length <= 2 ? [] : keys.sublist(1, keys.length - 1);
  }
  final stops = [
    for (final placeKey in keys)
      TripStop(name: names[placeKey] ?? '', location: locations[placeKey]),
  ];
  final located = [for (final stop in stops) ?stop.location];
  var distance = 0.0;
  for (var i = 1; i < located.length; i++) {
    distance += located[i - 1].distanceTo(located[i]);
  }
  final shown = [
    for (final entry in chronological)
      if (entry.placeName == null ||
          !leftOut.contains(key(entry.placeName ?? '')))
        entry,
  ];
  return TripPicture(
    title: trip.title,
    startDate: trip.startDate,
    endDate: trip.endDate,
    dayCount: trip.dayCount,
    stops: stops,
    distanceMeters: distance,
    photoPaths: _pickPhotos(shown),
  );
}

/// The first photo of different days (spread evenly over the trip), then
/// further photos in time order, at most [TripPicture.maxPhotos].
List<String> _pickPhotos(List<Entry> chronological) {
  const limit = TripPicture.maxPhotos;
  final byDay = <DateTime, List<String>>{};
  for (final entry in chronological) {
    if (entry.photoPaths.isEmpty) continue;
    byDay.putIfAbsent(entry.localDay, () => []).addAll(entry.photoPaths);
  }
  final days = byDay.values.toList();
  final firstOfDays = [for (final photos in days) photos.first];
  final picked = <String>[];
  if (firstOfDays.length > limit) {
    for (var i = 0; i < limit; i++) {
      picked.add(
        firstOfDays[(i * (firstOfDays.length - 1) / (limit - 1)).round()],
      );
    }
    return picked;
  }
  picked.addAll(firstOfDays);
  for (final photos in days) {
    for (final photo in photos.skip(1)) {
      if (picked.length == limit) return picked;
      picked.add(photo);
    }
  }
  return picked;
}
