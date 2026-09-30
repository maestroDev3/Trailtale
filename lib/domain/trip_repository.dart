import 'trip.dart';

/// Single source of the user's trips; the UI only talks to this interface so
/// storage can change (e.g. to a backend) without touching screens.
abstract interface class TripRepository {
  /// Emits all trips sorted newest first, immediately and after every change.
  Stream<List<Trip>> watchTrips();

  /// Stores [trip], replacing a stored trip with the same id.
  Future<void> saveTrip(Trip trip);

  /// Removes the trip with [id]; unknown ids are ignored.
  Future<void> deleteTrip(String id);

  /// Reads the stored trips again, e.g. after a backup was restored, and
  /// emits them to all listeners.
  Future<void> reload();
}
