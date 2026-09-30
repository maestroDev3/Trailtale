import 'dart:io';

import 'package:flutter/material.dart';

import '../domain/entry.dart';
import '../domain/trip.dart';
import '../domain/trip_overview.dart';
import '../l10n/app_localizations.dart';
import 'app_services.dart';
import 'formatting.dart';
import 'trip_detail_screen.dart';
import 'trip_form_screen.dart';
import 'widgets/trailtale_logo.dart';
import 'widgets/trip_cover.dart';
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
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: StreamBuilder<List<Trip>>(
        stream: services.tripRepository.watchTrips(),
        builder: (context, snapshot) => StreamBuilder<List<Entry>>(
          stream: services.entryRepository.watchAllEntries(),
          builder: (context, entriesSnapshot) {
            return CustomScrollView(
              slivers: [
                SliverAppBar(
                  floating: true,
                  titleSpacing: 20,
                  title: Row(
                    children: [
                      const TrailtaleLogo(size: 34),
                      const SizedBox(width: 10),
                      Text(l10n.appTitle, style: textTheme.titleLarge),
                    ],
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  sliver: SliverToBoxAdapter(
                    child: Text(
                      l10n.yourTrips,
                      style: textTheme.headlineLarge,
                    ),
                  ),
                ),
                switch (snapshot) {
                  AsyncSnapshot(hasError: true) => _Message(
                    l10n.tripsLoadError,
                  ),
                  AsyncSnapshot(:final data?) when data.isEmpty => _Message(
                    l10n.emptyTripsMessage,
                  ),
                  AsyncSnapshot(:final data?) => _Overview(
                    overviews: buildTripOverviews(
                      data,
                      entriesSnapshot.data ?? const [],
                      today: services.clock(),
                    ),
                    photoFile: services.photoLibrary.fileFor,
                    onOpen: (trip) => _openTrip(context, trip),
                  ),
                  _ => const SliverToBoxAdapter(),
                },
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openNewTripForm(context),
        icon: const Icon(Icons.add),
        label: Text(l10n.newTrip),
      ),
    );
  }
}

class _Overview extends StatelessWidget {
  const _Overview({
    required this.overviews,
    required this.photoFile,
    required this.onOpen,
  });

  final ({TripOverview? featured, List<TripOverview> others}) overviews;
  final File Function(String relativePath) photoFile;
  final ValueChanged<Trip> onOpen;

  File? _cover(TripOverview overview) => switch (overview.coverPhoto) {
    final path? => photoFile(path),
    null => null,
  };

  @override
  Widget build(BuildContext context) {
    final (:featured, :others) = overviews;
    final textTheme = Theme.of(context).textTheme;
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 104),
      sliver: SliverList.list(
        children: [
          if (featured != null) ...[
            _FeaturedTripCard(
              overview: featured,
              cover: _cover(featured),
              onTap: () => onOpen(featured.trip),
            ),
            if (others.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 24, 4, 8),
                child: Text(
                  AppLocalizations.of(context).moreJourneys,
                  style: textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
          ],
          for (final overview in others)
            _TripCard(
              overview: overview,
              cover: _cover(overview),
              onTap: () => onOpen(overview.trip),
            ),
        ],
      ),
    );
  }
}

class _FeaturedTripCard extends StatelessWidget {
  const _FeaturedTripCard({
    required this.overview,
    required this.cover,
    required this.onTap,
  });

  final TripOverview overview;
  final File? cover;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final (:trip, :summary, coverPhoto: _, :progress) = overview;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
            SizedBox(height: 320, child: TripCover(file: cover)),
            if (progress case RunningTrip(:final dayNumber, :final dayCount))
              Positioned(
                left: 14,
                top: 14,
                child: _Badge(text: l10n.onTheRoad(dayNumber, dayCount)),
              ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(trip.title, style: theme.textTheme.headlineSmall),
                    Text(
                      tripDatesText(context, trip),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 16,
                      runSpacing: 6,
                      children: [
                        _Fact(
                          icon: Icons.notes_outlined,
                          text: l10n.entryCount(summary.entryCount),
                        ),
                        _Fact(
                          icon: Icons.place_outlined,
                          text: l10n.placeCount(summary.placeCount),
                        ),
                        _Fact(
                          icon: Icons.route_outlined,
                          text: l10n.distanceKm(
                            formatKilometers(summary.distanceMeters, locale),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.inverseSurface,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.onInverseSurface,
        ),
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.primary),
        const SizedBox(width: 5),
        Text(text, style: theme.textTheme.labelLarge),
      ],
    );
  }
}

class _TripCard extends StatelessWidget {
  const _TripCard({
    required this.overview,
    required this.cover,
    required this.onTap,
  });

  final TripOverview overview;
  final File? cover;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final (:trip, :summary, coverPhoto: _, progress: _) = overview;
    final days = l10n.tripDayCount(trip.dayCount);
    final facts = summary.distanceMeters > 0
        ? l10n.tripFacts(days, formatKilometers(summary.distanceMeters, locale))
        : days;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox.square(
                  dimension: 84,
                  child: TripCover(file: cover),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(trip.title, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      tripDatesText(context, trip),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      facts,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                  ],
                ),
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
