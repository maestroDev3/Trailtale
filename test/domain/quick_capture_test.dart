import 'package:flutter_test/flutter_test.dart';
import 'package:trailtale/domain/geo_point.dart';
import 'package:trailtale/domain/place.dart';
import 'package:trailtale/domain/quick_capture.dart';
import 'package:trailtale/domain/trip.dart';

void main() {
  final today = DateTime(2026, 10, 6, 9, 41);
  Trip trip(String id, DateTime start, DateTime end) =>
      Trip(id: id, title: id, startDate: start, endDate: end);
  final montenegro = trip(
    'montenegro',
    DateTime(2026, 9, 26),
    DateTime(2026, 9, 30),
  );
  final lisbon = trip('lisbon', DateTime(2026, 10, 4), DateTime(2026, 10, 8));
  final porto = trip('porto', DateTime(2026, 10, 6), DateTime(2026, 10, 7));
  final iceland = trip('iceland', DateTime(2027, 2, 1), DateTime(2027, 2, 9));

  group('quickCaptureTarget', () {
    test('captures into the one trip running today', () {
      final target = quickCaptureTarget([montenegro, lisbon], today: today);

      expect(target, isA<CaptureInto>());
      expect((target as CaptureInto).trip, lisbon);
    });

    test('lets the traveler choose among several running trips first', () {
      final target = quickCaptureTarget([
        montenegro,
        lisbon,
        porto,
        iceland,
      ], today: today);

      expect([for (final trip in (target as ChooseTrip).trips) trip.id], [
        'porto',
        'lisbon',
        'iceland',
        'montenegro',
      ]);
    });

    test('lets the traveler choose among all trips without a running one', () {
      final target = quickCaptureTarget([
        montenegro,
        iceland,
      ], today: DateTime(2026, 12, 24));

      expect([for (final trip in (target as ChooseTrip).trips) trip.id], [
        'iceland',
        'montenegro',
      ]);
    });

    test('has no target without trips', () {
      expect(quickCaptureTarget(const [], today: today), isA<NoTrip>());
    });
  });

  group('buildQuickEntry', () {
    final kotor = GeoPoint(latitude: 42.4247, longitude: 18.7712);

    test('has the local time, the location and the nearest place name', () {
      final entry = buildQuickEntry(
        id: 'e1',
        trip: lisbon,
        localTime: today,
        location: kotor,
        nearestPlace: Place(
          name: 'Kotor',
          country: 'Montenegro',
          countryCode: 'ME',
          location: kotor,
          population: 13510,
        ),
      );

      expect(entry.id, 'e1');
      expect(entry.tripId, 'lisbon');
      expect(entry.localDateTime, DateTime.utc(2026, 10, 6, 9, 41));
      expect(entry.location, kotor);
      expect(entry.placeName, 'Kotor');
    });

    test('has only the location without a nearest place', () {
      final entry = buildQuickEntry(
        id: 'e1',
        trip: lisbon,
        localTime: today,
        location: kotor,
        nearestPlace: null,
      );

      expect(entry.location, kotor);
      expect(entry.placeName, isNull);
    });
  });
}
