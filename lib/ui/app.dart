import 'package:flutter/material.dart';

import '../domain/id_generator.dart';
import '../domain/trip_repository.dart';
import '../l10n/app_localizations.dart';
import 'home_screen.dart';
import 'theme.dart';

/// Root widget that wires theme, localization and the first screen together.
class TrailtaleApp extends StatelessWidget {
  const TrailtaleApp({
    super.key,
    required this.tripRepository,
    required this.newId,
  });

  final TripRepository tripRepository;
  final IdGenerator newId;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: ThemeMode.system,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: HomeScreen(tripRepository: tripRepository, newId: newId),
    );
  }
}
