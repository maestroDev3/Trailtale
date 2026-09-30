import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final manifest = File('android/app/src/main/AndroidManifest.xml')
      .readAsStringSync();

  List<String> permissions() =>
      RegExp(r'uses-permission\s+android:name="([^"]+)"')
          .allMatches(manifest)
          .map((match) => match.group(1) ?? '')
          .toList();

  group('AndroidManifest', () {
    test('declares media location access for GPS data in photos', () {
      expect(
        permissions(),
        contains('android.permission.ACCESS_MEDIA_LOCATION'),
      );
    });

    test('declares internet access for map tiles', () {
      expect(permissions(), contains('android.permission.INTERNET'));
    });

    test('declares no background location', () {
      expect(
        permissions(),
        isNot(contains('android.permission.ACCESS_BACKGROUND_LOCATION')),
      );
    });
  });
}
