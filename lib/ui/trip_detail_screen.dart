import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../domain/delete_trip_with_entries.dart';
import '../domain/entry.dart';
import '../domain/trip.dart';
import '../domain/trip_day.dart';
import '../domain/trip_summary.dart';
import '../l10n/app_localizations.dart';
import 'app_services.dart';
import 'entry_form_screen.dart';
import 'formatting.dart';
import 'trip_form_screen.dart';
import 'widgets/photo_thumbnail.dart';
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
                SliverAppBar.large(
                  title: Text(current.title),
                  actions: [
                    IconButton(
                      tooltip: l10n.editTrip,
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => _openEditForm(context, current),
                    ),
                    IconButton(
                      tooltip: l10n.deleteTrip,
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _confirmDelete(context, current),
                    ),
                  ],
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
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tripDatesText(context, trip), style: textTheme.titleMedium),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Stat(
                key: const Key('summary-days'),
                value: '${summary.dayCount}',
                label: l10n.summaryDaysLabel(summary.dayCount),
              ),
              _Stat(
                key: const Key('summary-entries'),
                value: '${summary.entryCount}',
                label: l10n.summaryEntriesLabel(summary.entryCount),
              ),
              _Stat(
                key: const Key('summary-places'),
                value: '${summary.placeCount}',
                label: l10n.summaryPlacesLabel(summary.placeCount),
              ),
              _Stat(
                key: const Key('summary-photos'),
                value: '${summary.photoCount}',
                label: l10n.summaryPhotosLabel(summary.photoCount),
              ),
              _Stat(
                key: const Key('summary-distance'),
                value: formatKilometers(summary.distanceMeters, locale),
                label: l10n.summaryKilometersLabel,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A number with its label, e.g. "4" over "days".
class _Stat extends StatelessWidget {
  const _Stat({super.key, required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      constraints: const BoxConstraints(minWidth: 64),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: theme.textTheme.titleLarge),
          Text(label, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
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
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
      child: Text(
        switch (day.dayNumber) {
          final number? => l10n.tripDayHeader(number, day.day),
          null => l10n.otherDayHeader(day.day),
        },
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
        ),
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
    final textTheme = Theme.of(context).textTheme;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final time = DateFormat.jm(locale).format(entry.localDateTime);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(time, style: textTheme.labelLarge),
              if (entry.note.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(entry.note, style: textTheme.bodyLarge),
              ],
              if (entry.placeName case final placeName?) ...[
                const SizedBox(height: 4),
                _PlaceName(name: placeName),
              ],
              if (entry.photoPaths.isNotEmpty) ...[
                const SizedBox(height: 8),
                _PhotoStrip(files: entry.photoPaths.map(photoFile).toList()),
              ],
            ],
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

class _PlaceName extends StatelessWidget {
  const _PlaceName({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(
          Icons.place_outlined,
          size: 16,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 4),
        Expanded(child: Text(name, style: theme.textTheme.bodyMedium)),
      ],
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
