import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final manifest = File(
    'android/app/src/main/AndroidManifest.xml',
  ).readAsStringSync();

  List<String> permissions() => RegExp(r'uses-permission\s+android:name="([^"]+)"')
      .allMatches(manifest)
      .map((match) => match.group(1) ?? '')
      .toList();

  group('AndroidManifest', () {
    test('declares media location access for GPS data in photos', () {
      expect(permissions(), contains('android.permission.ACCESS_MEDIA_LOCATION'));
    });

    test('declares no permission without a decided purpose', () {
      expect(permissions(), isNot(contains('android.permission.INTERNET')));
      expect(
        permissions(),
        isNot(contains('android.permission.ACCESS_BACKGROUND_LOCATION')),
      );
    });
  });
}
