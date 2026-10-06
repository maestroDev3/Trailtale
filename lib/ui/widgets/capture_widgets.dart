import 'package:flutter/material.dart';

import '../../domain/trip.dart';
import '../../l10n/app_localizations.dart';
import 'trip_dates.dart';

/// The trips to choose from for a quick capture or shared photos.
class TripChoiceList extends StatelessWidget {
  const TripChoiceList({super.key, required this.trips, required this.onChosen});

  final List<Trip> trips;
  final ValueChanged<Trip> onChosen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView.builder(
      itemCount: trips.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              AppLocalizations.of(context).quickCaptureChooseTrip,
              style: theme.textTheme.titleLarge,
            ),
          );
        }
        final trip = trips[index - 1];
        return ListTile(
          leading: const Icon(Icons.map_outlined),
          title: Text(trip.title),
          subtitle: Text(dateRangeText(context, trip.startDate, trip.endDate)),
          onTap: () => onChosen(trip),
        );
      },
    );
  }
}

/// A centred message with an icon and actions, e.g. “no trip yet”.
class CaptureMessage extends StatelessWidget {
  const CaptureMessage({
    super.key,
    required this.icon,
    required this.text,
    required this.actions,
  });

  final IconData icon;
  final String text;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: theme.colorScheme.secondary),
            const SizedBox(height: 16),
            Text(
              text,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 24),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: actions,
            ),
          ],
        ),
      ),
    );
  }
}
