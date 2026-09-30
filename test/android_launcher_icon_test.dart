import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

const _res = 'android/app/src/main/res';

String _read(String path) => File('$_res/$path').readAsStringSync();

/// Width and height from the IHDR chunk of a PNG file.
(int, int) _pngSize(String path) {
  final bytes = File('$_res/$path').readAsBytesSync();
  final data = ByteData.sublistView(bytes);
  return (data.getUint32(16), data.getUint32(20));
}

/// All x/y coordinates of the path data in a vector drawable.
List<double> _coordinates(String vectorXml) {
  final paths = RegExp(
    r'android:pathData="([^"]+)"',
  ).allMatches(vectorXml).map((match) => match.group(1) ?? '');
  return [
    for (final path in paths)
      for (final number in RegExp(r'-?\d+(\.\d+)?').allMatches(path))
        double.parse(number.group(0) ?? ''),
  ];
}

void main() {
  group('Android launcher icon', () {
    test('is an adaptive icon with background, foreground and monochrome', () {
      final icon = _read('mipmap-anydpi-v26/ic_launcher.xml');

      expect(icon, contains('<adaptive-icon'));
      expect(icon, contains('@color/ic_launcher_background'));
      expect(icon, contains('@drawable/ic_launcher_foreground'));
      expect(icon, contains('@drawable/ic_launcher_monochrome'));
    });

    test('uses ink as background color', () {
      final colors = _read('values/ic_launcher_background.xml');

      expect(
        colors,
        contains('<color name="ic_launcher_background">#1F3B34</color>'),
      );
    });

    test('keeps the foreground inside the 66 dp safe zone', () {
      for (final drawable in [
        'drawable/ic_launcher_foreground.xml',
        'drawable/ic_launcher_monochrome.xml',
      ]) {
        final vector = _read(drawable);
        expect(vector, contains('android:viewportWidth="108"'));
        final coordinates = _coordinates(vector);
        expect(coordinates, isNotEmpty);
        // Absolute coordinates only (arc radii are small and positive too).
        for (final value in coordinates.where((value) => value > 12)) {
          expect(value, inInclusiveRange(21, 87), reason: drawable);
        }
      }
    });

    test('has PNG fallbacks in every density', () {
      const sizes = {
        'mdpi': 48,
        'hdpi': 72,
        'xhdpi': 96,
        'xxhdpi': 144,
        'xxxhdpi': 192,
      };
      for (final MapEntry(key: density, value: size) in sizes.entries) {
        expect(_pngSize('mipmap-$density/ic_launcher.png'), (size, size));
      }
    });

    test('is used by the manifest', () {
      final manifest = File(
        'android/app/src/main/AndroidManifest.xml',
      ).readAsStringSync();

      expect(manifest, contains('android:icon="@mipmap/ic_launcher"'));
    });
  });
}
