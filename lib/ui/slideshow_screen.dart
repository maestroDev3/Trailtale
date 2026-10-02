import 'dart:async';

import 'package:flutter/material.dart';

import '../domain/entry.dart';
import '../domain/slideshow.dart';
import '../domain/slideshow_document.dart';
import '../domain/trip.dart';
import '../l10n/app_localizations.dart';
import 'app_services.dart';
import 'formatting.dart';
import 'widgets/trip_dates.dart';

/// Creates the slideshow of [trip] as a PDF and opens the share sheet.
class SlideshowScreen extends StatefulWidget {
  const SlideshowScreen({
    super.key,
    required this.services,
    required this.trip,
  });

  final AppServices services;
  final Trip trip;

  @override
  State<SlideshowScreen> createState() => _SlideshowScreenState();
}

class _SlideshowScreenState extends State<SlideshowScreen> {
  late final StreamSubscription<List<Entry>> _entriesSubscription;
  var _entries = const <Entry>[];
  var _leaveOutEnds = false;
  var _creating = false;

  @override
  void initState() {
    super.initState();
    _entriesSubscription = widget.services.entryRepository
        .watchEntries(widget.trip.id)
        .listen((entries) => setState(() => _entries = entries));
  }

  @override
  void dispose() {
    unawaited(_entriesSubscription.cancel());
    super.dispose();
  }

  /// The slideshow with all texts localized for the writer.
  SlideshowDocument _document(AppLocalizations l10n) {
    final trip = widget.trip;
    final slideshow = buildSlideshow(
      trip,
      _entries,
      leaveOutEnds: _leaveOutEnds,
    );
    String? absolute(String? path) => switch (path) {
      final relative? => widget.services.photoLibrary.fileFor(relative).path,
      null => null,
    };
    return SlideshowDocument(
      title: trip.title,
      dateText: dateRangeText(context, trip.startDate, trip.endDate),
      factsText: pictureFactsText(l10n, slideshow.overview),
      coverPhotoPath: absolute(slideshow.coverPhotoPath),
      stops: [
        for (final stop in slideshow.stops)
          SlideText(
            number: stop.number,
            name: stop.name,
            dateText: l10n.tripSingleDate(stop.firstVisit),
            notes: stop.notes,
            photoPath: absolute(stop.photoPath),
          ),
      ],
      closingTitle: l10n.slideshowRouteTitle,
      wordmark: l10n.appTitle,
    );
  }

  Future<void> _create() async {
    final l10n = AppLocalizations.of(context);
    final services = widget.services;
    final document = _document(l10n);
    setState(() => _creating = true);
    try {
      final bytes = await services.slideshowWriter.write(document);
      final file = await services.temporaryFiles.write(
        '${widget.trip.title}.pdf',
        bytes,
      );
      await services.fileSharer.shareFile(file, subject: widget.trip.title);
    } on Exception {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.slideshowFailed)));
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.shareOptionSlideshow)),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              l10n.slideshowDescription,
              style: theme.textTheme.bodyLarge,
            ),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            title: Text(l10n.pictureLeaveOutEnds),
            value: _leaveOutEnds,
            onChanged: _creating
                ? null
                : (value) => setState(() => _leaveOutEnds = value),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: FilledButton.icon(
            onPressed: _creating ? null : _create,
            icon: _creating
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.picture_as_pdf_outlined),
            label: Text(_creating ? l10n.creatingPdf : l10n.createPdf),
          ),
        ),
      ),
    );
  }
}
