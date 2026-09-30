import 'entry.dart';

/// The place names of a trip in the order they were first visited; a place
/// visited again later (ignoring case and surrounding spaces) is listed once,
/// spelled as on its first visit.
List<String> routePlaces(List<Entry> entries) {
  final seen = <String>{};
  return [
    for (final entry in sortEntriesChronologically(entries))
      if (entry.placeName case final name?)
        if (seen.add(name.trim().toLowerCase())) name,
  ];
}
