import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../domain/delete_trip_with_entries.dart';
import '../domain/entry.dart';
import '../domain/route_places.dart';
import '../domain/trip.dart';
import '../domain/trip_day.dart';
import '../domain/trip_overview.dart';
import '../domain/trip_summary.dart';
import '../l10n/app_localizations.dart';
import 'app_services.dart';
import 'entry_form_screen.dart';
import 'formatting.dart';
import 'trip_form_screen.dart';
import 'widgets/photo_thumbnail.dart';
import 'widgets/stat_tile.dart';
import 'widgets/trip_cover.dart';
import 'widgets/trip_dates.dart';

/// Shows one trip with its dates and entries, and offers editing and
/// deleting it.
class TripDetailScreen extends StatelessWidget {
  const TripDetailScreen({
    super.key,
    required this.services,
    required this.trip,
  });

  final AppServices services;

  /// The trip as it was when the screen was opened; updates come from the
  /// repository.
  final Trip trip;

  Stream<Trip?> _watchTrip() => services.tripRepository.watchTrips().map(
    (trips) => trips.where((stored) => stored.id == trip.id).firstOrNull,
  );

  void _openEditForm(BuildContext context, Trip current) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TripFormScreen(services: services, trip: current),
      ),
    );
  }

  void _openEntryForm(BuildContext context, Trip current, [Entry? entry]) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            EntryFormScreen(services: services, trip: current, entry: entry),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Trip current) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => _DeleteTripDialog(title: current.title),
    );
    if (confirmed != true) return;
    await deleteTripWithEntries(
      tripRepository: services.tripRepository,
      entryRepository: services.entryRepository,
      photoLibrary: services.photoLibrary,
      tripId: current.id,
    );
    if (!context.mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return StreamBuilder<Trip?>(
      initialData: trip,
      stream: _watchTrip(),
      builder: (context, snapshot) {
        final current = snapshot.data;
        if (current == null) return const Scaffold();
        return Scaffold(
          body: StreamBuilder<List<Entry>>(
            stream: services.entryRepository.watchEntries(current.id),
            builder: (context, entriesSnapshot) => CustomScrollView(
              slivers: [
                SliverAppBar(
                  pinned: true,
                  expandedHeight: 240,
                  automaticallyImplyLeading: false,
                  leading: Center(
                    child: _RoundButton(
                      tooltip: MaterialLocalizations.of(context)
                          .backButtonTooltip,
                      icon: Icons.arrow_back,
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                  ),
                  actions: [
                    _RoundButton(
                      tooltip: l10n.editTrip,
                      icon: Icons.edit_outlined,
                      onPressed: () => _openEditForm(context, current),
                    ),
                    const SizedBox(width: 8),
                    _RoundButton(
                      tooltip: l10n.deleteTrip,
                      icon: Icons.delete_outline,
                      onPressed: () => _confirmDelete(context, current),
                    ),
                    const SizedBox(width: 12),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    background: TripCover(
                      file: switch (coverPhotoOf(
                        entriesSnapshot.data ?? const [],
                      )) {
                        final path? => services.photoLibrary.fileFor(path),
                        null => null,
                      },
                    ),
                  ),
                  bottom: const PreferredSize(
                    preferredSize: Size.fromHeight(28),
                    child: _SheetEdge(),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _TripHeader(
                    trip: current,
                    entries: entriesSnapshot.data ?? const [],
                  ),
                ),
                _EntryList(
                  trip: current,
                  entries: entriesSnapshot.data,
                  onOpen: (entry) => _openEntryForm(context, current, entry),
                  photoFile: services.photoLibrary.fileFor,
                ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _openEntryForm(context, current),
            icon: const Icon(Icons.add),
            label: Text(l10n.newEntry),
          ),
        );
      },
    );
  }
}

class _TripHeader extends StatelessWidget {
  const _TripHeader({required this.trip, required this.entries});

  final Trip trip;
  final List<Entry> entries;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final textTheme = Theme.of(context).textTheme;
    final summary = summarizeTrip(trip, entries);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(trip.title, style: textTheme.headlineMedium),
          const SizedBox(height: 4),
          Text(
            tripDatesText(context, trip),
            style: textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              StatTile(
                key: const Key('summary-days'),
                value: '${summary.dayCount}',
                label: l10n.summaryDaysLabel(summary.dayCount),
              ),
              StatTile(
                key: const Key('summary-entries'),
                value: '${summary.entryCount}',
                label: l10n.summaryEntriesLabel(summary.entryCount),
              ),
              StatTile(
                key: const Key('summary-places'),
                value: '${summary.placeCount}',
                label: l10n.summaryPlacesLabel(summary.placeCount),
              ),
              StatTile(
                key: const Key('summary-photos'),
                value: '${summary.photoCount}',
                label: l10n.summaryPhotosLabel(summary.photoCount),
              ),
              StatTile(
                key: const Key('summary-distance'),
                value: formatKilometers(summary.distanceMeters, locale),
                label: l10n.summaryKilometersLabel,
              ),
            ],
          ),
          if (routePlaces(entries) case final places
              when places.length > 1) ...[
            const SizedBox(height: 16),
            _RouteStrip(places: places),
          ],
        ],
      ),
    );
  }
}

/// The start of the content sheet with rounded corners over the cover.
class _SheetEdge extends StatelessWidget {
  const _SheetEdge();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
    );
  }
}

/// A round icon button that stays readable on top of a photo.
class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return IconButton.filled(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon),
      style: IconButton.styleFrom(
        backgroundColor: scheme.surfaceContainerLowest,
        foregroundColor: scheme.onSurface,
      ),
    );
  }
}

/// The places of the trip in visiting order, joined by dotted lines.
class _RouteStrip extends StatelessWidget {
  const _RouteStrip({required this.places});

  static const maxShown = 4;

  final List<String> places;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.labelLarge?.copyWith(
      color: theme.colorScheme.onInverseSurface,
    );
    final shown = places.take(maxShown).toList();
    final hidden = places.length - shown.length;
    return Container(
      key: const Key('route-strip'),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.inverseSurface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          for (final (index, place) in shown.indexed) ...[
            if (index > 0) _DottedConnector(color: theme.colorScheme.tertiary),
            Flexible(
              child: Text(
                place,
                style: style,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
          if (hidden > 0) ...[
            _DottedConnector(color: theme.colorScheme.tertiary),
            Text(AppLocalizations.of(context).morePlaces(hidden), style: style),
          ],
        ],
      ),
    );
  }
}

class _DottedConnector extends StatelessWidget {
  const _DottedConnector({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: CustomPaint(
          size: const Size.fromHeight(4),
          painter: _DotsPainter(color: color, axis: Axis.horizontal),
        ),
      ),
    );
  }
}

/// Paints a dotted (horizontal) or dashed (vertical) line through the middle
/// of its box.
class _DotsPainter extends CustomPainter {
  const _DotsPainter({required this.color, required this.axis});

  final Color color;
  final Axis axis;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    if (axis == Axis.horizontal) {
      final y = size.height / 2;
      for (var x = 1.0; x < size.width; x += 6) {
        canvas.drawLine(
          Offset(x, y),
          Offset(x + 0.1, y),
          paint..strokeWidth = 3,
        );
      }
    } else {
      for (var y = 0.0; y < size.height; y += 10) {
        canvas.drawLine(Offset(1, y), Offset(1, y + 5), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DotsPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.axis != axis;
}

class _EntryList extends StatelessWidget {
  const _EntryList({
    required this.trip,
    required this.entries,
    required this.onOpen,
    required this.photoFile,
  });

  final Trip trip;

  /// The trip's entries; `null` while they are loading.
  final List<Entry>? entries;
  final ValueChanged<Entry> onOpen;
  final File Function(String relativePath) photoFile;

  @override
  Widget build(BuildContext context) {
    return switch (entries) {
      null => const SliverToBoxAdapter(),
      [] => const _NoEntries(),
      final entries => _TimelineList(
        items: [
          for (final day in groupEntriesByDay(trip, entries)) ...[
            _DayHeaderItem(day),
            for (final entry in day.entries) _EntryItem(entry),
          ],
        ],
        onOpen: onOpen,
        photoFile: photoFile,
      ),
    };
  }
}

/// One row of the timeline: a day header or an entry.
sealed class _TimelineItem {
  const _TimelineItem();
}

class _DayHeaderItem extends _TimelineItem {
  const _DayHeaderItem(this.day);

  final TripDay day;
}

class _EntryItem extends _TimelineItem {
  const _EntryItem(this.entry);

  final Entry entry;
}

class _TimelineList extends StatelessWidget {
  const _TimelineList({
    required this.items,
    required this.onOpen,
    required this.photoFile,
  });

  final List<_TimelineItem> items;
  final ValueChanged<Entry> onOpen;
  final File Function(String relativePath) photoFile;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 104),
      sliver: SliverList.builder(
        itemCount: items.length,
        itemBuilder: (context, index) => switch (items[index]) {
          _DayHeaderItem(:final day) => _DayHeader(day: day),
          _EntryItem(:final entry) => _EntryCard(
            entry: entry,
            onTap: () => onOpen(entry),
            photoFile: photoFile,
          ),
        },
      ),
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.day});

  final TripDay day;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final number = day.dayNumber;
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: scheme.inverseSurface,
              shape: BoxShape.circle,
            ),
            child: number == null
                ? Icon(Icons.event, size: 20, color: scheme.onInverseSurface)
                : Text(
                    number.toString(),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: scheme.onInverseSurface,
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: number == null
                ? Text(
                    l10n.otherDayHeader(day.day),
                    style: theme.textTheme.titleSmall,
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.tripDayTitle(number),
                        style: theme.textTheme.titleSmall,
                      ),
                      Text(
                        l10n.tripDayDate(day.day),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _EntryCard extends StatelessWidget {
  const _EntryCard({
    required this.entry,
    required this.onTap,
    required this.photoFile,
  });

  final Entry entry;
  final VoidCallback onTap;
  final File Function(String relativePath) photoFile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final time = DateFormat.jm(locale).format(entry.localDateTime);
    return Padding(
      padding: const EdgeInsets.only(left: 19),
      child: CustomPaint(
        painter: _DotsPainter(
          color: theme.colorScheme.outlineVariant,
          axis: Axis.vertical,
        ),
        child: Padding(
          padding: const EdgeInsets.only(left: 29, bottom: 6),
          child: Card(
            margin: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      time,
                      style: textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    if (entry.note.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(entry.note, style: textTheme.bodyLarge),
                    ],
                    if (entry.placeName case final placeName?) ...[
                      const SizedBox(height: 8),
                      _PlaceChip(name: placeName),
                    ],
                    if (entry.photoPaths.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      _PhotoStrip(
                        files: entry.photoPaths.map(photoFile).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PhotoStrip extends StatelessWidget {
  const _PhotoStrip({required this.files});

  static const maxShown = 4;
  static const size = 64.0;

  final List<File> files;

  @override
  Widget build(BuildContext context) {
    final hidden = files.length - maxShown;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final file in files.take(maxShown))
          PhotoThumbnail(file: file, size: size),
        if (hidden > 0) _MorePhotos(count: hidden),
      ],
    );
  }
}

class _MorePhotos extends StatelessWidget {
  const _MorePhotos({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      constraints: const BoxConstraints(
        minWidth: _PhotoStrip.size,
        minHeight: _PhotoStrip.size,
      ),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        AppLocalizations.of(context).morePhotos(count),
        style: theme.textTheme.titleMedium?.copyWith(
          color: theme.colorScheme.onSecondaryContainer,
        ),
      ),
    );
  }
}

class _PlaceChip extends StatelessWidget {
  const _PlaceChip({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.onSecondaryContainer;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.place_outlined, size: 14, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              name,
              style: theme.textTheme.labelLarge?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoEntries extends StatelessWidget {
  const _NoEntries();

  @override
  Widget build(BuildContext context) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            AppLocalizations.of(context).noEntriesYet,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ),
    );
  }
}

class _DeleteTripDialog extends StatelessWidget {
  const _DeleteTripDialog({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.deleteTripQuestion(title)),
      content: Text(l10n.deleteTripWarning),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.delete),
        ),
      ],
    );
  }
}
