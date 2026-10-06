import 'clock.dart';
import 'entry_tag.dart';
import 'geo_point.dart';

/// Marks a `copyWith` argument that was not passed, so `null` can mean
/// "remove the value".
const Object _unchanged = Object();

/// Something the traveler recorded at a point in time during a trip.
///
/// [time] is the UTC instant; [utcOffset] is the local offset at the place
/// where the entry was recorded, so the entry keeps its local wall-clock time
/// and day even when viewed in another time zone.
class Entry {
  /// Creates a validated entry; throws [ArgumentError] if it has neither a
  /// note, a place name, a location, photos nor tags, or if a photo path is
  /// blank or absolute.
  factory Entry({
    required String id,
    required String tripId,
    required DateTime time,
    required Duration utcOffset,
    String note = '',
    String? placeName,
    GeoPoint? location,
    List<String> photoPaths = const [],
    Set<EntryTag> tags = const {},
    String? voiceNotePath,
    Duration? voiceNoteLength,
  }) {
    for (final path in photoPaths) {
      if (path.trim().isEmpty || path.startsWith('/')) {
        throw ArgumentError.value(path, 'photoPaths', 'must be relative');
      }
    }
    final trimmedNote = note.trim();
    final trimmedPlace = placeName?.trim();
    final place = trimmedPlace == null || trimmedPlace.isEmpty
        ? null
        : trimmedPlace;
    if (trimmedNote.isEmpty &&
        place == null &&
        location == null &&
        photoPaths.isEmpty &&
        tags.isEmpty) {
      throw ArgumentError(
        'An entry needs a note, a place name, a location, photos or tags',
      );
    }
    return Entry._(
      id: id,
      tripId: tripId,
      time: time.toUtc(),
      utcOffset: utcOffset,
      note: trimmedNote,
      placeName: place,
      location: location,
      photoPaths: List.unmodifiable(photoPaths),
      tags: Set.unmodifiable({
        for (final tag in EntryTag.values)
          if (tags.contains(tag)) tag,
      }),
    );
  }

  /// Creates an entry from a local [localTime], keeping its UTC instant and
  /// its time zone offset.
  factory Entry.atLocalTime({
    required String id,
    required String tripId,
    required DateTime localTime,
    String note = '',
    String? placeName,
    GeoPoint? location,
    List<String> photoPaths = const [],
    Set<EntryTag> tags = const {},
  }) {
    return Entry(
      id: id,
      tripId: tripId,
      time: localTime.toUtc(),
      utcOffset: localTime.timeZoneOffset,
      note: note,
      placeName: placeName,
      location: location,
      photoPaths: photoPaths,
      tags: tags,
    );
  }

  const Entry._({
    required this.id,
    required this.tripId,
    required this.time,
    required this.utcOffset,
    required this.note,
    required this.placeName,
    required this.location,
    required this.photoPaths,
    required this.tags,
  });

  final String id;
  final String tripId;
  final DateTime time;
  final Duration utcOffset;
  final String note;
  final String? placeName;
  final GeoPoint? location;

  /// Relative paths of the entry's photos in the photo library, in order.
  final List<String> photoPaths;

  /// What kind of moment this was (food, view, …), in [EntryTag] order.
  final Set<EntryTag> tags;

  /// Relative path of the entry's voice note, if any.
  String? get voiceNotePath => null;

  /// Length of the voice note.
  Duration? get voiceNoteLength => null;

  /// Wall-clock time where the entry was recorded. The value is flagged as
  /// UTC only so that its fields are not converted again; read its fields.
  DateTime get localDateTime => time.add(utcOffset);

  /// Local calendar day of the entry, used to group entries into trip days.
  DateTime get localDay => dayOf(localDateTime);

  /// Returns a new entry with the given fields replaced; passing `null` for
  /// [placeName] or [location] removes them. Validated like a new entry.
  Entry copyWith({
    DateTime? time,
    Duration? utcOffset,
    String? note,
    Object? placeName = _unchanged,
    Object? location = _unchanged,
    List<String>? photoPaths,
    Set<EntryTag>? tags,
    Object? voiceNotePath = _unchanged,
    Duration? voiceNoteLength,
  }) {
    return Entry(
      id: id,
      tripId: tripId,
      time: time ?? this.time,
      utcOffset: utcOffset ?? this.utcOffset,
      note: note ?? this.note,
      placeName: identical(placeName, _unchanged)
          ? this.placeName
          : placeName as String?,
      location: identical(location, _unchanged)
          ? this.location
          : location as GeoPoint?,
      photoPaths: photoPaths ?? this.photoPaths,
      tags: tags ?? this.tags,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Entry &&
      other.id == id &&
      other.tripId == tripId &&
      other.time == time &&
      other.utcOffset == utcOffset &&
      other.note == note &&
      other.placeName == placeName &&
      other.location == location &&
      _sameList(other.photoPaths, photoPaths) &&
      other.tags.length == tags.length &&
      other.tags.containsAll(tags);

  @override
  int get hashCode => Object.hash(
    id,
    tripId,
    time,
    utcOffset,
    note,
    placeName,
    location,
    Object.hashAll(photoPaths),
    Object.hashAll(tags),
  );

  @override
  String toString() => 'Entry($id, $time $utcOffset, $note, $placeName)';
}

bool _sameList(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// Orders entries by time, entries at the same instant by id, leaving the
/// input unchanged.
List<Entry> sortEntriesChronologically(Iterable<Entry> entries) {
  return entries.toList()..sort((a, b) {
    final byTime = a.time.compareTo(b.time);
    return byTime != 0 ? byTime : a.id.compareTo(b.id);
  });
}
