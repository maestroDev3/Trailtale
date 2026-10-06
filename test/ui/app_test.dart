import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trailtale/l10n/app_localizations.dart';
import 'package:trailtale/ui/app.dart';
import 'package:trailtale/ui/quick_capture_screen.dart';
import 'package:trailtale/ui/shared_photos_screen.dart';
import 'package:trailtale/ui/trip_form_screen.dart';
import 'package:trailtale/ui/theme.dart';

import '../support/fake_quick_capture_requests.dart';
import '../support/fake_shared_photo_requests.dart';
import '../support/test_services.dart';

void main() {
  group('TrailtaleApp', () {
    testWidgets('shows the app title and the welcome headline', (tester) async {
      await tester.pumpWidget(TrailtaleApp(services: testServices()));
      await tester.pumpAndSettle();

      expect(find.text('Trailtale'), findsWidgets);
      expect(find.text('Every trip tells a tale'), findsOneWidget);
    });

    testWidgets('uses the localized app title as window title', (tester) async {
      await tester.pumpWidget(TrailtaleApp(services: testServices()));
      await tester.pumpAndSettle();

      expect(tester.widget<Title>(find.byType(Title)).title, 'Trailtale');
    });

    testWidgets('follows the system with the light and dark theme', (
      tester,
    ) async {
      await tester.pumpWidget(TrailtaleApp(services: testServices()));

      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.themeMode, ThemeMode.system);
      expect(app.theme?.colorScheme, buildLightTheme().colorScheme);
      expect(app.darkTheme?.colorScheme, buildDarkTheme().colorScheme);
    });

    testWidgets('supports English through the generated localizations', (
      tester,
    ) async {
      await tester.pumpWidget(TrailtaleApp(services: testServices()));

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

  group('TrailtaleApp quick capture', () {
    testWidgets('opens quick capture when a request arrives', (tester) async {
      final requests = FakeQuickCaptureRequests();
      await tester.pumpWidget(
        TrailtaleApp(services: testServices(quickCaptureRequests: requests)),
      );
      await tester.pumpAndSettle();

      requests.request();
      await tester.pumpAndSettle();

      expect(find.byType(QuickCaptureScreen), findsOneWidget);
    });

    testWidgets('opens quick capture on top of the current screen', (
      tester,
    ) async {
      final requests = FakeQuickCaptureRequests();
      await tester.pumpWidget(
        TrailtaleApp(services: testServices(quickCaptureRequests: requests)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('New trip').first);
      await tester.pumpAndSettle();
      expect(find.byType(TripFormScreen), findsOneWidget);

      requests.request();
      await tester.pumpAndSettle();

      expect(find.byType(QuickCaptureScreen), findsOneWidget);
      expect(find.byType(TripFormScreen, skipOffstage: false), findsOneWidget);
    });
  });

  group('TrailtaleApp shared photos', () {
    testWidgets('opens the shared photos screen with their paths', (
      tester,
    ) async {
      final shares = FakeSharedPhotoRequests();
      await tester.pumpWidget(
        TrailtaleApp(services: testServices(sharedPhotoRequests: shares)),
      );
      await tester.pumpAndSettle();

      shares.share(['/cache/a.jpg', '/cache/b.jpg']);
      await tester.pumpAndSettle();

      final screen = tester.widget<SharedPhotosScreen>(
        find.byType(SharedPhotosScreen),
      );
      expect(screen.paths, ['/cache/a.jpg', '/cache/b.jpg']);
    });
  });
}
