import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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

  /// The trip as last saved here (day title photos change it).
  late Trip _trip = widget.trip;

  /// Photos deselected for this slideshow.
  final _excluded = <String>{};

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

  Slideshow _slideshow({required bool withExcluded}) => buildSlideshow(
    _trip,
    _entries,
    leaveOutEnds: _leaveOutEnds,
    excludedPhotos: withExcluded ? _excluded : const {},
  );

  /// “Day 2 · Kotor · Perast”, or the date for a day outside the trip.
  String _dayHeading(AppLocalizations l10n, DaySlide day) => [
    switch (day.dayNumber) {
      final number? => l10n.slideshowDayLabel(number),
      null => l10n.tripSingleDate(day.day),
    },
    ...day.places,
  ].join(' · ');

  Future<void> _chooseDayTitle(DaySlide day, List<String> photos) async {
    final l10n = AppLocalizations.of(context);
    final chosen = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text(
                l10n.slideshowChooseDayTitle(_dayHeading(l10n, day)),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Flexible(
              child: GridView.count(
                shrinkWrap: true,
                crossAxisCount: 3,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
                children: [
                  for (final path in photos)
                    GestureDetector(
                      key: Key('day-title-option-$path'),
                      onTap: () => Navigator.of(context).pop(path),
                      child: _Thumbnail(
                        file: widget.services.photoLibrary.fileFor(path),
                        selected: path == day.titlePhotoPath,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    if (chosen == null || !mounted) return;
    final changed = _trip.withDayCover(day.day, chosen);
    await widget.services.tripRepository.saveTrip(changed);
    if (!mounted) return;
    setState(() {
      _trip = changed;
      _excluded.remove(chosen);
    });
  }

  /// A day with several stops: an overview (“Day 2 · Perast → Kotor”, one
  /// line per stop with its time) next to the title photo, then each stop
  /// with its notes, its photo and its photo slides.
  DaySlideText _overviewSlide(
    AppLocalizations l10n,
    DaySlide day,
    String? Function(String?) absolute,
  ) {
    String time(DateTime value) =>
        DateFormat.jm(l10n.localeName).format(value);
    String stopHeading(int number, DayStop stop) => [
      '$number',
      ?stop.place,
    ].join(' · ');
    final label = switch (day.dayNumber) {
      final number? => l10n.slideshowDayLabel(number),
      null => l10n.tripSingleDate(day.day),
    };
    final places = [for (final stop in day.stops) ?stop.place];
    return DaySlideText(
      heading: places.isEmpty ? label : '$label · ${places.join(' → ')}',
      dateText: l10n.tripSingleDate(day.day),
      notes: [
        for (final (index, stop) in day.stops.indexed)
          '${stopHeading(index + 1, stop)} · ${time(stop.time)}',
      ],
      photoPath: absolute(day.titlePhotoPath),
      stops: [
        for (final (index, stop) in day.stops.indexed)
          DaySlideText(
            heading: stopHeading(index + 1, stop),
            dateText: time(stop.time),
            notes: [for (final note in stop.notes) _noteText(l10n, note)],
            photoPath: absolute(stop.photoPath),
            photos: [
              for (final photo in stop.photos)
                PhotoSlideText(photoPath: absolute(photo.path) ?? photo.path),
            ],
          ),
      ],
    );
  }

  /// “9:30 AM · Kotor – Arrival”, without place “9:30 AM – Car rental”.
  String _noteText(AppLocalizations l10n, DayNote note) {
    final time = DateFormat.jm(l10n.localeName).format(note.time);
    return switch (note.place) {
      final place? => l10n.slideshowNoteWithPlace(time, place, note.text),
      null => l10n.slideshowNote(time, note.text),
    };
  }

  /// The slideshow with all texts localized for the writer.
  SlideshowDocument _document(AppLocalizations l10n) {
    final trip = _trip;
    final slideshow = _slideshow(withExcluded: true);
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
      days: [
        for (final day in slideshow.days)
          if (day.stops.length > 1)
            _overviewSlide(l10n, day, absolute)
          else
            DaySlideText(
              heading: _dayHeading(l10n, day),
              dateText: l10n.tripSingleDate(day.day),
              notes: [for (final note in day.notes) _noteText(l10n, note)],
              photoPath: absolute(day.titlePhotoPath),
              photos: [
                for (final photo in day.photos)
                  PhotoSlideText(photoPath: absolute(photo.path) ?? photo.path),
              ],
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              l10n.slideshowPhotosHint,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          for (final day in _slideshow(withExcluded: false).days)
            _DayCard(
              heading: _dayHeading(l10n, day),
              day: day,
              titlePhoto: _slideshow(withExcluded: true).days
                  .where((shown) => shown.day == day.day)
                  .firstOrNull
                  ?.titlePhotoPath,
              excluded: _excluded,
              fileFor: widget.services.photoLibrary.fileFor,
              onChooseTitle: () => _chooseDayTitle(day, [
                ?day.titlePhotoPath,
                for (final photo in day.photos) photo.path,
              ]),
              onToggle: (path) => setState(() {
                if (!_excluded.remove(path)) _excluded.add(path);
              }),
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

class _DayCard extends StatelessWidget {
  const _DayCard({
    required this.heading,
    required this.day,
    required this.titlePhoto,
    required this.excluded,
    required this.fileFor,
    required this.onChooseTitle,
    required this.onToggle,
  });

  final String heading;

  /// The day with all its photos (nothing deselected).
  final DaySlide day;

  /// The title photo that will be used, `null` if none.
  final String? titlePhoto;
  final Set<String> excluded;
  final File Function(String path) fileFor;
  final VoidCallback onChooseTitle;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final photos = [
      ?day.titlePhotoPath,
      for (final photo in day.photos) photo.path,
    ];
    final dayKey = DateFormat('yyyy-MM-dd').format(day.day);
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Tooltip(
                  message: l10n.slideshowDayTitlePhoto,
                  child: GestureDetector(
                    key: Key('day-title-$dayKey'),
                    onTap: photos.isEmpty ? null : onChooseTitle,
                    child: SizedBox.square(
                      dimension: 64,
                      child: switch (titlePhoto) {
                        final path? => _Thumbnail(
                          file: fileFor(path),
                          selected: false,
                        ),
                        null => DecoratedBox(
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.photo_outlined,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(heading, style: theme.textTheme.titleMedium),
                ),
              ],
            ),
            if (photos.isNotEmpty) ...[
              const SizedBox(height: 10),
              SizedBox(
                height: 64,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: photos.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 6),
                  itemBuilder: (context, index) {
                    final path = photos[index];
                    final left = excluded.contains(path);
                    return GestureDetector(
                      key: Key('slide-photo-$path'),
                      onTap: () => onToggle(path),
                      child: Opacity(
                        opacity: left ? 0.35 : 1,
                        child: SizedBox.square(
                          dimension: 64,
                          child: _Thumbnail(
                            file: fileFor(path),
                            selected: !left,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.file, required this.selected});

  final File file;

  /// Whether the photo is part of the slideshow (shows a check mark).
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image(
            image: ResizeImage(FileImage(file), width: 240),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => ColoredBox(
              color: colorScheme.surfaceContainerHighest,
              child: Icon(
                Icons.broken_image_outlined,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          if (selected)
            Positioned(
              top: 4,
              right: 4,
              child: CircleAvatar(
                radius: 9,
                backgroundColor: colorScheme.primary,
                child: Icon(
                  Icons.check,
                  size: 12,
                  color: colorScheme.onPrimary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
