import 'dart:async';

import 'package:trailtale/domain/current_then_changes.dart';
import 'package:trailtale/domain/trip.dart';
import 'package:trailtale/domain/trip_repository.dart';

/// In-memory [TripRepository] for widget tests; follows the same contract as
/// the file-based repository.
class FakeTripRepository implements TripRepository {
  FakeTripRepository([Iterable<Trip> trips = const []])
    : _trips = sortTripsNewestFirst(trips);

  final _changes = StreamController<List<Trip>>.broadcast();
  List<Trip> _trips;

  /// The currently stored trips, newest first.
  List<Trip> get trips => _trips;

  @override
  Stream<List<Trip>> watchTrips() =>
      currentThenChanges(() async => _trips, _changes.stream);

  @override
  Future<void> saveTrip(Trip trip) async {
    _update([..._trips.where((stored) => stored.id != trip.id), trip]);
  }

  @override
  Future<void> deleteTrip(String id) async {
    if (_trips.every((trip) => trip.id != id)) return;
    _update(_trips.where((trip) => trip.id != id).toList());
  }

  void _update(List<Trip> trips) {
    _trips = sortTripsNewestFirst(trips);
    _changes.add(_trips);
  }
}
