import 'clock.dart';
import 'trip.dart';

/// Suggested time for a new entry of [trip]: [now] while the trip is running,
/// otherwise the trip's first day at the current time of day, so entries
/// added before or after the journey land inside it.
DateTime defaultEntryTime({required Trip trip, required DateTime now}) {
  final today = dayOf(now);
  if (!today.isBefore(trip.startDate) && !today.isAfter(trip.endDate)) {
    return now;
  }
  final start = trip.startDate;
  return DateTime(start.year, start.month, start.day, now.hour, now.minute);
}
