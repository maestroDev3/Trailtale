import 'clock.dart';
import 'entry.dart';
import 'trip.dart';

/// The trip's cover: the first photo of the earliest entry that has photos,
/// or `null` if the trip has no photos yet.
String? coverPhotoOf(List<Entry> entries) {
  for (final entry in sortEntriesChronologically(entries)) {
    if (entry.photoPaths.isNotEmpty) return entry.photoPaths.first;
  }
  return null;
}

/// Where a trip stands relative to today.
sealed class TripProgress {
  const TripProgress();
}

/// The trip starts in [daysUntilStart] days.
final class UpcomingTrip extends TripProgress {
  const UpcomingTrip({required this.daysUntilStart});

  final int daysUntilStart;

  @override
  bool operator ==(Object other) =>
      other is UpcomingTrip && other.daysUntilStart == daysUntilStart;

  @override
  int get hashCode => daysUntilStart.hashCode;
}

/// Today is day [dayNumber] of [dayCount] of the trip.
final class RunningTrip extends TripProgress {
  const RunningTrip({required this.dayNumber, required this.dayCount});

  final int dayNumber;
  final int dayCount;

  @override
  bool operator ==(Object other) =>
      other is RunningTrip &&
      other.dayNumber == dayNumber &&
      other.dayCount == dayCount;

  @override
  int get hashCode => Object.hash(dayNumber, dayCount);
}

/// The trip is over.
final class PastTrip extends TripProgress {
  const PastTrip();

  @override
  bool operator ==(Object other) => other is PastTrip;

  @override
  int get hashCode => 0;
}

/// Compares [trip] with the calendar day of [today].
TripProgress tripProgress(Trip trip, {required DateTime today}) {
  final day = dayOf(today);
  if (day.isBefore(trip.startDate)) {
    return UpcomingTrip(daysUntilStart: trip.startDate.difference(day).inDays);
  }
  if (day.isAfter(trip.endDate)) return const PastTrip();
  return RunningTrip(
    dayNumber: day.difference(trip.startDate).inDays + 1,
    dayCount: trip.dayCount,
  );
}
