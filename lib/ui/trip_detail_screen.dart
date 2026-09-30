import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../domain/delete_trip_with_entries.dart';
import '../domain/entry.dart';
import '../domain/trip.dart';
import '../l10n/app_localizations.dart';
import 'app_services.dart';
import 'entry_form_screen.dart';
import 'trip_form_screen.dart';
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
          body: CustomScrollView(
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
              SliverToBoxAdapter(child: _TripHeader(trip: current)),
              _EntryList(
                entries: services.entryRepository.watchEntries(current.id),
                onOpen: (entry) => _openEntryForm(context, current, entry),
              ),
            ],
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
  const _TripHeader({required this.trip});

  final Trip trip;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tripDatesText(context, trip), style: textTheme.titleMedium),
          Text(
            AppLocalizations.of(context).tripDayCount(trip.dayCount),
            style: textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _EntryList extends StatelessWidget {
  const _EntryList({required this.entries, required this.onOpen});

  final Stream<List<Entry>> entries;
  final ValueChanged<Entry> onOpen;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Entry>>(
      stream: entries,
      builder: (context, snapshot) => switch (snapshot) {
        AsyncSnapshot(:final data?) when data.isNotEmpty => SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
          sliver: SliverList.builder(
            itemCount: data.length,
            itemBuilder: (context, index) {
              final entry = data[index];
              return _EntryCard(entry: entry, onTap: () => onOpen(entry));
            },
          ),
        ),
        AsyncSnapshot(:final data?) when data.isEmpty => const _NoEntries(),
        _ => const SliverToBoxAdapter(),
      },
    );
  }
}

class _EntryCard extends StatelessWidget {
  const _EntryCard({required this.entry, required this.onTap});

  final Entry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final time = DateFormat.yMMMd(locale).add_jm().format(entry.localDateTime);
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
            ],
          ),
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
