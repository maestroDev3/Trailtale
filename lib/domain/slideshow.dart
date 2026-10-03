import 'entry.dart';
import 'trip_overview.dart';
import 'trip.dart';
import 'trip_picture.dart';

/// One slide per stop of the trip.
class StopSlide {
  const StopSlide({
    required this.number,
    required this.name,
    required this.firstVisit,
    required this.photoPath,
    required this.notes,
  });

  final int number;
  final String name;

  /// Local wall-clock time of the first entry at this stop.
  final DateTime firstVisit;
  final String? photoPath;
  final List<String> notes;
}

/// A photo on its own slide.
class PhotoSlide {
  const PhotoSlide({required this.path, this.caption, this.place});

  final String path;

  /// The note of the photo's entry, if any.
  final String? caption;
  final String? place;
}

/// One slide per trip day, followed by its photos.
class DaySlide {
  const DaySlide({
    required this.day,
    required this.dayNumber,
    required this.places,
    required this.titlePhotoPath,
    required this.notes,
    required this.photos,
  });

  /// The local calendar day (see `dayOf`).
  final DateTime day;

  /// 1 for the trip's first day; `null` outside the trip dates.
  final int? dayNumber;
  final List<String> places;
  final String? titlePhotoPath;

  /// Notes of the day's entries without photos.
  final List<String> notes;
  final List<PhotoSlide> photos;
}

/// The content of a trip slideshow: title slide, stop slides, closing slide.
class Slideshow {
  const Slideshow({
    required this.overview,
    required this.coverPhotoPath,
    required this.stops,
    this.days = const [],
  });

  /// The days of the trip with their photos.
  final List<DaySlide> days;

  /// Title, dates and figures (as on the trip picture).
  final TripPicture overview;
  final String? coverPhotoPath;
  final List<StopSlide> stops;
}

/// Most notes a stop slide shows.
const maxNotesPerSlide = 3;

/// Builds the slideshow of [trip]: one slide per stop of the trip picture
/// (same stops, same rule for [leaveOutEnds]); entries belong to a stop by
/// place name (case and surrounding spaces ignored).
Slideshow buildSlideshow(
  Trip trip,
  List<Entry> entries, {
  required bool leaveOutEnds,
  Set<String> excludedPhotos = const {},
}) {
  String key(String name) => name.trim().toLowerCase();
  final overview = buildTripPicture(trip, entries, leaveOutEnds: leaveOutEnds);
  final chronological = sortEntriesChronologically(entries);
  final byStop = <String, List<Entry>>{};
  for (final entry in chronological) {
    if (entry.placeName case final name?) {
      byStop.putIfAbsent(key(name), () => []).add(entry);
    }
  }
  final shownKeys = {for (final stop in overview.stops) key(stop.name)};
  bool isShown(Entry entry) => switch (entry.placeName) {
    final name? => shownKeys.contains(key(name)),
    null => true,
  };
  final shownEntries = chronological.where(isShown).toList();
  final stops = [
    for (final (index, stop) in overview.stops.indexed)
      _stopSlide(index + 1, stop.name, byStop[key(stop.name)] ?? const []),
  ];
  return Slideshow(
    overview: overview,
    coverPhotoPath: coverPhotoOf(shownEntries, chosen: trip.coverPhotoPath),
    stops: stops,
    days: _daySlides(trip, shownEntries, excludedPhotos),
  );
}

/// One [DaySlide] per local day of [entries] (in time order).
List<DaySlide> _daySlides(
  Trip trip,
  List<Entry> entries,
  Set<String> excludedPhotos,
) {
  final byDay = <DateTime, List<Entry>>{};
  for (final entry in entries) {
    byDay.putIfAbsent(entry.localDay, () => []).add(entry);
  }
  return [
    for (final MapEntry(key: day, value: dayEntries) in byDay.entries)
      _daySlide(trip, day, dayEntries, excludedPhotos),
  ];
}

DaySlide _daySlide(
  Trip trip,
  DateTime day,
  List<Entry> entries,
  Set<String> excludedPhotos,
) {
  final places = <String, String>{};
  for (final entry in entries) {
    if (entry.placeName case final name?) {
      places.putIfAbsent(name.trim().toLowerCase(), () => name);
    }
  }
  final photos = [
    for (final entry in entries)
      for (final path in entry.photoPaths)
        if (!excludedPhotos.contains(path))
          PhotoSlide(
            path: path,
            caption: entry.note.trim().isEmpty ? null : entry.note.trim(),
            place: entry.placeName,
          ),
  ];
  final chosen = trip.dayCoverPhotos[day];
  final title =
      photos.where((photo) => photo.path == chosen).firstOrNull ??
      photos.firstOrNull;
  final number = day.difference(trip.startDate).inDays + 1;
  return DaySlide(
    day: day,
    dayNumber: number >= 1 && number <= trip.dayCount ? number : null,
    places: places.values.toList(),
    titlePhotoPath: title?.path,
    notes: [
      for (final entry in entries)
        if (entry.photoPaths.isEmpty && entry.note.trim().isNotEmpty)
          entry.note.trim(),
    ].take(maxNotesPerSlide).toList(),
    photos: [
      for (final photo in photos)
        if (!identical(photo, title)) photo,
    ],
  );
}

StopSlide _stopSlide(int number, String name, List<Entry> entries) {
  final first = entries.first.localDateTime;
  return StopSlide(
    number: number,
    name: name,
    firstVisit: DateTime(
      first.year,
      first.month,
      first.day,
      first.hour,
      first.minute,
    ),
    photoPath: [for (final entry in entries) ...entry.photoPaths].firstOrNull,
    notes: [
      for (final entry in entries)
        if (entry.note.trim().isNotEmpty) entry.note.trim(),
    ].take(maxNotesPerSlide).toList(),
  );
}
