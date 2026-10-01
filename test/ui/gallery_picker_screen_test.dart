import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trailtale/domain/photo_gallery.dart';
import 'package:trailtale/domain/trip.dart';
import 'package:trailtale/ui/gallery_picker_screen.dart';

import '../support/fake_photo_gallery.dart';
import '../support/pump_app.dart';

final trip = Trip(
  id: 't',
  title: 'Montenegro',
  startDate: DateTime(2026, 9, 26),
  endDate: DateTime(2026, 9, 28),
);

GalleryPhoto photo(String id, DateTime takenAt) =>
    GalleryPhoto(id: id, takenAt: takenAt);

/// Gallery with two photos during [trip] and one before it.
FakePhotoGallery tripGallery() => FakePhotoGallery(
  photos: [
    photo('before', DateTime(2026, 9, 20, 12)),
    photo('kotor', DateTime(2026, 9, 26, 10)),
    photo('beach', DateTime(2026, 9, 28, 16)),
  ],
);

Finder tile(String id) => find.byKey(ValueKey('gallery-photo-$id'));

Future<Future<List<String>?>> pumpPicker(
  WidgetTester tester,
  PhotoGallery gallery, {
  GalleryAccess access = GalleryAccess.full,
  int pageSize = 60,
}) async {
  late Future<List<String>?> result;
  await pumpApp(
    tester,
    Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () {
              result = Navigator.of(context).push<List<String>>(
                MaterialPageRoute(
                  builder: (_) => GalleryPickerScreen(
                    gallery: gallery,
                    trip: trip,
                    access: access,
                    pageSize: pageSize,
                  ),
                ),
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return result;
}

void main() {
  group('GalleryPickerScreen', () {
    testWidgets('shows the photos taken during the trip first', (tester) async {
      await pumpPicker(tester, tripGallery());

      expect(tile('kotor'), findsOneWidget);
      expect(tile('beach'), findsOneWidget);
      expect(tile('before'), findsNothing);
    });

    testWidgets('switches to all photos', (tester) async {
      await pumpPicker(tester, tripGallery());

      await tester.tap(find.text('All photos'));
      await tester.pumpAndSettle();

      expect(tile('before'), findsOneWidget);
      expect(tile('kotor'), findsOneWidget);
    });

    testWidgets('offers all photos when the trip days have none', (
      tester,
    ) async {
      final gallery = FakePhotoGallery(
        photos: [photo('before', DateTime(2026, 9, 20, 12))],
      );
      await pumpPicker(tester, gallery);

      expect(find.text('No photos from the days of this trip'), findsOneWidget);
      await tester.tap(find.text('Show all photos'));
      await tester.pumpAndSettle();

      expect(tile('before'), findsOneWidget);
    });

    testWidgets('selects and deselects photos by tapping', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpPicker(tester, tripGallery());

      await tester.tap(tile('kotor'));
      await tester.pumpAndSettle();

      expect(
        find.descendant(of: tile('kotor'), matching: find.byIcon(Icons.check)),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(RegExp(r'Photo from .*Sep 26, 2026.*, selected')),
        findsOneWidget,
      );

      await tester.tap(tile('kotor'));
      await tester.pumpAndSettle();

      expect(
        find.descendant(of: tile('kotor'), matching: find.byIcon(Icons.check)),
        findsNothing,
      );
      semantics.dispose();
    });

    testWidgets('returns the chosen photos in the order selected', (
      tester,
    ) async {
      final result = await pumpPicker(tester, tripGallery());

      await tester.tap(tile('beach'));
      await tester.tap(tile('kotor'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add 2 photos'));
      await tester.pumpAndSettle();

      expect(await result, ['beach', 'kotor']);
    });

    testWidgets('disables the add button without a selection', (tester) async {
      await pumpPicker(tester, tripGallery());

      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Add photos'),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('returns nothing when going back', (tester) async {
      final result = await pumpPicker(tester, tripGallery());

      await tester.tap(tile('kotor'));
      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(await result, isNull);
    });

    testWidgets('loads more photos when scrolling to the end', (tester) async {
      final gallery = FakePhotoGallery(
        photos: [
          for (var hour = 0; hour < 40; hour++)
            photo('p$hour', DateTime(2026, 9, 27).add(Duration(hours: hour))),
        ],
      );
      await pumpPicker(tester, gallery, pageSize: 6);

      await tester.scrollUntilVisible(
        tile('p0'),
        300,
        scrollable: find.byType(Scrollable).last,
      );

      expect(tile('p0'), findsOneWidget);
    });

    testWidgets('lets the user select more photos with limited access', (
      tester,
    ) async {
      final gallery = tripGallery();
      await pumpPicker(tester, gallery, access: GalleryAccess.limited);

      expect(
        find.text('Trailtale can only see the photos you selected.'),
        findsOneWidget,
      );
      gallery.stored.add(photo('castle', DateTime(2026, 9, 27, 11)));
      await tester.tap(find.text('Select more'));
      await tester.pumpAndSettle();

      expect(gallery.selectMoreCount, 1);
      expect(tile('castle'), findsOneWidget);
    });

    testWidgets('shows no limited access hint with full access', (
      tester,
    ) async {
      await pumpPicker(tester, tripGallery());

      expect(find.text('Select more'), findsNothing);
    });
  });
}
