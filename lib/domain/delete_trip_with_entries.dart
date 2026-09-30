import 'entry_repository.dart';
import 'trip_repository.dart';

/// Deletes a trip together with its entries. Entries go first, so an
/// interruption never leaves entries without their trip.
Future<void> deleteTripWithEntries({
  required TripRepository tripRepository,
  required EntryRepository entryRepository,
  required String tripId,
}) async {
  await entryRepository.deleteEntriesOfTrip(tripId);
  await tripRepository.deleteTrip(tripId);
}
