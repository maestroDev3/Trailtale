import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trailtale/ui/theme.dart';

void main() {
  group('buildLightTheme', () {
    test('uses Material 3 with a light color scheme', () {
      final theme = buildLightTheme();

      expect(theme.useMaterial3, isTrue);
      expect(theme.colorScheme.brightness, Brightness.light);
    });

    test('derives its color scheme from the seed color', () {
      final theme = buildLightTheme();

      expect(
        theme.colorScheme,
        ColorScheme.fromSeed(
          seedColor: trailtaleSeedColor,
          brightness: Brightness.light,
        ),
      );
    });
  });

  group('buildDarkTheme', () {
    test('uses Material 3 with a dark color scheme', () {
      final theme = buildDarkTheme();

      expect(theme.useMaterial3, isTrue);
      expect(theme.colorScheme.brightness, Brightness.dark);
    });

    test('derives its color scheme from the same seed color', () {
      final theme = buildDarkTheme();

      expect(
        theme.colorScheme,
        ColorScheme.fromSeed(
          seedColor: trailtaleSeedColor,
          brightness: Brightness.dark,
        ),
      );
      expect(
        theme.colorScheme.primary,
        isNot(buildLightTheme().colorScheme.primary),
      );
    });
  });

  group('color definitions', () {
    test('hex color values only appear in lib/ui/theme.dart', () {
      final hexColor = RegExp(r'Color\(\s*0x');
      final offenders = Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'))
          .where((file) => !file.path.endsWith('lib/ui/theme.dart'))
          .where((file) => hexColor.hasMatch(file.readAsStringSync()))
          .map((file) => file.path)
          .toList();

      expect(offenders, isEmpty);
    });
  });
}
