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
/// slide over the cover photo, per day a day slide over its title photo
/// followed by one slide per photo, and a closing slide with all stops.
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
      pdf.addPage(
        _page(
          await _photo(day.photoPath),
          (photo) => _DaySlide(day, heading: heading, onPhoto: photo),
        ),
      );
      for (final slide in day.photos) {
        // A photo that cannot be read gets no slide.
        if (await _photo(slide.photoPath) case final photo?) {
          pdf.addPage(_photoPage(photo, slide.caption));
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

  /// The whole photo on the ink color, with its caption on a translucent
  /// band.
  pw.Page _photoPage(pw.ImageProvider photo, String? caption) => pw.Page(
    pageFormat: _format,
    margin: pw.EdgeInsets.zero,
    build: (context) => pw.Stack(
      fit: pw.StackFit.expand,
      children: [
        pw.Container(color: _Colors.ink),
        pw.Center(child: pw.Image(photo, fit: pw.BoxFit.contain)),
        if (caption != null)
          pw.Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: pw.Stack(
              children: [
                pw.Positioned.fill(
                  child: pw.Opacity(
                    opacity: 0.6,
                    child: pw.Container(color: _Colors.shade),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 18,
                  ),
                  child: pw.Text(
                    caption,
                    maxLines: 2,
                    style: const pw.TextStyle(
                      fontSize: 18,
                      color: _Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
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

class _DaySlide extends pw.StatelessWidget {
  _DaySlide(this.day, {required this.heading, required this.onPhoto});

  final DaySlideText day;
  final pw.TextStyle heading;
  final bool onPhoto;

  @override
  pw.Widget build(pw.Context context) {
    final card = pw.Container(
      width: onPhoto ? 460 : 780,
      padding: const pw.EdgeInsets.all(28),
      decoration: pw.BoxDecoration(
        color: onPhoto ? _Colors.card : null,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(18)),
      ),
      child: pw.Column(
        mainAxisSize: pw.MainAxisSize.min,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(width: 40, height: 4, color: _Colors.clay),
          pw.SizedBox(height: 12),
          pw.Text(
            day.heading,
            maxLines: 2,
            style: heading.copyWith(
              fontSize: onPhoto ? 36 : 52,
              color: _Colors.ink,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            day.dateText,
            style: const pw.TextStyle(fontSize: 16, color: _Colors.muted),
          ),
          for (final note in day.notes) ...[
            pw.SizedBox(height: 10),
            pw.Text(
              note,
              maxLines: 3,
              style: const pw.TextStyle(fontSize: 16, color: _Colors.ink),
            ),
          ],
        ],
      ),
    );
    return pw.Padding(
      padding: const pw.EdgeInsets.all(40),
      child: pw.Align(
        alignment: onPhoto ? pw.Alignment.bottomLeft : pw.Alignment.centerLeft,
        child: card,
      ),
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
