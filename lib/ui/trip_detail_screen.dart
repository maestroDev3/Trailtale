import 'package:flutter/material.dart';

import '../domain/clock.dart';
import '../domain/id_generator.dart';
import '../domain/trip.dart';
import '../domain/trip_repository.dart';
import '../l10n/app_localizations.dart';
import 'trip_form_screen.dart';
import 'widgets/trip_dates.dart';

/// Shows one trip with its dates and (later) its entries, and offers editing
/// and deleting it.
class TripDetailScreen extends StatelessWidget {
  const TripDetailScreen({
    super.key,
    required this.trip,
    required this.tripRepository,
    required this.newId,
    this.clock = DateTime.now,
  });

  /// The trip as it was when the screen was opened; updates come from the
  /// repository.
  final Trip trip;
  final TripRepository tripRepository;
  final IdGenerator newId;
  final Clock clock;

  Stream<Trip?> _watchTrip() => tripRepository.watchTrips().map(
    (trips) => trips.where((stored) => stored.id == trip.id).firstOrNull,
  );

  void _openEditForm(BuildContext context, Trip current) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TripFormScreen(
          tripRepository: tripRepository,
          newId: newId,
          clock: clock,
          trip: current,
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Trip current) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => _DeleteTripDialog(title: current.title),
    );
    if (confirmed != true) return;
    await tripRepository.deleteTrip(current.id);
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
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      l10n.noEntriesYet,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                ),
              ),
            ],
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
      padding: const EdgeInsets.symmetric(horizontal: 16),
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
