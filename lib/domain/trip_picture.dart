import 'entry.dart';
import 'geo_point.dart';
import 'trip.dart';
import 'trip_day.dart';

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
/// e.g. to keep one's home private. [chosenPhotos] replace the automatic
/// photo pick (in their order, only photos of the trip, at most
/// [TripPicture.maxPhotos]; the automatic pick when none of them is left).
/// The distance counts the legs between the stops in visiting order, so a
/// way back to an earlier place is not counted.
TripPicture buildTripPicture(
  Trip trip,
  List<Entry> entries, {
  required bool leaveOutEnds,
  List<String> chosenPhotos = const [],
}) {
  final chronological = sortEntriesChronologically(entries);
  final names = <String, String>{};
  final locations = <String, GeoPoint>{};
  for (final entry in chronological) {
    if (entry.placeName case final name?) {
      final placeKey = _placeKey(name);
      names.putIfAbsent(placeKey, () => name);
      if (entry.location case final location?) {
        locations.putIfAbsent(placeKey, () => location);
      }
    }
  }
  final leftOut = leaveOutEnds
      ? _leftOutPlaces(chronological)
      : const <String>{};
  final keys = [
    for (final placeKey in names.keys)
      if (!leftOut.contains(placeKey)) placeKey,
  ];
  final stops = [
    for (final placeKey in keys)
      TripStop(name: names[placeKey] ?? '', location: locations[placeKey]),
  ];
  final located = [for (final stop in stops) ?stop.location];
  var distance = 0.0;
  for (var i = 1; i < located.length; i++) {
    distance += located[i - 1].distanceTo(located[i]);
  }
  final shown = _withoutPlaces(chronological, leftOut);
  return TripPicture(
    title: trip.title,
    startDate: trip.startDate,
    endDate: trip.endDate,
    dayCount: trip.dayCount,
    stops: stops,
    distanceMeters: distance,
    photoPaths: switch (_keepChosen(chosenPhotos, shown)) {
      [] => _pickPhotos(shown),
      final chosen => chosen,
    },
  );
}

String _placeKey(String name) => name.trim().toLowerCase();

/// The first and the last place of the trip (by [chronological] entries).
/// The trip ends where the last named entry is – on a round trip that is
/// the first place again, so only home is left out.
Set<String> _leftOutPlaces(List<Entry> chronological) {
  final named = [for (final entry in chronological) ?entry.placeName];
  if (named.isEmpty) return const {};
  return {_placeKey(named.first), _placeKey(named.last)};
}

List<Entry> _withoutPlaces(List<Entry> entries, Set<String> leftOut) => [
  for (final entry in entries)
    if (entry.placeName == null ||
        !leftOut.contains(_placeKey(entry.placeName ?? '')))
      entry,
];

List<String> _keepChosen(List<String> chosen, List<Entry> entries) {
  final available = {for (final entry in entries) ...entry.photoPaths};
  return {
    for (final path in chosen)
      if (available.contains(path)) path,
  }.take(TripPicture.maxPhotos).toList();
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

/// The picture of one trip day, e.g. for an Instagram carousel.
class DayPicture {
  const DayPicture({
    required this.day,
    required this.dayNumber,
    required this.picture,
  });

  /// The local calendar day (see `dayOf`).
  final DateTime day;

  /// 1 for the trip's first day; `null` outside the trip dates.
  final int? dayNumber;
  final TripPicture picture;
}

/// One [DayPicture] per local day with entries, in date order. Each shows
/// the places of that day like [buildTripPicture]; its photos start with
/// the day's stored title photo. With [leaveOutEnds] the first and last
/// place of the whole trip are left out and days without other entries
/// are dropped.
List<DayPicture> buildDayPictures(
  Trip trip,
  List<Entry> entries, {
  required bool leaveOutEnds,
}) {
  final chronological = sortEntriesChronologically(entries);
  final shown = leaveOutEnds
      ? _withoutPlaces(chronological, _leftOutPlaces(chronological))
      : chronological;
  return [
    for (final day in groupEntriesByDay(trip, shown))
      DayPicture(
        day: day.day,
        dayNumber: day.dayNumber,
        picture: _dayPicture(trip, day),
      ),
  ];
}

TripPicture _dayPicture(Trip trip, TripDay day) {
  final picture = buildTripPicture(trip, day.entries, leaveOutEnds: false);
  final cover = trip.dayCoverPhotos[day.day];
  final dayPhotos = {for (final entry in day.entries) ...entry.photoPaths};
  return TripPicture(
    title: trip.title,
    startDate: day.day,
    endDate: day.day,
    dayCount: 1,
    stops: picture.stops,
    distanceMeters: picture.distanceMeters,
    photoPaths: {
      if (cover != null && dayPhotos.contains(cover)) cover,
      ...picture.photoPaths,
    }.take(TripPicture.maxPhotos).toList(),
  );
}
