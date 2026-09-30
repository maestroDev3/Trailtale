import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trailtale/ui/theme.dart';

double _contrast(Color a, Color b) {
  final (lighter, darker) = a.computeLuminance() > b.computeLuminance()
      ? (a, b)
      : (b, a);
  return (lighter.computeLuminance() + 0.05) /
      (darker.computeLuminance() + 0.05);
}

void main() {
  group('buildLightTheme', () {
    final scheme = buildLightTheme().colorScheme;

    test('uses Material 3 with a light color scheme', () {
      expect(buildLightTheme().useMaterial3, isTrue);
      expect(scheme.brightness, Brightness.light);
    });

    test('uses the field journal colors', () {
      expect(scheme.primary, const Color(0xFFB84A22));
      expect(scheme.secondary, const Color(0xFF2F6F7E));
      expect(scheme.tertiary, const Color(0xFFE07A45));
      expect(scheme.surface, const Color(0xFFF6F1E7));
      expect(scheme.onSurface, const Color(0xFF1F3B34));
      expect(scheme.surfaceContainerLowest, const Color(0xFFFFFDF8));
    });
  });

  group('buildDarkTheme', () {
    test('uses Material 3 with a dark color scheme', () {
      final theme = buildDarkTheme();

      expect(theme.useMaterial3, isTrue);
      expect(theme.colorScheme.brightness, Brightness.dark);
      expect(theme.colorScheme.surface.computeLuminance(), lessThan(0.05));
    });
  });

  for (final (name, theme) in [
    ('light', buildLightTheme()),
    ('dark', buildDarkTheme()),
  ]) {
    group('$name theme contrast', () {
      final scheme = theme.colorScheme;
      final pairs = {
        'primary': (scheme.primary, scheme.onPrimary),
        'secondary': (scheme.secondary, scheme.onSecondary),
        'tertiary': (scheme.tertiary, scheme.onTertiary),
        'primaryContainer': (
          scheme.primaryContainer,
          scheme.onPrimaryContainer,
        ),
        'secondaryContainer': (
          scheme.secondaryContainer,
          scheme.onSecondaryContainer,
        ),
        'surface': (scheme.surface, scheme.onSurface),
        'surfaceVariantText': (scheme.surface, scheme.onSurfaceVariant),
      };
      for (final MapEntry(key: pair, value: (background, foreground))
          in pairs.entries) {
        test('$pair text has a contrast of at least 4.5', () {
          expect(_contrast(background, foreground), greaterThanOrEqualTo(4.5));
        });
      }
    });

    group('$name theme typography', () {
      final text = theme.textTheme;

      test('uses Fraunces for display, headline and large titles', () {
        for (final style in [
          text.displayLarge,
          text.displayMedium,
          text.displaySmall,
          text.headlineLarge,
          text.headlineMedium,
          text.headlineSmall,
          text.titleLarge,
          text.titleMedium,
        ]) {
          expect(style?.fontFamily, 'Fraunces');
        }
      });

      test('uses Manrope for small titles, body and labels', () {
        for (final style in [
          text.titleSmall,
          text.bodyLarge,
          text.bodyMedium,
          text.bodySmall,
          text.labelLarge,
          text.labelMedium,
          text.labelSmall,
        ]) {
          expect(style?.fontFamily, 'Manrope');
        }
      });
    });
  }

  group('bundled fonts', () {
    test('are declared in pubspec.yaml and exist', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      final assets = RegExp(r'asset:\s*(assets/fonts/\S+)')
          .allMatches(pubspec)
          .map((match) => match.group(1) ?? '')
          .toList();

      expect(pubspec, contains('family: Fraunces'));
      expect(pubspec, contains('family: Manrope'));
      expect(assets, isNotEmpty);
      for (final asset in assets) {
        expect(File(asset).existsSync(), isTrue, reason: asset);
      }
    });

    testWidgets('register their licenses', (tester) async {
      registerFontLicenses();

      final packages = await tester.runAsync(
        () => LicenseRegistry.licenses
            .expand((license) => license.packages)
            .toList(),
      );

      expect(packages, containsAll(['Fraunces', 'Manrope']));
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
          .where((file) => !file.path.contains('lib/l10n/'))
          .where((file) => hexColor.hasMatch(file.readAsStringSync()))
          .map((file) => file.path)
          .toList();

      expect(offenders, isEmpty);
    });
  });

  group('component styles', () {
    final theme = buildLightTheme();
    final scheme = theme.colorScheme;
    const states = <WidgetState>{};

    test('cards are flat paper cards with a thin border', () {
      final card = theme.cardTheme;
      final shape = card.shape as RoundedRectangleBorder?;

      expect(card.color, scheme.surfaceContainerLowest);
      expect(card.elevation, 0);
      expect(shape?.borderRadius, BorderRadius.circular(22));
      expect(shape?.side.color, scheme.outlineVariant);
      expect(shape?.side.width, 1);
    });

    test('filled buttons are clay with rounded corners', () {
      final style = theme.filledButtonTheme.style;
      final shape = style?.shape?.resolve(states) as RoundedRectangleBorder?;

      expect(style?.backgroundColor?.resolve(states), scheme.primary);
      expect(style?.foregroundColor?.resolve(states), scheme.onPrimary);
      expect(style?.minimumSize?.resolve(states)?.height, 52);
      expect(shape?.borderRadius, BorderRadius.circular(18));
    });

    test('outlined buttons have a strong ink border', () {
      final style = theme.outlinedButtonTheme.style;
      final side = style?.side?.resolve(states);

      expect(side?.color, scheme.onSurface);
      expect(side?.width, 2);
      expect(style?.minimumSize?.resolve(states)?.height, 52);
    });

    test('the floating action button is clay', () {
      final fab = theme.floatingActionButtonTheme;
      final shape = fab.shape as RoundedRectangleBorder?;

      expect(fab.backgroundColor, scheme.primary);
      expect(fab.foregroundColor, scheme.onPrimary);
      expect(shape?.borderRadius, BorderRadius.circular(20));
    });

    test('inputs are filled cards with a focused clay border', () {
      final input = theme.inputDecorationTheme;
      final border = input.enabledBorder as OutlineInputBorder?;
      final focused = input.focusedBorder as OutlineInputBorder?;

      expect(input.filled, isTrue);
      expect(input.fillColor, scheme.surfaceContainerLowest);
      expect(border?.borderRadius, BorderRadius.circular(16));
      expect(border?.borderSide.color, scheme.outlineVariant);
      expect(focused?.borderSide.color, scheme.primary);
    });

    test('app bars sit on the paper without a scroll tint', () {
      final appBar = theme.appBarTheme;

      expect(appBar.backgroundColor, scheme.surface);
      expect(appBar.scrolledUnderElevation, 0);
      expect(appBar.titleTextStyle?.fontFamily, 'Fraunces');
    });

    test('snack bars float with rounded corners', () {
      final snackBar = theme.snackBarTheme;
      final shape = snackBar.shape as RoundedRectangleBorder?;

      expect(snackBar.behavior, SnackBarBehavior.floating);
      expect(shape?.borderRadius, BorderRadius.circular(14));
    });
  });
}
