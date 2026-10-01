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

    test('declares read access to images incl. selected photos only', () {
      expect(
        permissions(),
        containsAll([
          'android.permission.READ_MEDIA_IMAGES',
          'android.permission.READ_MEDIA_VISUAL_USER_SELECTED',
        ]),
      );
      expect(
        manifest,
        matches(
          RegExp(
            r'android:name="android.permission.READ_EXTERNAL_STORAGE"'
            r'\s+android:maxSdkVersion="32"',
          ),
        ),
      );
    });

    test('declares no video or audio access', () {
      expect(
        permissions(),
        isNot(
          anyOf(
            contains('android.permission.READ_MEDIA_VIDEO'),
            contains('android.permission.READ_MEDIA_AUDIO'),
          ),
        ),
      );
    });

    test('declares internet access for map tiles', () {
      expect(permissions(), contains('android.permission.INTERNET'));
    });

    test('declares precise and approximate location while in use', () {
      expect(
        permissions(),
        containsAll([
          'android.permission.ACCESS_FINE_LOCATION',
          'android.permission.ACCESS_COARSE_LOCATION',
        ]),
      );
    });

    test('removes the foreground location service of geolocator', () {
      expect(
        manifest,
        matches(
          RegExp(
            r'android:name="android.permission.FOREGROUND_SERVICE_LOCATION"'
            r'\s+tools:node="remove"',
          ),
        ),
      );
      expect(
        manifest,
        matches(
          RegExp(
            r'android:name="com.baseflow.geolocator.GeolocatorLocationService"'
            r'\s+tools:node="remove"',
          ),
        ),
      );
    });

    test('declares no background location', () {
      expect(
        permissions(),
        isNot(contains('android.permission.ACCESS_BACKGROUND_LOCATION')),
      );
    });
  });
}
