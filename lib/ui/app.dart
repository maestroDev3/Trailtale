import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'app_services.dart';
import 'home_screen.dart';
import 'quick_capture_screen.dart';
import 'shared_photos_screen.dart';
import 'theme.dart';

/// Root widget that wires theme, localization and the first screen together,
/// and opens quick capture for every tap on the home screen widget and the
/// shared photos screen for every share from another app.
class TrailtaleApp extends StatefulWidget {
  const TrailtaleApp({super.key, required this.services});

  final AppServices services;

  @override
  State<TrailtaleApp> createState() => _TrailtaleAppState();
}

class _TrailtaleAppState extends State<TrailtaleApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  late final StreamSubscription<void> _quickCaptures;
  late final StreamSubscription<List<String>> _sharedPhotos;

  @override
  void initState() {
    super.initState();
    _quickCaptures = widget.services.quickCaptureRequests.requests.listen(
      (_) => _open((services) => QuickCaptureScreen(services: services)),
    );
    _sharedPhotos = widget.services.sharedPhotoRequests.photos.listen(
      (paths) => _open(
        (services) => SharedPhotosScreen(services: services, paths: paths),
      ),
    );
  }

  @override
  void dispose() {
    unawaited(_quickCaptures.cancel());
    unawaited(_sharedPhotos.cancel());
    super.dispose();
  }

  /// Opens [screen] on top of the current one.
  void _open(Widget Function(AppServices services) screen) {
    final navigator = _navigatorKey.currentState;
    if (navigator == null) {
      // The request came before the first frame; open it right after.
      WidgetsBinding.instance.addPostFrameCallback((_) => _open(screen));
      return;
    }
    unawaited(
      navigator.push(
        MaterialPageRoute<void>(builder: (_) => screen(widget.services)),
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
