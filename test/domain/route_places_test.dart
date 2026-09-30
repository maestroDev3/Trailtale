import 'package:flutter_test/flutter_test.dart';
import 'package:trailtale/domain/entry.dart';
import 'package:trailtale/domain/route_places.dart';

void main() {
  Entry entry(String id, int hour, String? place) => Entry(
    id: id,
    tripId: 'portugal',
    time: DateTime.utc(2026, 5, 1, hour),
    utcOffset: Duration.zero,
    note: id,
    placeName: place,
  );

  group('routePlaces', () {
    test('is empty without places', () {
      expect(routePlaces(const []), isEmpty);
      expect(routePlaces([entry('a', 8, null)]), isEmpty);
    });

    test('lists places in the order they were first visited', () {
      final places = routePlaces([
        entry('porto', 18, 'Porto'),
        entry('lisbon', 8, 'Lisbon'),
        entry('sintra', 12, 'Sintra'),
      ]);

      expect(places, ['Lisbon', 'Sintra', 'Porto']);
    });

    test('lists a place visited again only once, spelled as first', () {
      final places = routePlaces([
        entry('a', 8, 'Lisbon'),
        entry('b', 12, 'Sintra'),
        entry('c', 18, ' lisbon '),
        entry('d', 20, null),
      ]);

      expect(places, ['Lisbon', 'Sintra']);
    });
  });
}
