import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trailtale/ui/home_screen.dart';

import '../support/pump_app.dart';

void main() {
  group('HomeScreen', () {
    testWidgets('shows the app title and the empty trips message', (
      tester,
    ) async {
      await pumpApp(tester, const HomeScreen());

      expect(find.text('Trailtale'), findsWidgets);
      expect(find.text('No trips yet'), findsOneWidget);
    });
  });

  group('pumpApp', () {
    testWidgets('uses the English locale and a phone-sized surface', (
      tester,
    ) async {
      await pumpApp(tester, const HomeScreen());

      final context = tester.element(find.byType(HomeScreen));
      expect(Localizations.localeOf(context), const Locale('en'));
      expect(MediaQuery.sizeOf(context), phoneSize);
    });
  });
}
