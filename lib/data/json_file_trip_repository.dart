import 'dart:io';

import '../domain/current_then_changes.dart';
import '../domain/trip.dart';
import '../domain/trip_repository.dart';
import 'versioned_json_list.dart';

/// Stores all trips in one versioned JSON file, e.g. `trips.json` in the app
/// documents directory.
///
/// Format version 1: `{"version": 1, "trips": [{"id", "title", "startDate",
/// "endDate", "coverPhoto"?}]}` with dates as `yyyy-MM-dd`; `coverPhoto`
/// (the chosen cover's relative path) and `dayCovers` (`{"yyyy-MM-dd": path}`,
/// title photos of single days) are optional and only written when set.
class JsonFileTripRepository implements TripRepository {
  JsonFileTripRepository(File file)
    : _store = VersionedJsonList(
        file: file,
        listKey: 'trips',
        fromJson: _tripFromJson,
        toJson: _tripToJson,
      );

  final VersionedJsonList<Trip> _store;

  @override
  Future<void> reload() => _store.reload();

  @override
  Stream<List<Trip>> watchTrips() => currentThenChanges(
    () async => sortTripsNewestFirst(await _store.read()),
    _store.changes.map(sortTripsNewestFirst),
  );

  @override
  Future<void> saveTrip(Trip trip) => _store.update(
    (trips) => sortTripsNewestFirst([
      ...trips.where((stored) => stored.id != trip.id),
      trip,
    ]),
  );

  @override
  Future<void> deleteTrip(String id) => _store.update(
    (trips) => trips.every((trip) => trip.id != id)
        ? trips
        : trips.where((trip) => trip.id != id).toList(),
  );
}

Map<String, Object?> _tripToJson(Trip trip) => {
  'id': trip.id,
  'title': trip.title,
  'startDate': _formatDate(trip.startDate),
  'endDate': _formatDate(trip.endDate),
  'coverPhoto': ?trip.coverPhotoPath,
  if (trip.dayCoverPhotos.isNotEmpty)
    'dayCovers': {
      for (final MapEntry(:key, :value) in trip.dayCoverPhotos.entries)
        _formatDate(key): value,
    },
};

Trip _tripFromJson(Map<String, dynamic> json) => Trip(
  id: json['id'] as String,
  title: json['title'] as String,
  startDate: DateTime.parse(json['startDate'] as String),
  endDate: DateTime.parse(json['endDate'] as String),
  coverPhotoPath: json['coverPhoto'] as String?,
  dayCoverPhotos: {
    for (final MapEntry(:key, :value)
        in ((json['dayCovers'] as Map<String, dynamic>?) ?? const {}).entries)
      DateTime.parse(key): value as String,
  },
);

String _formatDate(DateTime day) {
  final month = day.month.toString().padLeft(2, '0');
  final dayOfMonth = day.day.toString().padLeft(2, '0');
  return '${day.year.toString().padLeft(4, '0')}-$month-$dayOfMonth';
}
