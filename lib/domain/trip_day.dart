import 'entry.dart';
import 'trip.dart';

/// One calendar day of a trip with the entries recorded on it (local time).
class TripDay {
  const TripDay({
    required this.day,
    required this.dayNumber,
    required this.entries,
  });

  /// The local calendar day at midnight UTC (see `dayOf`).
  final DateTime day;

  /// 1 for the trip's start date, 2 for the next day, …; `null` for days
  /// outside the trip's dates.
  final int? dayNumber;

  /// Entries of this day in chronological order.
  final List<Entry> entries;
}

/// Groups [entries] into trip days by the local day they were recorded on,
/// in chronological order. Only days with entries are returned.
List<TripDay> groupEntriesByDay(Trip trip, List<Entry> entries) {
  final byDay = <DateTime, List<Entry>>{};
  for (final entry in sortEntriesChronologically(entries)) {
    byDay.putIfAbsent(entry.localDay, () => []).add(entry);
  }
  final days = byDay.keys.toList()..sort();
  return [
    for (final day in days)
      TripDay(
        day: day,
        dayNumber: _dayNumber(trip, day),
        entries: List.unmodifiable(byDay[day] ?? const <Entry>[]),
      ),
  ];
}

int? _dayNumber(Trip trip, DateTime day) {
  if (day.isBefore(trip.startDate) || day.isAfter(trip.endDate)) return null;
  return day.difference(trip.startDate).inDays + 1;
}
