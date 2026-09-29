import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../domain/current_then_changes.dart';
import '../domain/trip.dart';
import '../domain/trip_repository.dart';

/// Stores all trips in one versioned JSON file, e.g. `trips.json` in the app
/// documents directory.
///
/// Format version 1: `{"version": 1, "trips": [{"id", "title", "startDate",
/// "endDate"}]}` with dates as `yyyy-MM-dd`.
class JsonFileTripRepository implements TripRepository {
  JsonFileTripRepository(this.file);

  static const currentVersion = 1;

  final File file;
  final _changes = StreamController<List<Trip>>.broadcast();
  Future<void> _queue = Future.value();
  List<Trip>? _trips;

  @override
  Stream<List<Trip>> watchTrips() =>
      currentThenChanges(() => _serialized(_load), _changes.stream);

  @override
  Future<void> saveTrip(Trip trip) => _serialized(() async {
    final trips = await _load();
    await _store([...trips.where((stored) => stored.id != trip.id), trip]);
  });

  @override
  Future<void> deleteTrip(String id) => _serialized(() async {
    final trips = await _load();
    if (trips.every((trip) => trip.id != id)) return;
    await _store(trips.where((trip) => trip.id != id).toList());
  });

  /// Runs file operations one after another so concurrent saves never
  /// overwrite each other.
  Future<T> _serialized<T>(Future<T> Function() operation) {
    final result = _queue.then((_) => operation());
    _queue = result.then((_) {}, onError: (_) {});
    return result;
  }

  Future<List<Trip>> _load() async {
    if (_trips case final trips?) return trips;
    if (!file.existsSync()) return _trips = const [];
    final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    final version = json['version'];
    if (version != currentVersion) {
      throw StateError('Unsupported trips file version: $version');
    }
    final trips = (json['trips'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(_tripFromJson);
    return _trips = sortTripsNewestFirst(trips);
  }

  Future<void> _store(List<Trip> trips) async {
    final sorted = sortTripsNewestFirst(trips);
    final json = {
      'version': currentVersion,
      'trips': sorted.map(_tripToJson).toList(),
    };
    final temporary = File('${file.path}.tmp');
    await temporary.parent.create(recursive: true);
    await temporary.writeAsString(jsonEncode(json), flush: true);
    await temporary.rename(file.path);
    _trips = sorted;
    _changes.add(sorted);
  }
}

Map<String, Object> _tripToJson(Trip trip) => {
  'id': trip.id,
  'title': trip.title,
  'startDate': _formatDate(trip.startDate),
  'endDate': _formatDate(trip.endDate),
};

Trip _tripFromJson(Map<String, dynamic> json) => Trip(
  id: json['id'] as String,
  title: json['title'] as String,
  startDate: DateTime.parse(json['startDate'] as String),
  endDate: DateTime.parse(json['endDate'] as String),
);

String _formatDate(DateTime day) {
  final month = day.month.toString().padLeft(2, '0');
  final dayOfMonth = day.day.toString().padLeft(2, '0');
  return '${day.year.toString().padLeft(4, '0')}-$month-$dayOfMonth';
}
