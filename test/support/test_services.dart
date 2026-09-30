import 'package:trailtale/domain/clock.dart';
import 'package:trailtale/domain/id_generator.dart';
import 'package:trailtale/ui/app_services.dart';

import 'fake_backup.dart';
import 'fake_entry_repository.dart';
import 'fake_media_location_access.dart';
import 'fake_photo_library.dart';
import 'fake_photo_metadata_reader.dart';
import 'fake_photo_picker.dart';
import 'fake_trip_repository.dart';
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
  FakeMediaLocationAccess? mediaLocationAccess,
  FakeBackupService? backupService,
  FakeFileSharer? fileSharer,
  FakeDocumentPicker? documentPicker,
}) {
  return AppServices(
    tripRepository: trips ?? FakeTripRepository(),
    entryRepository: entries ?? FakeEntryRepository(),
    newId: newId ?? () => 'id',
    clock: clock ?? () => testNow,
    photoLibrary: photoLibrary ?? FakePhotoLibrary(),
    photoPicker: photoPicker ?? FakePhotoPicker(),
    photoMetadataReader: photoMetadataReader ?? FakePhotoMetadataReader(),
    mediaLocationAccess: mediaLocationAccess ?? FakeMediaLocationAccess(),
    backupService: backupService ?? FakeBackupService(),
    fileSharer: fileSharer ?? FakeFileSharer(),
    documentPicker: documentPicker ?? FakeDocumentPicker(),
    tripMap: PlaceholderTripMap.new,
  );
}
