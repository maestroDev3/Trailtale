import 'entry_repository.dart';
import 'photo_library.dart';
import 'trip_repository.dart';

/// Deletes a trip together with its entries and their photo files.
///
/// Entries go first, so an interruption never leaves entries without their
/// trip; photo files go last, so no entry ever points to a deleted file.
Future<void> deleteTripWithEntries({
  required TripRepository tripRepository,
  required EntryRepository entryRepository,
  required PhotoLibrary photoLibrary,
  required String tripId,
}) async {
  final entries = await entryRepository.deleteEntriesOfTrip(tripId);
  await tripRepository.deleteTrip(tripId);
  final photos = [for (final entry in entries) ...entry.photoPaths];
  if (photos.isNotEmpty) await photoLibrary.deletePhotos(photos);
}
