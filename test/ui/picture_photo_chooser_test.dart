import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trailtale/domain/entry.dart';
import 'package:trailtale/ui/picture_photo_chooser.dart';

import '../support/pump_app.dart';
import '../support/test_services.dart';

void main() {
  Entry entry(String id, int day, List<String> photos) => Entry(
    id: id,
    tripId: 'me',
    time: DateTime.utc(2026, 9, day, 9),
    utcOffset: Duration.zero,
    photoPaths: photos,
  );
  final entries = [
    entry('b', 27, ['photos/b1.jpg', 'photos/b2.jpg', 'photos/b3.jpg']),
    entry('a', 26, ['photos/a1.jpg', 'photos/a2.jpg']),
  ];

  Finder tile(String path) => find.byKey(Key('picture-photo-$path'));
  Finder badge(String path, String number) =>
      find.descendant(of: tile(path), matching: find.text(number));

  Future<Future<List<String>?>> openChooser(
    WidgetTester tester, {
    List<String> selected = const [],
  }) async {
    late Future<List<String>?> result;
    await pumpApp(
      tester,
      Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => result = Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PicturePhotoChooser(
                  services: testServices(),
                  entries: entries,
                  selected: selected,
                ),
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return result;
  }

  group('PicturePhotoChooser', () {
    testWidgets('shows every trip photo once with the selection numbered', (
      tester,
    ) async {
      await openChooser(tester, selected: ['photos/b2.jpg', 'photos/a1.jpg']);

      expect(find.text('Choose photos'), findsOneWidget);
      for (final path in [
        'photos/a1.jpg',
        'photos/a2.jpg',
        'photos/b1.jpg',
        'photos/b2.jpg',
        'photos/b3.jpg',
      ]) {
        expect(tile(path), findsOneWidget);
      }
      expect(badge('photos/b2.jpg', '1'), findsOneWidget);
      expect(badge('photos/a1.jpg', '2'), findsOneWidget);
    });

    testWidgets('selects and deselects by tapping', (tester) async {
      final result = await openChooser(tester, selected: ['photos/a1.jpg']);

      await tester.tap(tile('photos/a1.jpg'));
      await tester.tap(tile('photos/b3.jpg'));
      await tester.tap(tile('photos/a2.jpg'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Use 2 photos'));
      await tester.pumpAndSettle();

      expect(await result, ['photos/b3.jpg', 'photos/a2.jpg']);
    });

    testWidgets('allows at most four photos', (tester) async {
      await openChooser(
        tester,
        selected: [
          'photos/a1.jpg',
          'photos/a2.jpg',
          'photos/b1.jpg',
          'photos/b2.jpg',
        ],
      );

      await tester.tap(tile('photos/b3.jpg'));
      await tester.pumpAndSettle();

      expect(find.text('Use 4 photos'), findsOneWidget);
      expect(find.text('Up to 4 photos'), findsOneWidget);
    });

    testWidgets('goes back to the automatic pick', (tester) async {
      final result = await openChooser(tester, selected: ['photos/a1.jpg']);

      await tester.tap(find.text('Automatic'));
      await tester.pumpAndSettle();

      expect(await result, isEmpty);
    });

    testWidgets('changes nothing when going back', (tester) async {
      final result = await openChooser(tester, selected: ['photos/a1.jpg']);

      await tester.tap(tile('photos/b1.jpg'));
      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(await result, isNull);
    });
  });
}
