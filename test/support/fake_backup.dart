import 'dart:io';

import 'package:trailtale/domain/backup_service.dart';
import 'package:trailtale/domain/document_picker.dart';
import 'package:trailtale/domain/file_sharer.dart';

/// [BackupService] for widget tests that records calls.
class FakeBackupService implements BackupService {
  FakeBackupService({this.restoreError});

  /// Thrown by [restoreBackup] if set.
  final Exception? restoreError;

  final backupFile = File('/cache/trailtale-backup-2026-09-29.zip');
  var createCount = 0;
  final restored = <File>[];

  @override
  Future<File> createBackup() async {
    createCount++;
    return backupFile;
  }

  @override
  Future<void> restoreBackup(File backup) async {
    if (restoreError case final error?) throw error;
    restored.add(backup);
  }
}

/// [FileSharer] for widget tests that records shared files.
class FakeFileSharer implements FileSharer {
  final shared = <File>[];

  @override
  Future<void> shareFile(File file, {required String subject}) async {
    shared.add(file);
  }
}

/// [DocumentPicker] for widget tests that returns [nextPick].
class FakeDocumentPicker implements DocumentPicker {
  FakeDocumentPicker([this.nextPick]);

  /// The file the next pick returns; `null` means "cancelled".
  File? nextPick;
  var pickCount = 0;

  @override
  Future<File?> pickBackup() async {
    pickCount++;
    return nextPick;
  }
}
