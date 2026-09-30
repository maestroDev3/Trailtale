import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The “field journal” palette: warm paper, ink green, clay for actions,
/// sunset for highlights and sea blue for routes. The only place in the app
/// where colors are defined.
abstract final class TrailtaleColors {
  static const paper = Color(0xFFF6F1E7);
  static const card = Color(0xFFFFFDF8);
  static const ink = Color(0xFF1F3B34);
  static const clay = Color(0xFFB84A22);
  static const sunset = Color(0xFFE07A45);
  static const sea = Color(0xFF2F6F7E);
  static const muted = Color(0xFF56645F);
  static const line = Color(0xFFD9CDB5);
}

const _lightScheme = ColorScheme(
  brightness: Brightness.light,
  primary: TrailtaleColors.clay,
  onPrimary: Color(0xFFFFFFFF),
  primaryContainer: Color(0xFFF6D9C8),
  onPrimaryContainer: Color(0xFF5A230E),
  secondary: TrailtaleColors.sea,
  onSecondary: Color(0xFFFFFFFF),
  secondaryContainer: Color(0xFFE3EEEC),
  onSecondaryContainer: Color(0xFF1F4A54),
  tertiary: TrailtaleColors.sunset,
  onTertiary: Color(0xFF141C19),
  tertiaryContainer: Color(0xFFFBE3D3),
  onTertiaryContainer: Color(0xFF5A230E),
  error: Color(0xFFB3261E),
  onError: Color(0xFFFFFFFF),
  surface: TrailtaleColors.paper,
  onSurface: TrailtaleColors.ink,
  onSurfaceVariant: TrailtaleColors.muted,
  surfaceContainerLowest: TrailtaleColors.card,
  surfaceContainerLow: Color(0xFFFAF6EE),
  surfaceContainer: Color(0xFFF1EADC),
  surfaceContainerHigh: Color(0xFFEFE7D6),
  surfaceContainerHighest: Color(0xFFE6DCC8),
  outline: Color(0xFF8C9A93),
  outlineVariant: TrailtaleColors.line,
  inverseSurface: TrailtaleColors.ink,
  onInverseSurface: TrailtaleColors.paper,
  inversePrimary: Color(0xFFE8875A),
  shadow: Color(0xFF000000),
  scrim: Color(0xFF000000),
  surfaceTint: Color(0x00000000),
);

const _darkScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: Color(0xFFE8875A),
  onPrimary: Color(0xFF2A1408),
  primaryContainer: Color(0xFF6B2A10),
  onPrimaryContainer: Color(0xFFFBDCCB),
  secondary: Color(0xFF86BCC6),
  onSecondary: Color(0xFF0E2B31),
  secondaryContainer: Color(0xFF1F4A54),
  onSecondaryContainer: Color(0xFFCFE6EA),
  tertiary: Color(0xFFF0A57A),
  onTertiary: Color(0xFF2A1408),
  tertiaryContainer: Color(0xFF6B2A10),
  onTertiaryContainer: Color(0xFFFBDCCB),
  error: Color(0xFFF2B8B5),
  onError: Color(0xFF601410),
  surface: Color(0xFF141C19),
  onSurface: Color(0xFFEDE6D8),
  onSurfaceVariant: Color(0xFFAEB8B2),
  surfaceContainerLowest: Color(0xFF1B2521),
  surfaceContainerLow: Color(0xFF1C2723),
  surfaceContainer: Color(0xFF212D28),
  surfaceContainerHigh: Color(0xFF26332E),
  surfaceContainerHighest: Color(0xFF2E3C36),
  outline: Color(0xFF7F8C86),
  outlineVariant: Color(0xFF3A4A44),
  inverseSurface: Color(0xFFEDE6D8),
  onInverseSurface: Color(0xFF1F3B34),
  inversePrimary: TrailtaleColors.clay,
  shadow: Color(0xFF000000),
  scrim: Color(0xFF000000),
  surfaceTint: Color(0x00000000),
);

/// Builds the light theme used when the system is in light mode.
ThemeData buildLightTheme() => _buildTheme(_lightScheme);

/// Builds the dark theme used when the system is in dark mode.
ThemeData buildDarkTheme() => _buildTheme(_darkScheme);

/// Display font for headings and numbers: a warm serif like in a journal.
const displayFontFamily = 'Fraunces';

/// Text font for everything else.
const textFontFamily = 'Manrope';

ThemeData _buildTheme(ColorScheme scheme) {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: textFontFamily,
  );
  return base.copyWith(
    scaffoldBackgroundColor: scheme.surface,
    textTheme: _textTheme(base.textTheme),
  );
}

TextTheme _textTheme(TextTheme base) {
  TextStyle? display(TextStyle? style, FontWeight weight) =>
      style?.copyWith(fontFamily: displayFontFamily, fontWeight: weight);
  return base.copyWith(
    displayLarge: display(base.displayLarge, FontWeight.w600),
    displayMedium: display(base.displayMedium, FontWeight.w600),
    displaySmall: display(base.displaySmall, FontWeight.w600),
    headlineLarge: display(base.headlineLarge, FontWeight.w600),
    headlineMedium: display(base.headlineMedium, FontWeight.w600),
    headlineSmall: display(base.headlineSmall, FontWeight.w600),
    titleLarge: display(base.titleLarge, FontWeight.w600),
    titleMedium: display(base.titleMedium, FontWeight.w600),
    titleSmall: base.titleSmall?.copyWith(fontWeight: FontWeight.w700),
    labelLarge: base.labelLarge?.copyWith(fontWeight: FontWeight.w700),
  );
}

/// Adds the SIL Open Font License texts of the bundled fonts to the app's
/// licenses page.
void registerFontLicenses() {
  LicenseRegistry.addLicense(() async* {
    for (final family in [displayFontFamily, textFontFamily]) {
      final text = await rootBundle.loadString('assets/fonts/$family-OFL.txt');
      yield LicenseEntryWithLineBreaks([family], text);
    }
  });
}
