import 'package:trailtale/domain/clock.dart';
import 'package:trailtale/domain/id_generator.dart';
import 'package:trailtale/domain/photo_gallery.dart';
import 'package:trailtale/ui/app_services.dart';
import 'package:trailtale/ui/widgets/picker_map.dart';

import 'fake_backup.dart';
import 'fake_entry_repository.dart';
import 'fake_photo_gallery.dart';
import 'fake_photo_library.dart';
import 'fake_photo_metadata_reader.dart';
import 'fake_position_service.dart';
import 'fake_photo_picker.dart';
import 'fake_quick_capture_requests.dart';
import 'fake_shared_photo_requests.dart';
import 'fake_place_directory.dart';
import 'fake_slideshow_writer.dart';
import 'fake_temporary_files.dart';
import 'fake_trip_repository.dart';
import 'fake_voice_recorder.dart';
import 'placeholder_picker_map.dart';
import 'placeholder_trip_map.dart';

/// Fixed "now" for widget tests: Tuesday, September 29, 2026, 10:30 local.
final testNow = DateTime(2026, 9, 29, 10, 30);

/// [AppServices] backed by fakes; pass fakes to inspect them afterwards.
AppServices testServices({
  FakeTripRepository? trips,
  FakeEntryRepository? entries,
  Clock? clock,
  IdGenerator? newId,
  FakePhotoLibrary? photoLibrary,
  FakePhotoPicker? photoPicker,
  FakePhotoMetadataReader? photoMetadataReader,
  FakePhotoGallery? photoGallery,
  FakeBackupService? backupService,
  FakeFileSharer? fileSharer,
  FakeDocumentPicker? documentPicker,
  FakePlaceDirectory? placeDirectory,
  FakePositionService? positionService,
  PickerMapBuilder? pickerMap,
  FakeTemporaryFiles? temporaryFiles,
  FakeSlideshowWriter? slideshowWriter,
  FakeQuickCaptureRequests? quickCaptureRequests,
  FakeSharedPhotoRequests? sharedPhotoRequests,
  FakeVoiceRecorder? voiceRecorder,
}) {
  return AppServices(
    tripRepository: trips ?? FakeTripRepository(),
    entryRepository: entries ?? FakeEntryRepository(),
    newId: newId ?? () => 'id',
    clock: clock ?? () => testNow,
    photoLibrary: photoLibrary ?? FakePhotoLibrary(),
    photoPicker: photoPicker ?? FakePhotoPicker(),
    photoMetadataReader: photoMetadataReader ?? FakePhotoMetadataReader(),
    // Without gallery access the system photo picker is used, so tests that
    // only care about picked files can keep using [FakePhotoPicker].
    photoGallery:
        photoGallery ?? FakePhotoGallery(access: GalleryAccess.denied),
    backupService: backupService ?? FakeBackupService(),
    fileSharer: fileSharer ?? FakeFileSharer(),
    temporaryFiles: temporaryFiles ?? FakeTemporaryFiles(),
    slideshowWriter: slideshowWriter ?? FakeSlideshowWriter(),
    documentPicker: documentPicker ?? FakeDocumentPicker(),
    tripMap: PlaceholderTripMap.new,
    pickerMap: pickerMap ?? placeholderPickerMap(),
    placeDirectory: placeDirectory ?? FakePlaceDirectory(),
    positionService: positionService ?? FakePositionService(),
    quickCaptureRequests: quickCaptureRequests ?? FakeQuickCaptureRequests(),
    sharedPhotoRequests: sharedPhotoRequests ?? FakeSharedPhotoRequests(),
    voiceRecorder: voiceRecorder ?? FakeVoiceRecorder(),
  );
}
