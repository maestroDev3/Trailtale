import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../domain/entry.dart';
import '../domain/entry_tag.dart';
import '../domain/position_service.dart';
import '../domain/quick_capture.dart';
import '../domain/trip.dart';
import '../domain/trip_repository.dart';
import '../l10n/app_localizations.dart';
import 'app_services.dart';
import 'entry_form_screen.dart';
import 'trip_form_screen.dart';
import 'widgets/capture_widgets.dart';
import 'widgets/position_feedback.dart';
import 'widgets/tag_chips.dart';

/// Saves where the traveler is right now – opened by the home screen widget
/// “I'm here”. With one running trip it saves without a tap; otherwise it
/// asks for the trip first. Afterwards it offers to add a note or a photo.
class QuickCaptureScreen extends StatefulWidget {
  const QuickCaptureScreen({super.key, required this.services});

  final AppServices services;

  @override
  State<QuickCaptureScreen> createState() => _QuickCaptureScreenState();
}

/// What the quick capture screen is doing.
sealed class _Stage {
  const _Stage();
}

final class _Loading extends _Stage {
  const _Loading();
}

final class _Choosing extends _Stage {
  const _Choosing(this.trips);

  final List<Trip> trips;
}

final class _NoTrip extends _Stage {
  const _NoTrip();
}

final class _Locating extends _Stage {
  const _Locating();
}

final class _Saved extends _Stage {
  const _Saved(this.trip, this.entry);

  final Trip trip;
  final Entry entry;
}

final class _NoPosition extends _Stage {
  const _NoPosition(this.trip, this.result);

  final Trip trip;
  final PositionResult result;
}

class _QuickCaptureScreenState extends State<QuickCaptureScreen> {
  _Stage _stage = const _Loading();

  @override
  void initState() {
    super.initState();
    unawaited(_start());
  }

  Future<void> _start() async {
    final services = widget.services;
    final allTrips = await readTripsOnce(services.tripRepository);
    if (!mounted) return;
    switch (quickCaptureTarget(allTrips, today: services.clock())) {
      case CaptureInto(:final trip):
        await _capture(trip);
      case ChooseTrip(:final trips):
        setState(() => _stage = _Choosing(trips));
      case NoTrip():
        setState(() => _stage = const _NoTrip());
    }
  }

  Future<void> _capture(Trip trip) async {
    setState(() => _stage = const _Locating());
    final services = widget.services;
    final result = await services.positionService.currentPosition();
    if (result case PositionFound(:final location)) {
      final places = await services.placeDirectory.load();
      final entry = buildQuickEntry(
        id: services.newId(),
        trip: trip,
        localTime: services.clock(),
        location: location,
        nearestPlace: places.nearest(location),
      );
      await services.entryRepository.saveEntry(entry);
      if (!mounted) return;
      setState(() => _stage = _Saved(trip, entry));
    } else {
      if (!mounted) return;
      setState(() => _stage = _NoPosition(trip, result));
    }
  }

  /// Saves the entry with [tags] right away – one tap describes the moment.
  Future<void> _retag(Trip trip, Entry entry, Set<EntryTag> tags) async {
    final tagged = entry.copyWith(tags: tags);
    setState(() => _stage = _Saved(trip, tagged));
    await widget.services.entryRepository.saveEntry(tagged);
  }

  Future<void> _createTrip() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TripFormScreen(services: widget.services),
      ),
    );
    if (!mounted) return;
    await _start();
  }

  void _openEntry(
    Trip trip,
    Entry? entry, {
    bool addPhotos = false,
    bool focusNote = false,
  }) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => EntryFormScreen(
          services: widget.services,
          trip: trip,
          entry: entry,
          addPhotosOnOpen: addPhotos,
          focusNote: focusNote,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.quickCaptureTitle)),
      body: SafeArea(
        child: switch (_stage) {
          _Loading() => const SizedBox.shrink(),
          _Locating() => _LocatingView(label: l10n.locatingPosition),
          _Choosing(:final trips) => TripChoiceList(
            trips: trips,
            onChosen: _capture,
          ),
          _NoTrip() => CaptureMessage(
            icon: Icons.luggage_outlined,
            text: l10n.quickCaptureNoTrip,
            actions: [
              FilledButton.icon(
                onPressed: _createTrip,
                icon: const Icon(Icons.add),
                label: Text(l10n.newTrip),
              ),
            ],
          ),
          _Saved(:final trip, :final entry) => _Confirmation(
            trip: trip,
            entry: entry,
            onTagsChanged: (tags) => _retag(trip, entry, tags),
            onAddNote: () => _openEntry(trip, entry, focusNote: true),
            onAddPhoto: () => _openEntry(trip, entry, addPhotos: true),
            onDone: () => Navigator.of(context).pop(),
          ),
          _NoPosition(:final trip, :final result) => CaptureMessage(
            icon: Icons.location_off_outlined,
            text: positionProblemText(l10n, result) ?? '',
            actions: [
              if (positionSettingsAction(
                    l10n,
                    result,
                    widget.services.positionService,
                  )
                  case final settings?)
                OutlinedButton(
                  onPressed: settings.onPressed,
                  child: Text(settings.label),
                ),
              OutlinedButton(
                onPressed: () => _openEntry(trip, null),
                child: Text(l10n.quickCaptureWriteEntry),
              ),
              FilledButton(
                onPressed: () => _capture(trip),
                child: Text(l10n.quickCaptureRetry),
              ),
            ],
          ),
        },
      ),
    );
  }
}

class _LocatingView extends StatelessWidget {
  const _LocatingView({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(label, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}

class _Confirmation extends StatelessWidget {
  const _Confirmation({
    required this.trip,
    required this.entry,
    required this.onTagsChanged,
    required this.onAddNote,
    required this.onAddPhoto,
    required this.onDone,
  });

  final Trip trip;
  final Entry entry;
  final ValueChanged<Set<EntryTag>> onTagsChanged;
  final VoidCallback onAddNote;
  final VoidCallback onAddPhoto;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final time = DateFormat.jm(l10n.localeName).format(entry.localDateTime);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              Icons.where_to_vote_outlined,
              size: 56,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.quickCaptureSaved,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.quickCaptureSavedAt(
                entry.placeName ?? l10n.quickCaptureYourPosition,
                time,
              ),
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            Text(
              l10n.quickCaptureInTrip(trip.title),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            TagChips(
              selected: entry.tags,
              onChanged: onTagsChanged,
              alignment: WrapAlignment.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onAddNote,
                    icon: const Icon(Icons.edit_note_outlined),
                    label: Text(l10n.quickCaptureAddNote),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onAddPhoto,
                    icon: const Icon(Icons.add_a_photo_outlined),
                    label: Text(l10n.quickCaptureAddPhoto),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FilledButton(onPressed: onDone, child: Text(l10n.quickCaptureDone)),
          ],
        ),
      ),
    );
  }
}
