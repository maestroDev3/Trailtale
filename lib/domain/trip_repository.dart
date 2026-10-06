import 'dart:async';

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

/// The stored trips once, e.g. for a one-time decision.
///
/// Listens and cancels after the first value instead of `Stream.first`,
/// which never completed on the repository stream in widget tests.
Future<List<Trip>> readTripsOnce(TripRepository repository) {
  final completer = Completer<List<Trip>>();
  late final StreamSubscription<List<Trip>> subscription;
  subscription = repository.watchTrips().listen((trips) {
    if (completer.isCompleted) return;
    completer.complete(trips);
    unawaited(subscription.cancel());
  }, onError: completer.completeError);
  return completer.future;
}
