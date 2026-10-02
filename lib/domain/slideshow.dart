import 'entry.dart';
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

/// Builds the slideshow of [trip].
Slideshow buildSlideshow(
  Trip trip,
  List<Entry> entries, {
  required bool leaveOutEnds,
}) => throw UnimplementedError();
