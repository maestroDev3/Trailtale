import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';

import '../domain/backup_service.dart';
import '../domain/clock.dart';

/// Backs up the documents directory's trips, entries, photos and voice notes
/// into one ZIP file: `manifest.json`, `trips.json`, `entries.json`,
/// `photos/…`, `voice/…`.
class ZipBackupService implements BackupService {
  ZipBackupService({
    required this.documents,
    required this.temporary,
    this.clock = DateTime.now,
  });

  /// Version of the backup layout; bumped when it changes incompatibly.
  static const format = 1;

  static const _dataFiles = {'trips.json': 'trips', 'entries.json': 'entries'};
  /// Folders of media files and their count in the manifest.
  static const _mediaFolders = {'photos': 'photos', 'voice': 'voiceNotes'};
  static const _manifest = 'manifest.json';

  final Directory documents;
  final Directory temporary;
  final Clock clock;

  @override
  Future<File> createBackup() async {
    final now = clock().toUtc();
    final files = <ArchiveFile>[];
    final counts = <String, int>{};
    for (final MapEntry(key: name, value: listKey) in _dataFiles.entries) {
      final file = File('${documents.path}/$name');
      counts[listKey] = 0;
      if (!file.existsSync()) continue;
      final bytes = await file.readAsBytes();
      counts[listKey] = _countItems(bytes, listKey);
      files.add(ArchiveFile.bytes(name, bytes));
    }
    for (final MapEntry(key: folder, value: countKey) in _mediaFolders.entries) {
      final media = _filesIn(folder);
      counts[countKey] = media.length;
      for (final file in media) {
        final relative = file.path.substring(documents.path.length + 1);
        files.add(ArchiveFile.bytes(relative, await file.readAsBytes()));
      }
    }
    final manifest = {
      'format': format,
      'createdAt': now.toIso8601String(),
      'trips': counts['trips'],
      'entries': counts['entries'],
      'photos': counts['photos'],
      'voiceNotes': counts['voiceNotes'],
    };
    final archive = Archive()
      ..addFile(ArchiveFile.string(_manifest, jsonEncode(manifest)));
    files.forEach(archive.addFile);

    final date = now.toIso8601String().substring(0, 10);
    final target = File('${temporary.path}/trailtale-backup-$date.zip');
    await target.parent.create(recursive: true);
    await target.writeAsBytes(ZipEncoder().encodeBytes(archive), flush: true);
    return target;
  }

  @override
  Future<void> restoreBackup(File backup) async {
    final archive = await _readArchive(backup);
    final staging = Directory('${documents.path}.restore');
    if (staging.existsSync()) await staging.delete(recursive: true);
    await staging.create(recursive: true);
    try {
      for (final file in archive.files.where((file) => file.isFile)) {
        if (file.name == _manifest) continue;
        final target = File('${staging.path}/${file.name}');
        await target.parent.create(recursive: true);
        await target.writeAsBytes(file.content, flush: true);
      }
      await _swapIn(staging);
    } finally {
      if (staging.existsSync()) await staging.delete(recursive: true);
    }
  }

  /// Reads and checks the archive before anything on disk is changed.
  Future<Archive> _readArchive(File backup) async {
    final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(await backup.readAsBytes());
    } on Object catch (error) {
      throw InvalidBackupException('not a ZIP file ($error)');
    }
    final manifestFile = archive.findFile(_manifest);
    if (manifestFile == null) {
      throw const InvalidBackupException('no manifest.json');
    }
    final Object? manifest;
    try {
      manifest = jsonDecode(utf8.decode(manifestFile.content));
    } on FormatException catch (error) {
      throw InvalidBackupException('unreadable manifest ($error)');
    }
    if (manifest is! Map<String, dynamic> || manifest['format'] != format) {
      throw const InvalidBackupException('unsupported backup format');
    }
    for (final file in archive.files.where((file) => file.isFile)) {
      if (!_isAllowedPath(file.name)) {
        throw InvalidBackupException('unexpected file ${file.name}');
      }
    }
    return archive;
  }

  bool _isAllowedPath(String name) {
    if (name == _manifest || _dataFiles.containsKey(name)) return true;
    final segments = name.split('/');
    return segments.length > 1 &&
        _mediaFolders.containsKey(segments.first) &&
        !segments.any((segment) => segment.isEmpty || segment == '..');
  }

  /// Replaces trips, entries and media in [documents] with the ones in
  /// [staging]; the previous ones are kept aside until the swap succeeded.
  Future<void> _swapIn(Directory staging) async {
    final previous = Directory('${documents.path}.previous');
    if (previous.existsSync()) await previous.delete(recursive: true);
    await previous.create(recursive: true);
    final managed = [..._dataFiles.keys, ..._mediaFolders.keys];
    for (final name in managed) {
      final current = '${documents.path}/$name';
      if (FileSystemEntity.typeSync(current) != FileSystemEntityType.notFound) {
        await _entity(current).rename('${previous.path}/$name');
      }
    }
    await documents.create(recursive: true);
    for (final name in managed) {
      final restored = '${staging.path}/$name';
      if (FileSystemEntity.typeSync(restored) !=
          FileSystemEntityType.notFound) {
        await _entity(restored).rename('${documents.path}/$name');
      }
    }
    await previous.delete(recursive: true);
  }

  FileSystemEntity _entity(String path) =>
      FileSystemEntity.isDirectorySync(path) ? Directory(path) : File(path);

  List<File> _filesIn(String folder) {
    final directory = Directory('${documents.path}/$folder');
    if (!directory.existsSync()) return const [];
    return directory.listSync(recursive: true).whereType<File>().toList()
      ..sort((a, b) => a.path.compareTo(b.path));
  }

  static int _countItems(List<int> bytes, String listKey) {
    try {
      final json = jsonDecode(utf8.decode(bytes));
      return json is Map<String, dynamic> && json[listKey] is List
          ? (json[listKey] as List).length
          : 0;
    } on FormatException {
      return 0;
    }
  }
}
