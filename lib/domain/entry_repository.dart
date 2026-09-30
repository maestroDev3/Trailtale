import 'entry.dart';

/// Single source of the entries of all trips; screens only use this
/// interface so storage can change without touching them.
abstract interface class EntryRepository {
  /// Emits the entries of [tripId] in chronological order, immediately and
  /// after every change.
  Stream<List<Entry>> watchEntries(String tripId);

  /// Emits the entries of all trips in chronological order, immediately
  /// and after every change (e.g. for the overview of all trips).
  Stream<List<Entry>> watchAllEntries();

  /// Stores [entry], replacing a stored entry with the same id.
  Future<void> saveEntry(Entry entry);

  /// Removes the entry with [id]; unknown ids are ignored.
  Future<void> deleteEntry(String id);

  /// Removes all entries of [tripId], e.g. when the trip is deleted, and
  /// returns them in chronological order (to clean up their photos).
  Future<List<Entry>> deleteEntriesOfTrip(String tripId);

  /// Reads the stored entries again, e.g. after a backup was restored, and
  /// emits them to all listeners.
  Future<void> reload();
}
