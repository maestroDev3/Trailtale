import 'package:flutter/material.dart';

/// The single brand color every Trailtale color scheme is generated from, so
/// light and dark mode stay consistent.
const trailtaleSeedColor = Color(0xFF2E7D6B);

/// Builds the light Material 3 theme used when the system is in light mode.
ThemeData buildLightTheme() => _buildTheme(Brightness.light);

/// Builds the dark Material 3 theme used when the system is in dark mode.
ThemeData buildDarkTheme() => _buildTheme(Brightness.dark);

ThemeData _buildTheme(Brightness brightness) {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: trailtaleSeedColor,
      brightness: brightness,
    ),
  );
}
