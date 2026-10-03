import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../domain/slideshow_document.dart';

/// The field journal colors, as in the app's theme.
abstract final class _Colors {
  static const paper = PdfColor.fromInt(0xFFF6F1E7);
  static const card = PdfColor.fromInt(0xFFFFFDF8);
  static const ink = PdfColor.fromInt(0xFF1F3B34);
  static const clay = PdfColor.fromInt(0xFFB84A22);
  static const sea = PdfColor.fromInt(0xFF2F6F7E);
  static const muted = PdfColor.fromInt(0xFF56645F);
  static const white = PdfColor.fromInt(0xFFFFFFFF);
  static const shade = PdfColor.fromInt(0xFF141C19);
}

/// The fonts of the slideshow; without them the PDF uses Helvetica.
typedef SlideshowFonts = ({ByteData display, ByteData text, ByteData bold});

/// Lays out a [SlideshowDocument] as a 16:9 PDF (package `pdf`): a title
/// slide over the cover photo, per day a day slide (notes next to its title
/// photo, more notes on continuation slides) followed by one slide per
/// photo, and a closing slide with all stops.
class PdfSlideshowWriter implements SlideshowWriter {
  PdfSlideshowWriter({
    required this.shrinker,
    this.loadFonts,
    this.compress = true,
  });

  final PhotoShrinker shrinker;

  /// Loads the bundled fonts (Fraunces for headings, Manrope for text).
  final Future<SlideshowFonts> Function()? loadFonts;

  /// Whether page contents are compressed (switched off in tests).
  final bool compress;

  /// Longest side of embedded photos in pixels.
  static const photoMaxSide = 1600;

  static const _format = PdfPageFormat(960, 540);

  /// Most notes on one day slide; more continue on the next slide.
  static const notesPerSlide = 6;

  @override
  Future<List<int>> write(SlideshowDocument document) async {
    final fonts = await loadFonts?.call();
    final display = fonts == null ? null : pw.Font.ttf(fonts.display);
    final text = fonts == null ? null : pw.Font.ttf(fonts.text);
    final bold = fonts == null ? null : pw.Font.ttf(fonts.bold);
    final pdf = pw.Document(
      compress: compress,
      title: document.title,
      creator: document.wordmark,
      theme: fonts == null
          ? null
          : pw.ThemeData.withFont(base: text, bold: bold),
    );
    final heading = pw.TextStyle(font: display, fontBold: display);

    pdf.addPage(
      _page(
        await _photo(document.coverPhotoPath),
        (photo) => _TitleSlide(document, heading: heading, onPhoto: photo),
      ),
    );
    for (final day in document.days) {
      final photo = await _photo(day.photoPath);
      final chunks = [
        for (var start = 0; start < day.notes.length; start += notesPerSlide)
          day.notes.skip(start).take(notesPerSlide).toList(),
      ];
      // The first slide shows the title photo next to the notes; further
      // notes continue on paper.
      for (final (index, notes) in (chunks.isEmpty ? [<String>[]] : chunks)
          .indexed) {
        pdf.addPage(
          pw.Page(
            pageFormat: _format,
            margin: pw.EdgeInsets.zero,
            build: (context) => _DaySlide(
              day,
              notes: notes,
              heading: heading,
              photo: index == 0 ? photo : null,
            ),
          ),
        );
      }
      for (final slide in day.photos) {
        // A photo that cannot be read gets no slide.
        if (await _photo(slide.photoPath) case final photo?) {
          pdf.addPage(_photoPage(photo));
        }
      }
    }
    pdf.addPage(_page(null, (_) => _ClosingSlide(document, heading: heading)));
    return pdf.save();
  }

  Future<pw.MemoryImage?> _photo(String? path) async {
    if (path == null) return null;
    final jpeg = await shrinker.shrink(path, maxSide: photoMaxSide);
    return jpeg == null ? null : pw.MemoryImage(Uint8List.fromList(jpeg));
  }

  /// The whole photo on the ink color, without text.
  pw.Page _photoPage(pw.ImageProvider photo) => pw.Page(
    pageFormat: _format,
    margin: pw.EdgeInsets.zero,
    build: (context) => pw.Stack(
      fit: pw.StackFit.expand,
      children: [
        pw.Container(color: _Colors.ink),
        pw.Center(child: pw.Image(photo, fit: pw.BoxFit.contain)),
      ],
    ),
  );

  /// A full page: the photo (cover) or paper behind the slide's content.
  pw.Page _page(
    pw.ImageProvider? photo,
    pw.Widget Function(bool onPhoto) content,
  ) => pw.Page(
    pageFormat: _format,
    margin: pw.EdgeInsets.zero,
    build: (context) => pw.Stack(
      fit: pw.StackFit.expand,
      children: [
        if (photo == null)
          pw.Container(color: _Colors.paper)
        else
          // No gradient: PDF shadings have no alpha and would cover the
          // photo completely (#195).
          pw.Image(photo, fit: pw.BoxFit.cover),
        content(photo != null),
      ],
    ),
  );
}

class _TitleSlide extends pw.StatelessWidget {
  _TitleSlide(this.document, {required this.heading, required this.onPhoto});

  final SlideshowDocument document;
  final pw.TextStyle heading;
  final bool onPhoto;

  @override
  pw.Widget build(pw.Context context) {
    final color = onPhoto ? _Colors.white : _Colors.ink;
    final text = pw.Padding(
      padding: const pw.EdgeInsets.all(56),
      child: pw.Column(
        mainAxisAlignment: pw.MainAxisAlignment.end,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            document.title,
            maxLines: 2,
            style: heading.copyWith(fontSize: 60, color: color),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            document.dateText,
            style: pw.TextStyle(fontSize: 22, color: color),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            document.factsText,
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: onPhoto ? _Colors.white : _Colors.sea,
            ),
          ),
        ],
      ),
    );
    if (!onPhoto) return text;
    // A translucent band keeps the title readable on any photo.
    return pw.Stack(
      fit: pw.StackFit.expand,
      children: [
        pw.Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: pw.Opacity(
            opacity: 0.55,
            child: pw.Container(height: 230, color: _Colors.shade),
          ),
        ),
        text,
      ],
    );
  }
}

/// The day's story: a paper panel with heading, date and notes, the title
/// photo uncovered to its right (the panel spans the slide without photo).
class _DaySlide extends pw.StatelessWidget {
  _DaySlide(
    this.day, {
    required this.notes,
    required this.heading,
    required this.photo,
  });

  final DaySlideText day;
  final List<String> notes;
  final pw.TextStyle heading;
  final pw.ImageProvider? photo;

  @override
  pw.Widget build(pw.Context context) {
    final photo = this.photo;
    final panel = pw.Container(
      width: photo == null ? null : 400,
      color: _Colors.paper,
      padding: const pw.EdgeInsets.fromLTRB(44, 48, 36, 40),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(width: 40, height: 4, color: _Colors.clay),
          pw.SizedBox(height: 14),
          pw.Text(
            day.heading,
            maxLines: 2,
            style: heading.copyWith(fontSize: 32, color: _Colors.ink),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            day.dateText,
            style: const pw.TextStyle(fontSize: 15, color: _Colors.muted),
          ),
          pw.SizedBox(height: 18),
          for (final note in notes) ...[
            pw.Text(
              note,
              maxLines: 3,
              style: const pw.TextStyle(fontSize: 15, color: _Colors.ink),
            ),
            pw.SizedBox(height: 10),
          ],
        ],
      ),
    );
    if (photo == null) return pw.Row(children: [pw.Expanded(child: panel)]);
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        panel,
        pw.Expanded(child: pw.Image(photo, fit: pw.BoxFit.cover)),
      ],
    );
  }
}

class _ClosingSlide extends pw.StatelessWidget {
  _ClosingSlide(this.document, {required this.heading});

  final SlideshowDocument document;
  final pw.TextStyle heading;

  @override
  pw.Widget build(pw.Context context) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(56),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            document.closingTitle,
            style: heading.copyWith(fontSize: 44, color: _Colors.ink),
          ),
          pw.SizedBox(height: 24),
          pw.Expanded(
            child: pw.Wrap(
              direction: pw.Axis.vertical,
              spacing: 10,
              runSpacing: 40,
              children: [
                for (final stop in document.stops)
                  pw.SizedBox(
                    width: 260,
                    child: pw.Row(
                      children: [
                        pw.SizedBox(
                          width: 32,
                          child: pw.Text(
                            '${stop.number}',
                            style: pw.TextStyle(
                              fontSize: 18,
                              fontWeight: pw.FontWeight.bold,
                              color: _Colors.clay,
                            ),
                          ),
                        ),
                        pw.Expanded(
                          child: pw.Text(
                            stop.name,
                            maxLines: 1,
                            style: const pw.TextStyle(
                              fontSize: 18,
                              color: _Colors.ink,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Expanded(
                child: pw.Text(
                  document.factsText,
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: _Colors.sea,
                  ),
                ),
              ),
              pw.Text(
                document.wordmark,
                style: heading.copyWith(fontSize: 22, color: _Colors.ink),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
