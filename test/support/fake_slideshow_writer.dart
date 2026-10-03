import 'dart:async';

import 'package:trailtale/domain/slideshow_document.dart';

/// [SlideshowWriter] for tests that records the documents it writes.
class FakeSlideshowWriter implements SlideshowWriter {
  /// Documents passed to [write], in order.
  final written = <SlideshowDocument>[];

  /// When set, [write] waits for it.
  Completer<void>? pending;

  /// Whether [write] throws.
  var fails = false;

  @override
  Future<List<int>> write(SlideshowDocument document) async {
    written.add(document);
    await pending?.future;
    if (fails) throw const FormatException('broken');
    return [37, 80, 68, 70];
  }
}
