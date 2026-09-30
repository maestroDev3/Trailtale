import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _main = 'android/app/src/main';

/// The `path` attributes of all `<include>` elements in [xml].
List<String> _includes(String xml) =>
    RegExp(r'<include\s+domain="root"\s+path="([^"]+)"')
        .allMatches(xml)
        .map((match) => match.group(1) ?? '')
        .toList();

void main() {
  group('Android Auto Backup', () {
    final manifest = File('$_main/AndroidManifest.xml').readAsStringSync();

    test('is configured in the manifest', () {
      expect(
        manifest,
        contains('android:fullBackupContent="@xml/backup_rules"'),
      );
      expect(
        manifest,
        contains('android:dataExtractionRules="@xml/data_extraction_rules"'),
      );
    });

    test('backs up only trips and entries (Android 11 and older)', () {
      final rules = File('$_main/res/xml/backup_rules.xml').readAsStringSync();

      expect(_includes(rules), [
        'app_flutter/trips.json',
        'app_flutter/entries.json',
      ]);
    });

    test('backs up only trips and entries (Android 12 and newer)', () {
      final rules = File('$_main/res/xml/data_extraction_rules.xml')
          .readAsStringSync();

      expect(rules, contains('<cloud-backup'));
      expect(rules, contains('<device-transfer'));
      expect(_includes(rules), [
        'app_flutter/trips.json',
        'app_flutter/entries.json',
        'app_flutter/trips.json',
        'app_flutter/entries.json',
      ]);
    });
  });
}
