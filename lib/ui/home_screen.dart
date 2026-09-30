import 'package:flutter/material.dart';

import '../domain/trip.dart';
import '../l10n/app_localizations.dart';
import 'app_services.dart';
import 'trip_detail_screen.dart';
import 'trip_form_screen.dart';
import 'widgets/trip_dates.dart';

/// Start screen of the app: lists the trips newest first and, until there
/// are any, shows an empty state.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.services});

  final AppServices services;

  void _openTrip(BuildContext context, Trip trip) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TripDetailScreen(services: services, trip: trip),
      ),
    );
  }

  void _openNewTripForm(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TripFormScreen(services: services),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: StreamBuilder<List<Trip>>(
        stream: services.tripRepository.watchTrips(),
        builder: (context, snapshot) {
          return CustomScrollView(
            slivers: [
              SliverAppBar.large(title: Text(l10n.appTitle)),
              switch (snapshot) {
                AsyncSnapshot(hasError: true) => _Message(l10n.tripsLoadError),
                AsyncSnapshot(:final data?) when data.isEmpty => _Message(
                  l10n.emptyTripsMessage,
                ),
                AsyncSnapshot(:final data?) => _TripList(
                  trips: data,
                  onOpen: (trip) => _openTrip(context, trip),
                ),
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
  const _TripList({required this.trips, required this.onOpen});

  final List<Trip> trips;
  final ValueChanged<Trip> onOpen;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
      sliver: SliverList.builder(
        itemCount: trips.length,
        itemBuilder: (context, index) {
          final trip = trips[index];
          return _TripCard(trip: trip, onTap: () => onOpen(trip));
        },
      ),
    );
  }
}

class _TripCard extends StatelessWidget {
  const _TripCard({required this.trip, required this.onTap});

  final Trip trip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(trip.title, style: textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(tripDatesText(context, trip), style: textTheme.bodyMedium),
              Text(
                l10n.tripDayCount(trip.dayCount),
                style: textTheme.bodySmall,
              ),
            ],
          ),
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
