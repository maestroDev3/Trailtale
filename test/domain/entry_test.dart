import 'package:flutter_test/flutter_test.dart';
import 'package:trailtale/domain/entry.dart';
import 'package:trailtale/domain/entry_tag.dart';
import 'package:trailtale/domain/geo_point.dart';

void main() {
  const plusTwo = Duration(hours: 2);

  Entry entry({
    String id = 'entry-1',
    DateTime? time,
    Duration utcOffset = plusTwo,
    String note = 'Pastéis de nata',
    String? placeName = 'Belém',
    GeoPoint? location,
    List<String> photoPaths = const [],
    Set<EntryTag> tags = const {},
  }) {
    return Entry(
      id: id,
      tripId: 'lisbon',
      time: time ?? DateTime.utc(2026, 5, 1, 8, 30),
      utcOffset: utcOffset,
      note: note,
      placeName: placeName,
      location: location,
      photoPaths: photoPaths,
      tags: tags,
    );
  }

  group('Entry', () {
    test('stores the time in UTC', () {
      final result = entry(time: DateTime.utc(2026, 5, 1, 8, 30));

      expect(result.time, DateTime.utc(2026, 5, 1, 8, 30));
      expect(result.time.isUtc, isTrue);
    });

    test('converts a non-UTC time to UTC', () {
      final local = DateTime(2026, 5, 1, 10, 30);

      expect(entry(time: local).time, local.toUtc());
    });

    test('returns the wall-clock time at the stored offset', () {
      final result = entry(time: DateTime.utc(2026, 5, 1, 8, 30));

      final local = result.localDateTime;
      expect(
        [local.year, local.month, local.day, local.hour, local.minute],
        [2026, 5, 1, 10, 30],
      );
    });

    test('keeps a late evening entry on its local day', () {
      final result = entry(time: DateTime.utc(2026, 5, 1, 21, 30));

      expect(result.localDay, DateTime.utc(2026, 5, 1));
    });

    test('puts an entry after local midnight on the next day', () {
      final result = entry(time: DateTime.utc(2026, 4, 30, 22, 30));

      expect(result.localDay, DateTime.utc(2026, 5, 1));
    });

    test('trims the note and treats an empty place name as missing', () {
      final result = entry(note: '  Tram 28  ', placeName: '  ');

      expect(result.note, 'Tram 28');
      expect(result.placeName, isNull);
    });

    test('requires a note, a place name or a location', () {
      expect(() => entry(note: ' ', placeName: null), throwsArgumentError);
      expect(entry(note: '', placeName: 'Alfama').placeName, 'Alfama');
      expect(
        entry(
          note: '',
          placeName: null,
          location: GeoPoint(latitude: 38.7, longitude: -9.1),
        ).location,
        isNotNull,
      );
    });

    test('is equal to an entry with the same values', () {
      expect(entry(), entry());
      expect(entry().hashCode, entry().hashCode);
      expect(entry(), isNot(entry(note: 'Other')));
    });
  });

  group('Entry photos', () {
    test('has no photos by default', () {
      expect(entry().photoPaths, isEmpty);
    });

    test('keeps photo paths in order and does not allow changing them', () {
      final result = entry(photoPaths: ['photos/b.jpg', 'photos/a.jpg']);

      expect(result.photoPaths, ['photos/b.jpg', 'photos/a.jpg']);
      expect(
        () => result.photoPaths.add('photos/c.jpg'),
        throwsUnsupportedError,
      );
    });

    test('is valid with only photos', () {
      final result = entry(
        note: '',
        placeName: null,
        photoPaths: ['photos/a.jpg'],
      );

      expect(result.photoPaths, ['photos/a.jpg']);
    });

    test('rejects blank and absolute photo paths', () {
      expect(() => entry(photoPaths: [' ']), throwsArgumentError);
      expect(() => entry(photoPaths: ['/sdcard/a.jpg']), throwsArgumentError);
    });

    test('compares photo paths by value', () {
      expect(
        entry(photoPaths: ['photos/a.jpg']),
        entry(photoPaths: ['photos/a.jpg']),
      );
      expect(
        entry(photoPaths: ['photos/a.jpg']).hashCode,
        entry(photoPaths: ['photos/a.jpg']).hashCode,
      );
      expect(
        entry(photoPaths: ['photos/a.jpg']),
        isNot(entry(photoPaths: ['photos/b.jpg'])),
      );
    });

    test('can be changed with copyWith', () {
      final changed = entry().copyWith(photoPaths: ['photos/a.jpg']);

      expect(changed.photoPaths, ['photos/a.jpg']);
      expect(changed.note, 'Pastéis de nata');
    });
  });

  group('Entry.atLocalTime', () {
    test('stores the UTC instant and the local offset', () {
      final local = DateTime(2026, 5, 1, 10, 30);

      final result = Entry.atLocalTime(
        id: 'entry-1',
        tripId: 'lisbon',
        localTime: local,
        note: 'Coffee',
      );

      expect(result.time, local.toUtc());
      expect(result.utcOffset, local.timeZoneOffset);
      expect(result.localDateTime.hour, 10);
    });
  });

  group('Entry.copyWith', () {
    test('returns a new entry with the changed fields', () {
      final original = entry();

      final changed = original.copyWith(note: 'Sardines');

      expect(changed.note, 'Sardines');
      expect(changed.placeName, 'Belém');
      expect(original.note, 'Pastéis de nata');
    });

    test('can remove the place name and location', () {
      final original = entry(
        location: GeoPoint(latitude: 38.7, longitude: -9.1),
      );

      final changed = original.copyWith(placeName: null, location: null);

      expect(changed.placeName, isNull);
      expect(changed.location, isNull);
    });

    test('validates the changed values', () {
      expect(
        () => entry().copyWith(note: '', placeName: null),
        throwsArgumentError,
      );
    });
  });

  group('sortEntriesChronologically', () {
    test('orders by time and ties by id without changing the input', () {
      final late = entry(id: 'c', time: DateTime.utc(2026, 5, 2, 9));
      final earlyB = entry(id: 'b', time: DateTime.utc(2026, 5, 1, 9));
      final earlyA = entry(id: 'a', time: DateTime.utc(2026, 5, 1, 9));
      final input = [late, earlyB, earlyA];

      expect(sortEntriesChronologically(input), [earlyA, earlyB, late]);
      expect(input, [late, earlyB, earlyA]);
    });
  });

  group('Entry tags', () {
    test('accepts an entry with only a tag', () {
      final tagged = entry(note: '', placeName: null, tags: {EntryTag.food});

      expect(tagged.tags, {EntryTag.food});
      expect(() => entry(note: '', placeName: null), throwsArgumentError);
    });

    test('keeps tags in their order; copyWith replaces them', () {
      final tagged = entry(tags: {EntryTag.transport, EntryTag.food});

      expect(tagged.tags.toList(), [EntryTag.food, EntryTag.transport]);
      expect(tagged.copyWith(tags: {EntryTag.view}).tags, {EntryTag.view});
      expect(tagged.copyWith(note: 'Other').tags, tagged.tags);
    });

    test('is not equal to an entry with other tags', () {
      expect(entry(tags: {EntryTag.food}), isNot(entry()));
      expect(entry(tags: {EntryTag.food}), entry(tags: {EntryTag.food}));
    });
  });
}
