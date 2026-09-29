import 'dart:io';

import '../domain/current_then_changes.dart';
import '../domain/entry.dart';
import '../domain/entry_repository.dart';
import '../domain/geo_point.dart';
import 'versioned_json_list.dart';

/// Stores the entries of all trips in one versioned JSON file, e.g.
/// `entries.json` in the app documents directory.
///
/// Format version 1: `{"version": 1, "entries": [{"id", "tripId", "time"
/// (ISO-8601 UTC), "utcOffsetMinutes", "note", "placeName", "location":
/// {"latitude", "longitude"} | null}]}`.
class JsonFileEntryRepository implements EntryRepository {
  JsonFileEntryRepository(File file)
    : _store = VersionedJsonList(
        file: file,
        listKey: 'entries',
        fromJson: _entryFromJson,
        toJson: _entryToJson,
      );

  final VersionedJsonList<Entry> _store;

  @override
  Stream<List<Entry>> watchEntries(String tripId) => currentThenChanges(
    () async => _entriesOf(await _store.read(), tripId),
    _store.changes.map((entries) => _entriesOf(entries, tripId)),
  );

  @override
  Future<void> saveEntry(Entry entry) => _store.update(
    (entries) => sortEntriesChronologically([
      ...entries.where((stored) => stored.id != entry.id),
      entry,
    ]),
  );

  @override
  Future<void> deleteEntry(String id) =>
      _store.update((entries) => _without(entries, (entry) => entry.id == id));

  @override
  Future<void> deleteEntriesOfTrip(String tripId) => _store.update(
    (entries) => _without(entries, (entry) => entry.tripId == tripId),
  );
}

List<Entry> _entriesOf(List<Entry> entries, String tripId) =>
    sortEntriesChronologically(
      entries.where((entry) => entry.tripId == tripId),
    );

/// Returns [entries] itself if nothing matches, so no write happens.
List<Entry> _without(List<Entry> entries, bool Function(Entry) matches) =>
    entries.any(matches) ? entries.where((e) => !matches(e)).toList() : entries;

Map<String, Object?> _entryToJson(Entry entry) => {
  'id': entry.id,
  'tripId': entry.tripId,
  'time': entry.time.toIso8601String(),
  'utcOffsetMinutes': entry.utcOffset.inMinutes,
  'note': entry.note,
  'placeName': entry.placeName,
  'location': switch (entry.location) {
    final location? => {
      'latitude': location.latitude,
      'longitude': location.longitude,
    },
    null => null,
  },
};

Entry _entryFromJson(Map<String, dynamic> json) => Entry(
  id: json['id'] as String,
  tripId: json['tripId'] as String,
  time: DateTime.parse(json['time'] as String),
  utcOffset: Duration(minutes: json['utcOffsetMinutes'] as int),
  note: json['note'] as String,
  placeName: json['placeName'] as String?,
  location: switch (json['location']) {
    final Map<String, dynamic> location => GeoPoint(
      latitude: (location['latitude'] as num).toDouble(),
      longitude: (location['longitude'] as num).toDouble(),
    ),
    _ => null,
  },
);
