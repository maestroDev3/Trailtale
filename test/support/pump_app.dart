import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trailtale/l10n/app_localizations.dart';
import 'package:trailtale/ui/theme.dart';

/// Logical size of a typical Android phone, so layouts are tested at the
/// size users actually see.
const phoneSize = Size(411, 914);

/// Pumps [widget] inside a [MaterialApp] with the app theme, the English
/// locale and a phone-sized surface, so widget tests look like the real app.
Future<void> pumpApp(WidgetTester tester, Widget widget) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = phoneSize;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      theme: buildLightTheme(),
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: widget,
    ),
  );
  await tester.pumpAndSettle();
}
