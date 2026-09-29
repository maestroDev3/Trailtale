import 'entry.dart';

/// Single source of the entries of all trips; screens only use this
/// interface so storage can change without touching them.
abstract interface class EntryRepository {
  /// Emits the entries of [tripId] in chronological order, immediately and
  /// after every change.
  Stream<List<Entry>> watchEntries(String tripId);

  /// Stores [entry], replacing a stored entry with the same id.
  Future<void> saveEntry(Entry entry);

  /// Removes the entry with [id]; unknown ids are ignored.
  Future<void> deleteEntry(String id);

  /// Removes all entries of [tripId], e.g. when the trip is deleted.
  Future<void> deleteEntriesOfTrip(String tripId);
}
