import 'clock.dart';

/// A journey the user records, spanning one or more calendar days.
///
/// Dates are stored as calendar days (see [dayOf]) so a trip never shifts by
/// a day because of time zones or daylight saving time.
class Trip {
  /// Creates a validated trip; throws [ArgumentError] for an empty title or
  /// an end date before the start date.
  factory Trip({
    required String id,
    required String title,
    required DateTime startDate,
    required DateTime endDate,
    String? coverPhotoPath,
    Map<DateTime, String> dayCoverPhotos = const {},
  }) {
    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) {
      throw ArgumentError.value(title, 'title', 'must not be empty');
    }
    final start = dayOf(startDate);
    final end = dayOf(endDate);
    if (end.isBefore(start)) {
      throw ArgumentError.value(endDate, 'endDate', 'must not be before start');
    }
    final cover = coverPhotoPath?.trim();
    return Trip._(
      id: id,
      title: trimmedTitle,
      startDate: start,
      endDate: end,
      coverPhotoPath: cover == null || cover.isEmpty ? null : cover,
      dayCoverPhotos: Map.unmodifiable({
        for (final MapEntry(:key, :value) in dayCoverPhotos.entries)
          if (value.trim().isNotEmpty) dayOf(key): value.trim(),
      }),
    );
  }

  const Trip._({
    required this.id,
    required this.title,
    required this.startDate,
    required this.endDate,
    required this.coverPhotoPath,
    required this.dayCoverPhotos,
  });

  final String id;
  final String title;
  final DateTime startDate;
  final DateTime endDate;

  /// Photo the traveler chose as cover (relative path), `null` for the
  /// automatic cover.
  final String? coverPhotoPath;

  /// Title photos chosen for single days of the trip (calendar day →
  /// relative photo path), e.g. for the slideshow.
  final Map<DateTime, String> dayCoverPhotos;

  /// Returns the trip with [path] as title photo of [day]; `null` removes it.
  Trip withDayCover(DateTime day, String? path) {
    final covers = {...dayCoverPhotos}..remove(dayOf(day));
    if (path != null) covers[dayOf(day)] = path;
    return Trip(
      id: id,
      title: title,
      startDate: startDate,
      endDate: endDate,
      coverPhotoPath: coverPhotoPath,
      dayCoverPhotos: covers,
    );
  }

  /// Number of calendar days the trip covers, counting both ends.
  int get dayCount => endDate.difference(startDate).inDays + 1;

  /// Returns a new trip with the given fields replaced, validated like a new
  /// trip.
  Trip copyWith({
    String? title,
    DateTime? startDate,
    DateTime? endDate,
    String? coverPhotoPath,
    bool clearCoverPhoto = false,
  }) {
    return Trip(
      id: id,
      title: title ?? this.title,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      coverPhotoPath: clearCoverPhoto
          ? null
          : coverPhotoPath ?? this.coverPhotoPath,
      dayCoverPhotos: dayCoverPhotos,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Trip &&
      other.id == id &&
      other.title == title &&
      other.startDate == startDate &&
      other.endDate == endDate &&
      other.coverPhotoPath == coverPhotoPath &&
      other.dayCoverPhotos.length == dayCoverPhotos.length &&
      dayCoverPhotos.entries.every(
        (entry) => other.dayCoverPhotos[entry.key] == entry.value,
      );

  @override
  int get hashCode =>
      Object.hash(
        id,
        title,
        startDate,
        endDate,
        coverPhotoPath,
        Object.hashAllUnordered([
          for (final entry in dayCoverPhotos.entries)
            Object.hash(entry.key, entry.value),
        ]),
      );

  @override
  String toString() => 'Trip($id, $title, $startDate – $endDate)';
}

/// Orders trips for display: the most recent start date first, trips starting
/// on the same day alphabetically by title. The input is left unchanged.
List<Trip> sortTripsNewestFirst(Iterable<Trip> trips) {
  return trips.toList()..sort((a, b) {
    final byStart = b.startDate.compareTo(a.startDate);
    return byStart != 0 ? byStart : a.title.compareTo(b.title);
  });
}
