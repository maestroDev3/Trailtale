import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'data/exif_photo_metadata_reader.dart';
import 'data/file_photo_library.dart';
import 'data/file_selector_document_picker.dart';
import 'data/image_picker_photo_picker.dart';
import 'data/json_file_entry_repository.dart';
import 'data/json_file_trip_repository.dart';
import 'data/permission_handler_media_location_access.dart';
import 'data/random_id.dart';
import 'data/share_plus_file_sharer.dart';
import 'data/storage_locations.dart';
import 'data/zip_backup_service.dart';
import 'ui/app.dart';
import 'ui/app_services.dart';
import 'ui/theme.dart';
import 'ui/widgets/osm_trip_map.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  registerFontLicenses();
  final documents = await getApplicationDocumentsDirectory();
  final temporary = await getTemporaryDirectory();
  runApp(
    TrailtaleApp(
      services: AppServices(
        tripRepository: JsonFileTripRepository(tripsFile(documents)),
        entryRepository: JsonFileEntryRepository(entriesFile(documents)),
        newId: randomId,
        photoLibrary: FilePhotoLibrary(documents: documents, newId: randomId),
        photoPicker: ImagePickerPhotoPicker(),
        photoMetadataReader: ExifPhotoMetadataReader(),
        mediaLocationAccess: PermissionHandlerMediaLocationAccess(),
        backupService: ZipBackupService(
          documents: documents,
          temporary: temporary,
        ),
        fileSharer: SharePlusFileSharer(),
        documentPicker: FileSelectorDocumentPicker(),
        tripMap:
            ({required points, required onOpenEntry, interactive = true}) =>
                OsmTripMap(
                  points: points,
                  onOpenEntry: onOpenEntry,
                  interactive: interactive,
                ),
      ),
    ),
  );
}
