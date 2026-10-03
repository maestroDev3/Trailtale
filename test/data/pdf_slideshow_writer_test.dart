import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:trailtale/data/pdf_slideshow_writer.dart';
import 'package:trailtale/domain/slideshow_document.dart';

/// Returns a tiny JPEG for every path except `missing`, and records calls.
class FakePhotoShrinker implements PhotoShrinker {
  final calls = <(String, int)>[];

  @override
  Future<List<int>?> shrink(String path, {required int maxSide}) async {
    calls.add((path, maxSide));
    if (path.contains('missing')) return null;
    return img.encodeJpg(img.Image(width: 4, height: 3));
  }
}

void main() {
  const document = SlideshowDocument(
    title: 'Montenegro',
    dateText: 'Sep 26 - Sep 30, 2026',
    factsText: '5 days - 3 places - 16 km',
    coverPhotoPath: '/photos/cover.jpg',
    stops: [
      SlideText(number: 1, name: 'Kotor', dateText: '', notes: []),
      SlideText(number: 2, name: 'Perast', dateText: '', notes: []),
      SlideText(number: 3, name: 'Budva', dateText: '', notes: []),
    ],
    days: [
      DaySlideText(
        heading: 'Day 1 - Kotor',
        dateText: 'Sep 27, 2026',
        notes: ['Old town walls'],
        photoPath: '/photos/kotor.jpg',
        photos: [
          PhotoSlideText(photoPath: '/photos/cats.jpg', caption: 'Cats here'),
        ],
      ),
      DaySlideText(
        heading: 'Day 2 - Perast - Budva',
        dateText: 'Sep 28, 2026',
        notes: [],
        photoPath: '/photos/missing.jpg',
        photos: [
          PhotoSlideText(photoPath: '/photos/beach.jpg', caption: 'Beach'),
          PhotoSlideText(photoPath: '/photos/sunset.jpg'),
        ],
      ),
    ],
    closingTitle: 'The route',
    wordmark: 'Trailtale',
  );

  int pages(String pdf) =>
      RegExp(r'/Type\s*/Page(?![s])').allMatches(pdf).length;

  Future<String> writePdf(FakePhotoShrinker shrinker) async {
    final bytes = await PdfSlideshowWriter(
      shrinker: shrinker,
      compress: false,
    ).write(document);
    return latin1.decode(bytes);
  }

  group('PdfSlideshowWriter', () {
    test('writes a title slide, per day a day slide and its photo slides, '
        'and a closing slide', () async {
      final pdf = await writePdf(FakePhotoShrinker());

      expect(pdf, startsWith('%PDF'));
      expect(pages(pdf), 1 + (1 + 1) + (1 + 2) + 1);
    });

    test('skips a photo slide whose photo cannot be read', () async {
      final bytes =
          await PdfSlideshowWriter(
            shrinker: FakePhotoShrinker(),
            compress: false,
          ).write(
            const SlideshowDocument(
              title: 'Montenegro',
              dateText: '',
              factsText: '',
              stops: [],
              days: [
                DaySlideText(
                  heading: 'Day 1',
                  dateText: '',
                  notes: [],
                  photos: [
                    PhotoSlideText(photoPath: '/photos/missing.jpg'),
                    PhotoSlideText(photoPath: '/photos/beach.jpg'),
                  ],
                ),
              ],
              closingTitle: 'The route',
              wordmark: 'Trailtale',
            ),
          );

      expect(pages(latin1.decode(bytes)), 1 + (1 + 1) + 1);
    });

    test('uses 16:9 pages of 960 × 540 points', () async {
      final pdf = await writePdf(FakePhotoShrinker());

      final boxes = RegExp(r'/MediaBox\s*\[([^\]]*)\]').allMatches(pdf);
      expect(boxes, hasLength(7));
      for (final box in boxes) {
        expect(box.group(1)?.trim().split(RegExp(r'\s+')), [
          '0',
          '0',
          '960',
          '540',
        ]);
      }
    });

    test('contains the texts of the document', () async {
      final pdf = await writePdf(FakePhotoShrinker());

      for (final text in [
        'Montenegro',
        'Day 1 - Kotor',
        'Day 2 - Perast - Budva',
        'Old town walls',
        'Sep 27, 2026',
        'Cats here',
        'Beach',
        'The route',
        'Trailtale',
      ]) {
        // The PDF writes every word on its own.
        for (final word in text.split(' ')) {
          expect(pdf, contains('($word)'), reason: text);
        }
      }
    });

    test('shrinks every photo to at most 1600 pixels', () async {
      final shrinker = FakePhotoShrinker();

      await writePdf(shrinker);

      expect(shrinker.calls, [
        ('/photos/cover.jpg', 1600),
        ('/photos/kotor.jpg', 1600),
        ('/photos/cats.jpg', 1600),
        ('/photos/missing.jpg', 1600),
        ('/photos/beach.jpg', 1600),
        ('/photos/sunset.jpg', 1600),
      ]);
    });

    test('covers no photo with an opaque shading', () async {
      final pdf = await writePdf(FakePhotoShrinker());

      expect(pdf, isNot(contains('/ShadingType')));
    });

    test('puts the title on a translucent band', () async {
      final pdf = await writePdf(FakePhotoShrinker());

      final alphas = RegExp(r'/ca\s+([0-9.]+)')
          .allMatches(pdf)
          .map((match) => double.parse(match.group(1) ?? '1'));
      expect(alphas.any((alpha) => alpha < 1), isTrue);
    });

    test('shows photo slides whole on the ink color', () async {
      final pdf = await writePdf(FakePhotoShrinker());

      // The ink color 0x1F3B34 as fill: 0.12157 0.23137 0.20392 rg.
      expect(pdf, contains('0.12157 0.23137 0.20392 rg'));
    });

    test('embeds the photos it could read', () async {
      final pdf = await writePdf(FakePhotoShrinker());

      expect(RegExp(r'/Subtype\s*/Image').allMatches(pdf), hasLength(5));
    });

    test('writes the PDF with the bundled fonts, incl. accents', () async {
      ByteData font(String name) =>
          ByteData.sublistView(File('assets/fonts/$name').readAsBytesSync());
      final bytes =
          await PdfSlideshowWriter(
            shrinker: FakePhotoShrinker(),
            compress: false,
            loadFonts: () async => (
              display: font('Fraunces-SemiBold.ttf'),
              text: font('Manrope-Regular.ttf'),
              bold: font('Manrope-Bold.ttf'),
            ),
          ).write(
            const SlideshowDocument(
              title: 'Čanj – Petrovac',
              dateText: 'Sep 26 – Oct 6, 2026',
              factsText: '12 days · 4 places · 49 km',
              stops: [
                SlideText(number: 1, name: 'Čanj', dateText: '', notes: []),
              ],
              days: [
                DaySlideText(
                  heading: 'Day 7 · Čanj',
                  dateText: 'Oct 1, 2026',
                  notes: ['Plaža'],
                ),
              ],
              closingTitle: 'The route',
              wordmark: 'Trailtale',
            ),
          );
      final pdf = latin1.decode(bytes);

      expect(RegExp(r'/Type\s*/Page(?![s])').allMatches(pdf), hasLength(3));
      expect(pdf, contains('/FontFile2'));
    });
  });
}
