import '../domain/backup_service.dart';
import '../domain/clock.dart';
import '../domain/document_picker.dart';
import '../domain/entry_repository.dart';
import '../domain/file_sharer.dart';
import '../domain/id_generator.dart';
import '../domain/photo_gallery.dart';
import '../domain/photo_library.dart';
import '../domain/photo_metadata.dart';
import '../domain/photo_picker.dart';
import '../domain/place.dart';
import '../domain/position_service.dart';
import '../domain/trip_repository.dart';
import 'widgets/picker_map.dart';
import 'widgets/trip_map_view.dart';

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
    required this.photoGallery,
    required this.backupService,
    required this.fileSharer,
    required this.documentPicker,
    required this.tripMap,
    required this.pickerMap,
    required this.placeDirectory,
    required this.positionService,
    this.clock = DateTime.now,
  });

  final TripRepository tripRepository;
  final EntryRepository entryRepository;
  final IdGenerator newId;
  final PhotoLibrary photoLibrary;
  final PhotoPicker photoPicker;
  final PhotoMetadataReader photoMetadataReader;

  /// The phone's gallery; keeps the GPS position of photos. Without access,
  /// [photoPicker] (the system photo picker) is the fallback.
  final PhotoGallery photoGallery;
  final BackupService backupService;
  final FileSharer fileSharer;
  final DocumentPicker documentPicker;

  /// Builds the trip map (OpenStreetMap in the app, a placeholder in tests).
  final TripMapBuilder tripMap;

  /// Builds the map for picking a place (OpenStreetMap in the app, a
  /// placeholder in tests).
  final PickerMapBuilder pickerMap;

  /// The bundled city list for place suggestions and place names.
  final PlaceDirectory placeDirectory;

  /// The device's current position, only while the app is in use.
  final PositionService positionService;
  final Clock clock;
}
