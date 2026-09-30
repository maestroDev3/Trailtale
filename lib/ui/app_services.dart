import '../domain/clock.dart';
import '../domain/entry_repository.dart';
import '../domain/id_generator.dart';
import '../domain/media_location_access.dart';
import '../domain/photo_library.dart';
import '../domain/photo_metadata.dart';
import '../domain/photo_picker.dart';
import '../domain/trip_repository.dart';

/// Everything the screens need from outside the UI. Created once in
/// `main.dart` and passed down, so tests can swap in fakes.
class AppServices {
  const AppServices({
    required this.tripRepository,
    required this.entryRepository,
    required this.newId,
    required this.photoLibrary,
    required this.photoPicker,
    required this.photoMetadataReader,
    required this.mediaLocationAccess,
    this.clock = DateTime.now,
  });

  final TripRepository tripRepository;
  final EntryRepository entryRepository;
  final IdGenerator newId;
  final PhotoLibrary photoLibrary;
  final PhotoPicker photoPicker;
  final PhotoMetadataReader photoMetadataReader;
  final MediaLocationAccess mediaLocationAccess;
  final Clock clock;
}
