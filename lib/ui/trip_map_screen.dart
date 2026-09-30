import 'package:flutter/material.dart';

import '../domain/entry.dart';
import '../domain/trip.dart';
import '../domain/trip_map.dart';
import 'app_services.dart';
import 'entry_form_screen.dart';

/// The map of a trip in full screen: pan and zoom, tap a marker to open the
/// entry.
class TripMapScreen extends StatelessWidget {
  const TripMapScreen({super.key, required this.services, required this.trip});

  final AppServices services;
  final Trip trip;

  void _openEntry(BuildContext context, List<Entry> entries, String entryId) {
    final entry = entries.where((entry) => entry.id == entryId).firstOrNull;
    if (entry == null) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            EntryFormScreen(services: services, trip: trip, entry: entry),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(trip.title)),
      body: StreamBuilder<List<Entry>>(
        stream: services.entryRepository.watchEntries(trip.id),
        builder: (context, snapshot) {
          final entries = snapshot.data ?? const <Entry>[];
          return services.tripMap(
            points: tripMapPoints(entries),
            onOpenEntry: (id) => _openEntry(context, entries, id),
          );
        },
      ),
    );
  }
}
