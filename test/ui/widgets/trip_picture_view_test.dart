import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trailtale/domain/geo_point.dart';
import 'package:trailtale/domain/trip_map.dart';
import 'package:trailtale/domain/trip_picture.dart';
import 'package:trailtale/ui/widgets/trip_picture_view.dart';

import '../../support/placeholder_trip_map.dart';
import '../../support/pump_app.dart';

void main() {
  final picture = TripPicture(
    title: 'Montenegro',
    startDate: DateTime.utc(2026, 9, 26),
    endDate: DateTime.utc(2026, 9, 30),
    dayCount: 5,
    stops: [
      TripStop(
        name: 'Kotor',
        location: GeoPoint(latitude: 42.4247, longitude: 18.7712),
      ),
      const TripStop(name: 'Perast'),
      TripStop(
        name: 'Budva',
        location: GeoPoint(latitude: 42.2864, longitude: 18.84),
      ),
    ],
    distanceMeters: 16400,
    photoPaths: const ['photos/a.jpg', 'photos/b.jpg', 'photos/c.jpg'],
  );

  Future<void> pumpPicture(
    WidgetTester tester, {
    TripPicture? content,
    TripPictureFormat format = TripPictureFormat.story,
  }) => pumpApp(
    tester,
    Center(
      child: TripPictureView(
        picture: content ?? picture,
        format: format,
        photoFile: (path) => File('/nonexistent/$path'),
        routeMap: PlaceholderTripMap.new,
      ),
    ),
  );

  group('TripPictureFormat', () {
    test('has the sizes Instagram expects', () {
      expect(TripPictureFormat.story.logicalSize, const Size(360, 640));
      expect(TripPictureFormat.post.logicalSize, const Size(360, 450));
      expect(TripPictureFormat.story.pixelSize, const Size(1080, 1920));
      expect(TripPictureFormat.post.pixelSize, const Size(1080, 1350));
    });
  });

  group('TripPictureView', () {
    for (final format in TripPictureFormat.values) {
      testWidgets('has the logical size of the ${format.name} format', (
        tester,
      ) async {
        await pumpPicture(tester, format: format);

        expect(
          tester.getSize(find.byType(TripPictureView)),
          format.logicalSize,
        );
      });

      testWidgets('shows title, dates and figures in ${format.name}', (
        tester,
      ) async {
        await pumpPicture(tester, format: format);

        expect(find.text('Montenegro'), findsOneWidget);
        expect(find.text('Sep 26, 2026 – Sep 30, 2026'), findsOneWidget);
        expect(find.text('5 days · 3 places · 16 km'), findsOneWidget);
      });

      testWidgets('shows the photos above the map in ${format.name}', (
        tester,
      ) async {
        await pumpPicture(tester, format: format);

        final photos = tester.getRect(
          find.byKey(const Key('trip-picture-photos')),
        );
        final map = tester.getRect(find.byKey(const Key('trip-picture-route')));
        expect(photos.bottom, lessThanOrEqualTo(map.top));
      });

      testWidgets('shows pins, stop names and photos in ${format.name}', (
        tester,
      ) async {
        await pumpPicture(tester, format: format);

        expect(find.text('Marker 1: Kotor'), findsOneWidget);
        expect(find.textContaining('Marker 2'), findsNothing);
        expect(find.text('Marker 3: Budva'), findsOneWidget);
        for (final name in ['Kotor', 'Perast', 'Budva']) {
          expect(find.text(name), findsOneWidget);
        }
        expect(find.byKey(const Key('trip-picture-photo-2')), findsOneWidget);
        expect(find.byKey(const Key('trip-picture-photo-3')), findsNothing);
      });
    }

    testWidgets('passes the located stops to a still map', (tester) async {
      List<MapPoint>? passed;
      bool? passedInteractive;
      await pumpApp(
        tester,
        Center(
          child: TripPictureView(
            picture: picture,
            format: TripPictureFormat.story,
            photoFile: (path) => File('/nonexistent/$path'),
            routeMap:
                ({required points, required onOpenEntry, interactive = true}) {
                  passed = points;
                  passedInteractive = interactive;
                  return const SizedBox.expand();
                },
          ),
        ),
      );

      expect([for (final point in passed ?? []) point.number], [1, 3]);
      expect(passed?.first.location, picture.stops.first.location);
      expect(passedInteractive, isFalse);
    });

    testWidgets('shows a smaller, full-width map strip in the post format', (
      tester,
    ) async {
      await pumpPicture(tester, format: TripPictureFormat.post);

      final photos = tester.getRect(
        find.byKey(const Key('trip-picture-photos')),
      );
      final map = tester.getRect(find.byKey(const Key('trip-picture-route')));
      expect(map.height, lessThan(photos.height / 2));
      expect(map.width, closeTo(photos.width, 0.5));
    });

    testWidgets('shows no route without located stops', (tester) async {
      await pumpPicture(
        tester,
        content: TripPicture(
          title: 'Montenegro',
          startDate: DateTime.utc(2026, 9, 26),
          endDate: DateTime.utc(2026, 9, 30),
          dayCount: 5,
          stops: const [TripStop(name: 'Perast')],
          distanceMeters: 0,
          photoPaths: const [],
        ),
      );

      expect(find.byKey(const Key('trip-picture-route')), findsNothing);
      expect(find.text('Montenegro'), findsOneWidget);
      expect(find.text('5 days · 1 place'), findsOneWidget);
    });

    testWidgets('shows the Trailtale wordmark', (tester) async {
      await pumpPicture(tester);

      expect(find.text('Trailtale'), findsOneWidget);
    });
  });
}
