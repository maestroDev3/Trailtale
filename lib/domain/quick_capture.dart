import 'entry.dart';
import 'geo_point.dart';
import 'place.dart';
import 'trip.dart';
import 'trip_overview.dart';

/// Where a quick capture (home screen widget “I'm here”) saves its entry.
sealed class QuickCaptureTarget {
  const QuickCaptureTarget();
}

/// Exactly one trip runs today; the entry goes there without asking.
final class CaptureInto extends QuickCaptureTarget {
  const CaptureInto(this.trip);

  final Trip trip;
}

/// The traveler chooses the trip from [trips].
final class ChooseTrip extends QuickCaptureTarget {
  const ChooseTrip(this.trips);

  final List<Trip> trips;
}

/// There is no trip yet.
final class NoTrip extends QuickCaptureTarget {
  const NoTrip();
}

/// Decides where a quick capture on [today] goes: into the one trip running
/// today; otherwise the traveler chooses, running trips first, then all
/// others newest first.
QuickCaptureTarget quickCaptureTarget(
  List<Trip> trips, {
  required DateTime today,
}) {
  if (trips.isEmpty) return const NoTrip();
  final newestFirst = sortTripsNewestFirst(trips);
  bool runs(Trip trip) => tripProgress(trip, today: today) is RunningTrip;
  final running = newestFirst.where(runs).toList();
  if (running case [final trip]) return CaptureInto(trip);
  return ChooseTrip([
    ...running,
    ...newestFirst.where((trip) => !runs(trip)),
  ]);
}

/// The entry a quick capture saves.
Entry buildQuickEntry({
  required String id,
  required Trip trip,
  required DateTime localTime,
  required GeoPoint location,
  required Place? nearestPlace,
}) => Entry.atLocalTime(
  id: id,
  tripId: trip.id,
  localTime: localTime,
  placeName: nearestPlace?.name,
  location: location,
);
