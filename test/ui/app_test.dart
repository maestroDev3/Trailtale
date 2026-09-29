import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trailtale/l10n/app_localizations.dart';
import 'package:trailtale/ui/app.dart';
import 'package:trailtale/ui/theme.dart';

import '../support/fake_trip_repository.dart';

void main() {
  group('TrailtaleApp', () {
    testWidgets('shows the app title and the empty trips message', (
      tester,
    ) async {
      await tester.pumpWidget(
        TrailtaleApp(tripRepository: FakeTripRepository(), newId: _newId),
      );
      await tester.pumpAndSettle();

      expect(find.text('Trailtale'), findsWidgets);
      expect(find.text('No trips yet'), findsOneWidget);
    });

    testWidgets('uses the localized app title as window title', (tester) async {
      await tester.pumpWidget(
        TrailtaleApp(tripRepository: FakeTripRepository(), newId: _newId),
      );
      await tester.pumpAndSettle();

      expect(tester.widget<Title>(find.byType(Title)).title, 'Trailtale');
    });

    testWidgets('follows the system with the light and dark theme', (
      tester,
    ) async {
      await tester.pumpWidget(
        TrailtaleApp(tripRepository: FakeTripRepository(), newId: _newId),
      );

      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.themeMode, ThemeMode.system);
      expect(app.theme?.colorScheme, buildLightTheme().colorScheme);
      expect(app.darkTheme?.colorScheme, buildDarkTheme().colorScheme);
    });

    testWidgets('supports English through the generated localizations', (
      tester,
    ) async {
      await tester.pumpWidget(
        TrailtaleApp(tripRepository: FakeTripRepository(), newId: _newId),
      );

      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.supportedLocales, contains(const Locale('en')));
      expect(app.localizationsDelegates, contains(AppLocalizations.delegate));
    });
  });

  group('lib/ui', () {
    test('contains no hard-coded UI strings', () {
      final hardCodedText = RegExp(r'''Text\(\s*['"]''');
      final offenders = Directory('lib/ui')
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'))
          .where((file) => hardCodedText.hasMatch(file.readAsStringSync()))
          .map((file) => file.path)
          .toList();

      expect(offenders, isEmpty);
    });
  });
}

String _newId() => 'id';
