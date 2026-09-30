import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trailtale/data/zip_backup_service.dart';
import 'package:trailtale/domain/backup_service.dart';

void main() {
  late Directory root;
  late Directory documents;
  late Directory temporary;
  late ZipBackupService service;
  final now = DateTime.utc(2026, 9, 29, 10, 30);

  const tripsJson = '{"version":1,"trips":[{"id":"a"},{"id":"b"}]}';
  const entriesJson =
      '{"version":2,"entries":[{"id":"1"},{"id":"2"},{"id":"3"}]}';

  void write(Directory directory, String path, List<int> bytes) {
    File('${directory.path}/$path')
      ..createSync(recursive: true)
      ..writeAsBytesSync(bytes);
  }

  Map<String, List<int>> filesIn(Directory directory) => {
    for (final file in directory.listSync(recursive: true).whereType<File>())
      file.path.substring(directory.path.length + 1): file.readAsBytesSync(),
  };

  setUp(() {
    root = Directory.systemTemp.createTempSync('trailtale_backup_');
    documents = Directory('${root.path}/documents')..createSync();
    temporary = Directory('${root.path}/cache')..createSync();
    service = ZipBackupService(
      documents: documents,
      temporary: temporary,
      clock: () => now,
    );
    write(documents, 'trips.json', utf8.encode(tripsJson));
    write(documents, 'entries.json', utf8.encode(entriesJson));
    write(documents, 'photos/a.jpg', [1, 2, 3]);
    write(documents, 'photos/b.png', [4, 5]);
  });

  tearDown(() => root.deleteSync(recursive: true));

  group('ZipBackupService.createBackup', () {
    test('writes a dated ZIP with manifest, data files and photos', () async {
      final backup = await service.createBackup();

      expect(backup.uri.pathSegments.last, 'trailtale-backup-2026-09-29.zip');
      final archive = ZipDecoder().decodeBytes(backup.readAsBytesSync());
      expect(archive.files.map((file) => file.name).toSet(), {
        'manifest.json',
        'trips.json',
        'entries.json',
        'photos/a.jpg',
        'photos/b.png',
      });
      expect(archive.findFile('photos/a.jpg')?.content, [1, 2, 3]);
    });

    test('describes the backup in the manifest', () async {
      final backup = await service.createBackup();

      final archive = ZipDecoder().decodeBytes(backup.readAsBytesSync());
      final manifest = jsonDecode(
        utf8.decode(archive.findFile('manifest.json')?.content ?? const []),
      );
      expect(manifest, {
        'format': 1,
        'createdAt': '2026-09-29T10:30:00.000Z',
        'trips': 2,
        'entries': 3,
        'photos': 2,
      });
    });

    test('works for a fresh install without data files', () async {
      documents.deleteSync(recursive: true);
      documents.createSync();

      final backup = await service.createBackup();

      final archive = ZipDecoder().decodeBytes(backup.readAsBytesSync());
      expect(archive.files.map((file) => file.name), ['manifest.json']);
    });
  });

  group('ZipBackupService.restoreBackup', () {
    test('recreates all files byte for byte', () async {
      final expected = filesIn(documents);
      final backup = await service.createBackup();
      documents.deleteSync(recursive: true);
      documents.createSync();

      await service.restoreBackup(backup);

      expect(filesIn(documents), expected);
    });

    test('replaces the current data completely', () async {
      final backup = await service.createBackup();
      write(documents, 'photos/newer.jpg', [9]);
      write(documents, 'trips.json', utf8.encode('{"version":1,"trips":[]}'));

      await service.restoreBackup(backup);

      expect(File('${documents.path}/photos/newer.jpg').existsSync(), isFalse);
      expect(
        File('${documents.path}/trips.json').readAsStringSync(),
        tripsJson,
      );
    });

    test('refuses a file that is not a ZIP and keeps the data', () async {
      final before = filesIn(documents);
      final notZip = File('${temporary.path}/notes.txt')
        ..writeAsStringSync('hello');

      await expectLater(
        service.restoreBackup(notZip),
        throwsA(isA<InvalidBackupException>()),
      );
      expect(filesIn(documents), before);
    });

    test('refuses a ZIP without manifest', () async {
      final archive = Archive()
        ..addFile(ArchiveFile.bytes('trips.json', utf8.encode(tripsJson)));
      final zip = File('${temporary.path}/other.zip')
        ..writeAsBytesSync(ZipEncoder().encode(archive));

      await expectLater(
        service.restoreBackup(zip),
        throwsA(isA<InvalidBackupException>()),
      );
    });

    test('refuses a backup from a newer app version', () async {
      final archive = Archive()
        ..addFile(
          ArchiveFile.bytes(
            'manifest.json',
            utf8.encode('{"format":2,"createdAt":"2027-01-01T00:00:00.000Z"}'),
          ),
        );
      final zip = File('${temporary.path}/newer.zip')
        ..writeAsBytesSync(ZipEncoder().encode(archive));
      final before = filesIn(documents);

      await expectLater(
        service.restoreBackup(zip),
        throwsA(isA<InvalidBackupException>()),
      );
      expect(filesIn(documents), before);
    });

    test('refuses paths that would leave the documents directory', () async {
      final archive = Archive()
        ..addFile(
          ArchiveFile.bytes('manifest.json', utf8.encode('{"format":1}')),
        )
        ..addFile(ArchiveFile.bytes('../evil.txt', [1]));
      final zip = File('${temporary.path}/evil.zip')
        ..writeAsBytesSync(ZipEncoder().encode(archive));

      await expectLater(
        service.restoreBackup(zip),
        throwsA(isA<InvalidBackupException>()),
      );
      expect(File('${root.path}/evil.txt').existsSync(), isFalse);
    });
  });
}
