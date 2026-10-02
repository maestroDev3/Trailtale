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

/// The content of a trip slideshow: title slide, stop slides, closing slide.
class Slideshow {
  const Slideshow({
    required this.overview,
    required this.coverPhotoPath,
    required this.stops,
  });

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
