import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('lib/domain', () {
    test('exists and contains Dart files', () {
      final files = _domainFiles();

      expect(files, isNotEmpty);
    });

    test('does not import Flutter', () {
      final flutterImport = RegExp(r'''import\s+['"]package:flutter''');
      final offenders = _domainFiles()
          .where((file) => flutterImport.hasMatch(file.readAsStringSync()))
          .map((file) => file.path)
          .toList();

      expect(offenders, isEmpty);
    });
  });
}

List<File> _domainFiles() {
  final directory = Directory('lib/domain');
  if (!directory.existsSync()) return const [];
  return directory
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'))
      .toList();
}
