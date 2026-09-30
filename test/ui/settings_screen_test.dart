import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trailtale/domain/backup_service.dart';
import 'package:trailtale/ui/home_screen.dart';
import 'package:trailtale/ui/settings_screen.dart';

import '../support/fake_backup.dart';
import '../support/fake_entry_repository.dart';
import '../support/fake_trip_repository.dart';
import '../support/pump_app.dart';
import '../support/test_services.dart';

void main() {
  final picked = File('/downloads/trailtale-backup-2026-09-01.zip');

  Future<void> openSettings(
    WidgetTester tester, {
    FakeBackupService? backup,
    FakeFileSharer? sharer,
    FakeDocumentPicker? picker,
    FakeTripRepository? trips,
    FakeEntryRepository? entries,
  }) async {
    await pumpApp(
      tester,
      HomeScreen(
        services: testServices(
          backupService: backup,
          fileSharer: sharer,
          documentPicker: picker,
          trips: trips,
          entries: entries,
        ),
      ),
    );
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
  }

  Future<void> tapTile(WidgetTester tester, String title) async {
    await tester.ensureVisible(find.text(title));
    await tester.tap(find.text(title));
    await tester.pumpAndSettle();
  }

  group('SettingsScreen', () {
    testWidgets('opens from the gear on the home screen', (tester) async {
      await openSettings(tester);

      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(find.text('Back up now'), findsOneWidget);
      expect(find.text('Restore from backup'), findsOneWidget);
    });

    testWidgets('backs up and shares the ZIP', (tester) async {
      final backup = FakeBackupService();
      final sharer = FakeFileSharer();
      await openSettings(tester, backup: backup, sharer: sharer);

      await tapTile(tester, 'Back up now');

      expect(backup.createCount, 1);
      expect(sharer.shared, [backup.backupFile]);
    });

    testWidgets('restores a picked backup after confirmation and reloads', (
      tester,
    ) async {
      final backup = FakeBackupService();
      final trips = FakeTripRepository();
      final entries = FakeEntryRepository();
      await openSettings(
        tester,
        backup: backup,
        picker: FakeDocumentPicker(picked),
        trips: trips,
        entries: entries,
      );

      await tapTile(tester, 'Restore from backup');
      expect(find.text('Restore this backup?'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Restore'));
      await tester.pumpAndSettle();

      expect(backup.restored, [picked]);
      expect(trips.reloadCount, 1);
      expect(entries.reloadCount, 1);
      expect(find.text('Backup restored'), findsOneWidget);
    });

    testWidgets('changes nothing when picking is cancelled', (tester) async {
      final backup = FakeBackupService();
      final picker = FakeDocumentPicker();
      await openSettings(tester, backup: backup, picker: picker);

      await tapTile(tester, 'Restore from backup');

      expect(picker.pickCount, 1);
      expect(find.text('Restore this backup?'), findsNothing);
      expect(backup.restored, isEmpty);
    });

    testWidgets('changes nothing when restoring is not confirmed', (
      tester,
    ) async {
      final backup = FakeBackupService();
      await openSettings(
        tester,
        backup: backup,
        picker: FakeDocumentPicker(picked),
      );

      await tapTile(tester, 'Restore from backup');
      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();

      expect(backup.restored, isEmpty);
    });

    testWidgets('explains an invalid file', (tester) async {
      await openSettings(
        tester,
        backup: FakeBackupService(
          restoreError: const InvalidBackupException('no manifest'),
        ),
        picker: FakeDocumentPicker(picked),
      );

      await tapTile(tester, 'Restore from backup');
      await tester.tap(find.widgetWithText(FilledButton, 'Restore'));
      await tester.pumpAndSettle();

      expect(find.text('This file is not a Trailtale backup.'), findsOneWidget);
    });

    testWidgets('opens the open-source licenses', (tester) async {
      await openSettings(tester);

      await tapTile(tester, 'Open-source licenses');

      expect(find.byType(LicensePage), findsOneWidget);
    });
  });
}
