import 'entry.dart';
import 'geo_point.dart';
import 'photo_metadata.dart';
import 'place.dart';

/// A photo another app shared to Trailtale, with what it says about itself.
class SharedPhoto {
  const SharedPhoto({required this.path, required this.metadata});

  /// Where the shared copy lies (absolute path).
  final String path;
  final PhotoMetadata metadata;
}

/// Photos taken close together – one suggested entry.
class PhotoGroup {
  const PhotoGroup({
    required this.photoPaths,
    required this.takenAt,
    required this.utcOffset,
    required this.location,
  });

  final List<String> photoPaths;

  /// Local wall-clock time of the earliest photo.
  final DateTime takenAt;

  /// Offset recorded with [takenAt]; `null` means the device's offset.
  final Duration? utcOffset;
  final GeoPoint? location;
}

/// A photo taken more than this after the previous one starts a new entry.
const maxGroupGap = Duration(hours: 2);

/// A photo farther than this from its group's place starts a new entry.
const maxGroupDistanceMeters = 1000.0;

/// Groups shared photos into suggested entries, in time order: a photo
/// joins the previous one's group unless it was taken more than
/// [maxGroupGap] later or more than [maxGroupDistanceMeters] away. Photos
/// without capture time form one last group at [now].
List<PhotoGroup> groupSharedPhotos(
  List<SharedPhoto> photos, {
  required DateTime now,
}) {
  final timed = [
    for (final photo in photos)
      if (photo.metadata.takenAt != null) photo,
  ]..sort((a, b) => _timeOf(a).compareTo(_timeOf(b)));
  final untimed = [
    for (final photo in photos)
      if (photo.metadata.takenAt == null) photo,
  ];
  final groups = <List<SharedPhoto>>[];
  for (final photo in timed) {
    final current = groups.lastOrNull;
    if (current == null || !_belongsTo(photo, current)) {
      groups.add([photo]);
    } else {
      current.add(photo);
    }
  }
  return [
    for (final group in groups)
      _group(
        group,
        takenAt: _timeOf(group.first),
        utcOffset: group.first.metadata.utcOffset,
      ),
    if (untimed.isNotEmpty) _group(untimed, takenAt: now, utcOffset: null),
  ];
}

DateTime _timeOf(SharedPhoto photo) =>
    photo.metadata.takenAt ?? DateTime.utc(0);

GeoPoint? _locationOf(List<SharedPhoto> photos) => photos
    .map((photo) => photo.metadata.location)
    .whereType<GeoPoint>()
    .firstOrNull;

bool _belongsTo(SharedPhoto photo, List<SharedPhoto> group) {
  if (_timeOf(photo).difference(_timeOf(group.last)) > maxGroupGap) {
    return false;
  }
  final (here, there) = (photo.metadata.location, _locationOf(group));
  if (here == null || there == null) return true;
  return here.distanceTo(there) <= maxGroupDistanceMeters;
}

PhotoGroup _group(
  List<SharedPhoto> photos, {
  required DateTime takenAt,
  required Duration? utcOffset,
}) => PhotoGroup(
  photoPaths: [for (final photo in photos) photo.path],
  takenAt: takenAt,
  utcOffset: utcOffset,
  location: _locationOf(photos),
);

/// The entry for [group] with the imported [photoPaths].
Entry entryFromGroup(
  PhotoGroup group, {
  required String id,
  required String tripId,
  required List<String> photoPaths,
  required Place? nearestPlace,
}) {
  final takenAt = group.takenAt;
  return switch (group.utcOffset) {
    // The photo's wall-clock time at its own offset, like the entry form.
    final offset? => Entry(
      id: id,
      tripId: tripId,
      time: DateTime.utc(
        takenAt.year,
        takenAt.month,
        takenAt.day,
        takenAt.hour,
        takenAt.minute,
        takenAt.second,
      ).subtract(offset),
      utcOffset: offset,
      placeName: nearestPlace?.name,
      location: group.location,
      photoPaths: photoPaths,
    ),
    null => Entry.atLocalTime(
      id: id,
      tripId: tripId,
      localTime: takenAt,
      placeName: nearestPlace?.name,
      location: group.location,
      photoPaths: photoPaths,
    ),
  };
}
