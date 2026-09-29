import 'package:flutter/material.dart';

import '../domain/clock.dart';
import '../domain/id_generator.dart';
import '../domain/trip.dart';
import '../domain/trip_repository.dart';
import '../l10n/app_localizations.dart';
import 'trip_form_screen.dart';
import 'widgets/trip_dates.dart';

/// Start screen of the app: lists the trips newest first and, until there
/// are any, shows an empty state.
class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.tripRepository,
    required this.newId,
    this.clock = DateTime.now,
  });

  final TripRepository tripRepository;
  final IdGenerator newId;
  final Clock clock;

  void _openNewTripForm(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TripFormScreen(
          tripRepository: tripRepository,
          newId: newId,
          clock: clock,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: StreamBuilder<List<Trip>>(
        stream: tripRepository.watchTrips(),
        builder: (context, snapshot) {
          return CustomScrollView(
            slivers: [
              SliverAppBar.large(title: Text(l10n.appTitle)),
              switch (snapshot) {
                AsyncSnapshot(hasError: true) => _Message(l10n.tripsLoadError),
                AsyncSnapshot(:final data?) when data.isEmpty => _Message(
                  l10n.emptyTripsMessage,
                ),
                AsyncSnapshot(:final data?) => _TripList(trips: data),
                _ => const SliverToBoxAdapter(),
              },
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openNewTripForm(context),
        icon: const Icon(Icons.add),
        label: Text(l10n.newTrip),
      ),
    );
  }
}

class _TripList extends StatelessWidget {
  const _TripList({required this.trips});

  final List<Trip> trips;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
      sliver: SliverList.builder(
        itemCount: trips.length,
        itemBuilder: (context, index) => _TripCard(trip: trips[index]),
      ),
    );
  }
}

class _TripCard extends StatelessWidget {
  const _TripCard({required this.trip});

  final Trip trip;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(trip.title, style: textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(tripDatesText(context, trip), style: textTheme.bodyMedium),
            Text(l10n.tripDayCount(trip.dayCount), style: textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ),
    );
  }
}
