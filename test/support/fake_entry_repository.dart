import 'dart:async';

import 'package:trailtale/domain/current_then_changes.dart';
import 'package:trailtale/domain/entry.dart';
import 'package:trailtale/domain/entry_repository.dart';

/// In-memory [EntryRepository] for widget tests; follows the same contract as
/// the file-based repository.
class FakeEntryRepository implements EntryRepository {
  FakeEntryRepository([Iterable<Entry> entries = const []])
    : _entries = sortEntriesChronologically(entries);

  final _changes = StreamController<List<Entry>>.broadcast();
  List<Entry> _entries;

  /// All stored entries of all trips, in chronological order.
  List<Entry> get entries => _entries;

  @override
  Stream<List<Entry>> watchEntries(String tripId) => currentThenChanges(
    () async => _entriesOf(tripId),
    _changes.stream.map((_) => _entriesOf(tripId)),
  );

  @override
  Future<void> saveEntry(Entry entry) async {
    _update([..._entries.where((stored) => stored.id != entry.id), entry]);
  }

  @override
  Future<void> deleteEntry(String id) async {
    if (_entries.every((entry) => entry.id != id)) return;
    _update(_entries.where((entry) => entry.id != id).toList());
  }

  @override
  Future<List<Entry>> deleteEntriesOfTrip(String tripId) async {
    final deleted = _entriesOf(tripId);
    if (deleted.isEmpty) return deleted;
    _update(_entries.where((entry) => entry.tripId != tripId).toList());
    return deleted;
  }

  List<Entry> _entriesOf(String tripId) =>
      _entries.where((entry) => entry.tripId == tripId).toList();

  void _update(List<Entry> entries) {
    _entries = sortEntriesChronologically(entries);
    _changes.add(_entries);
  }
}
