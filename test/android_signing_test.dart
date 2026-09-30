import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Release signing', () {
    final gradle = File('android/app/build.gradle.kts').readAsStringSync();
    final ci = File('.github/workflows/ci.yml').readAsStringSync();

    test('signs release builds with the key from the environment', () {
      for (final variable in [
        'ANDROID_KEYSTORE_PATH',
        'ANDROID_KEYSTORE_PASSWORD',
        'ANDROID_KEY_ALIAS',
        'ANDROID_KEY_PASSWORD',
      ]) {
        expect(gradle, contains('System.getenv("$variable")'));
      }
      expect(gradle, contains('create("release")'));
      expect(gradle, contains('signingConfigs.getByName("release")'));
    });

    test('CI restores the keystore from the repository secrets', () {
      expect(ci, contains(r'secrets.ANDROID_KEYSTORE_BASE64'));
      expect(ci, contains(r'secrets.ANDROID_KEYSTORE_PASSWORD'));
      expect(ci, contains(r'secrets.ANDROID_KEY_ALIAS'));
      expect(ci, contains(r'secrets.ANDROID_KEY_PASSWORD'));
    });

    test('CI gives every build a higher version code', () {
      expect(ci, contains(r'--build-number=${{ github.run_number }}'));
    });
  });
}
