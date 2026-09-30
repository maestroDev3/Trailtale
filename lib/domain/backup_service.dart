import 'dart:io';

/// Creates and restores complete backups (trips, entries and photos), so a
/// lost or new phone does not mean lost memories.
abstract interface class BackupService {
  /// Writes a backup file and returns it, e.g. to share it.
  Future<File> createBackup();

  /// Replaces all current data with the content of [backup]; throws
  /// [InvalidBackupException] (and changes nothing) if it is not a usable
  /// Trailtale backup.
  Future<void> restoreBackup(File backup);
}

/// The file is not a Trailtale backup this version of the app can restore.
class InvalidBackupException implements Exception {
  const InvalidBackupException(this.reason);

  final String reason;

  @override
  String toString() => 'InvalidBackupException: $reason';
}
