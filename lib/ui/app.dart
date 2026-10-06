import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'app_services.dart';
import 'home_screen.dart';
import 'quick_capture_screen.dart';
import 'theme.dart';

/// Root widget that wires theme, localization and the first screen together,
/// and opens quick capture for every tap on the home screen widget.
class TrailtaleApp extends StatefulWidget {
  const TrailtaleApp({super.key, required this.services});

  final AppServices services;

  @override
  State<TrailtaleApp> createState() => _TrailtaleAppState();
}

class _TrailtaleAppState extends State<TrailtaleApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  late final StreamSubscription<void> _quickCaptures;

  @override
  void initState() {
    super.initState();
    _quickCaptures = widget.services.quickCaptureRequests.requests.listen(
      (_) => _openQuickCapture(),
    );
  }

  @override
  void dispose() {
    unawaited(_quickCaptures.cancel());
    super.dispose();
  }

  void _openQuickCapture() {
    final navigator = _navigatorKey.currentState;
    if (navigator == null) {
      // The request came before the first frame; open it right after.
      WidgetsBinding.instance.addPostFrameCallback((_) => _openQuickCapture());
      return;
    }
    unawaited(
      navigator.push(
        MaterialPageRoute<void>(
          builder: (_) => QuickCaptureScreen(services: widget.services),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: ThemeMode.system,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: HomeScreen(services: widget.services),
    );
  }
}
