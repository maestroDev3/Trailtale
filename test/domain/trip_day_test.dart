import 'package:flutter_test/flutter_test.dart';
import 'package:trailtale/domain/entry.dart';
import 'package:trailtale/domain/trip.dart';
import 'package:trailtale/domain/trip_day.dart';

void main() {
  final trip = Trip(
    id: 'lisbon',
    title: 'Lisbon',
    startDate: DateTime(2026, 5, 1),
    endDate: DateTime(2026, 5, 4),
  );
  const plusTwo = Duration(hours: 2);

  Entry entry(String id, DateTime utc, {Duration offset = plusTwo}) =>
      Entry(id: id, tripId: 'lisbon', time: utc, utcOffset: offset, note: id);

  group('groupEntriesByDay', () {
    test('returns no days without entries', () {
      expect(groupEntriesByDay(trip, const []), isEmpty);
    });

    test('groups entries by local day in chronological order', () {
      final dinner = entry('dinner', DateTime.utc(2026, 5, 1, 18));
      final breakfast = entry('breakfast', DateTime.utc(2026, 5, 1, 6));
      final museum = entry('museum', DateTime.utc(2026, 5, 3, 9));
      final input = [museum, dinner, breakfast];

      final days = groupEntriesByDay(trip, input);

      expect(days.map((day) => day.day), [
        DateTime.utc(2026, 5, 1),
        DateTime.utc(2026, 5, 3),
      ]);
      expect(days.first.entries, [breakfast, dinner]);
      expect(days.last.entries, [museum]);
      expect(input, [museum, dinner, breakfast]);
    });

    test('numbers days from the trip start', () {
      final days = groupEntriesByDay(trip, [
        entry('a', DateTime.utc(2026, 5, 1, 9)),
        entry('b', DateTime.utc(2026, 5, 4, 9)),
      ]);

      expect(days.map((day) => day.dayNumber), [1, 4]);
    });

    test('has no day number outside the trip', () {
      final days = groupEntriesByDay(trip, [
        entry('before', DateTime.utc(2026, 4, 30, 9)),
        entry('after', DateTime.utc(2026, 5, 5, 9)),
      ]);

      expect(days.map((day) => day.dayNumber), [null, null]);
    });

    test('keeps a late evening entry on its local day', () {
      final late = entry('late', DateTime.utc(2026, 5, 1, 21, 30));

      final days = groupEntriesByDay(trip, [late]);

      expect(days.single.day, DateTime.utc(2026, 5, 1));
      expect(days.single.dayNumber, 1);
    });

    test('puts an entry after local midnight on the new day', () {
      final early = entry('early', DateTime.utc(2026, 5, 1, 22, 30));

      final days = groupEntriesByDay(trip, [early]);

      expect(days.single.day, DateTime.utc(2026, 5, 2));
      expect(days.single.dayNumber, 2);
    });

    test('uses each entry’s own offset', () {
      final instant = DateTime.utc(2026, 5, 1, 23);
      final inLisbon = entry(
        'lisbon',
        instant,
        offset: const Duration(hours: 1),
      );
      final inAzores = entry('azores', instant, offset: Duration.zero);

      final days = groupEntriesByDay(trip, [inLisbon, inAzores]);

      expect(days.map((day) => day.day), [
        DateTime.utc(2026, 5, 1),
        DateTime.utc(2026, 5, 2),
      ]);
      expect(days.first.entries, [inAzores]);
      expect(days.last.entries, [inLisbon]);
    });
  });
}
