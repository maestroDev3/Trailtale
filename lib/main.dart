import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import 'data/asset_place_directory.dart';
import 'data/exif_photo_metadata_reader.dart';
import 'data/file_photo_library.dart';
import 'data/codec_photo_shrinker.dart';
import 'data/directory_temporary_files.dart';
import 'data/file_selector_document_picker.dart';
import 'data/geolocator_position_service.dart';
import 'data/image_picker_photo_picker.dart';
import 'data/pdf_slideshow_writer.dart';
import 'data/photo_manager_gallery.dart';
import 'data/json_file_entry_repository.dart';
import 'data/json_file_trip_repository.dart';
import 'data/random_id.dart';
import 'data/share_plus_file_sharer.dart';
import 'data/storage_locations.dart';
import 'data/zip_backup_service.dart';
import 'ui/app.dart';
import 'ui/app_services.dart';
import 'ui/licenses.dart';
import 'ui/theme.dart';
import 'ui/widgets/osm_picker_map.dart';
import 'ui/widgets/osm_trip_map.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  registerFontLicenses();
  registerPlaceDataLicense();
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
        photoGallery: PhotoManagerGallery(),
        backupService: ZipBackupService(
          documents: documents,
          temporary: temporary,
        ),
        fileSharer: SharePlusFileSharer(),
        slideshowWriter: PdfSlideshowWriter(
          shrinker: CodecPhotoShrinker(),
          loadFonts: () async => (
            display: await rootBundle.load(
              'assets/fonts/Fraunces-SemiBold.ttf',
            ),
            text: await rootBundle.load('assets/fonts/Manrope-Regular.ttf'),
            bold: await rootBundle.load('assets/fonts/Manrope-Bold.ttf'),
          ),
        ),
        temporaryFiles: DirectoryTemporaryFiles(
          Directory('${temporary.path}/shared'),
        ),
        documentPicker: FileSelectorDocumentPicker(),
        tripMap:
            ({
              required points,
              required onOpenEntry,
              interactive = true,
              fitPadding = 48,
              sharp = false,
            }) => OsmTripMap(
              points: points,
              onOpenEntry: onOpenEntry,
              interactive: interactive,
              fitPadding: fitPadding,
              sharp: sharp,
            ),
        pickerMap:
            ({
              required controller,
              required initialCenter,
              required initialZoom,
              required onCenterChanged,
            }) => OsmPickerMap(
              controller: controller,
              initialCenter: initialCenter,
              initialZoom: initialZoom,
              onCenterChanged: onCenterChanged,
            ),
        positionService: GeolocatorPositionService(),
        placeDirectory: AssetPlaceDirectory(
          loadBytes: () async =>
              (await rootBundle.load('assets/places/cities.tsv.gz')).buffer
                  .asUint8List(),
        ),
      ),
    ),
  );
}
