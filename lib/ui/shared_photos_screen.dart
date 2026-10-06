import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../domain/place.dart';
import '../domain/quick_capture.dart';
import '../domain/shared_photos.dart';
import '../domain/trip.dart';
import '../domain/trip_repository.dart';
import '../l10n/app_localizations.dart';
import 'app_services.dart';
import 'trip_detail_screen.dart';
import 'trip_form_screen.dart';
import 'widgets/capture_widgets.dart';

/// Turns photos shared by another app into entries: groups them by time and
/// place, lets the traveler leave groups out and saves the rest into the
/// running (or chosen) trip.
class SharedPhotosScreen extends StatefulWidget {
  const SharedPhotosScreen({
    super.key,
    required this.services,
    required this.paths,
  });

  final AppServices services;

  /// Absolute paths of the shared photos (copies in the app cache).
  final List<String> paths;

  @override
  State<SharedPhotosScreen> createState() => _SharedPhotosScreenState();
}

/// A suggested entry with the place its location is closest to.
typedef _Suggestion = ({PhotoGroup group, Place? place});

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

final class _Preview extends _Stage {
  const _Preview(this.trip);

  final Trip trip;
}

class _SharedPhotosScreenState extends State<SharedPhotosScreen> {
  _Stage _stage = const _Loading();
  var _suggestions = const <_Suggestion>[];

  /// Indexes of the suggestions the traveler left out.
  final _leftOut = <int>{};
  var _saving = false;

  @override
  void initState() {
    super.initState();
    unawaited(_start());
  }

  Future<void> _start() async {
    final services = widget.services;
    final trips = await readTripsOnce(services.tripRepository);
    final photos = [
      for (final path in widget.paths)
        SharedPhoto(
          path: path,
          metadata: await services.photoMetadataReader.read(File(path)),
        ),
    ];
    final places = await services.placeDirectory.load();
    final groups = groupSharedPhotos(photos, now: services.clock());
    if (!mounted) return;
    setState(() {
      _suggestions = [
        for (final group in groups)
          (
            group: group,
            place: switch (group.location) {
              final location? => places.nearest(location),
              null => null,
            },
          ),
      ];
      _stage = switch (quickCaptureTarget(trips, today: services.clock())) {
        CaptureInto(:final trip) => _Preview(trip),
        ChooseTrip(:final trips) => _Choosing(trips),
        NoTrip() => const _NoTrip(),
      };
    });
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

  Future<void> _save(Trip trip) async {
    setState(() => _saving = true);
    final services = widget.services;
    for (final (index, suggestion) in _suggestions.indexed) {
      if (_leftOut.contains(index)) continue;
      final imported = [
        for (final path in suggestion.group.photoPaths)
          await services.photoLibrary.importPhoto(path),
      ];
      await services.entryRepository.saveEntry(
        entryFromGroup(
          suggestion.group,
          id: services.newId(),
          tripId: trip.id,
          photoPaths: imported,
          nearestPlace: suggestion.place,
        ),
      );
    }
    if (!mounted) return;
    unawaited(
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => TripDetailScreen(services: services, trip: trip),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final chosenCount = _suggestions.length - _leftOut.length;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.sharedPhotosTitle)),
      body: SafeArea(
        child: switch (_stage) {
          _Loading() => const Center(child: CircularProgressIndicator()),
          _Choosing(:final trips) => TripChoiceList(
            trips: trips,
            onChosen: (trip) => setState(() => _stage = _Preview(trip)),
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
          _Preview(:final trip) => ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            itemCount: _suggestions.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    l10n.sharedPhotosInto(trip.title),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                );
              }
              final position = index - 1;
              return _SuggestionCard(
                key: Key('shared-group-$position'),
                suggestion: _suggestions[position],
                chosen: !_leftOut.contains(position),
                photoFile: File.new,
                onChanged: (chosen) => setState(() {
                  if (chosen) {
                    _leftOut.remove(position);
                  } else {
                    _leftOut.add(position);
                  }
                }),
              );
            },
          ),
        },
      ),
      bottomNavigationBar: switch (_stage) {
        _Preview(:final trip) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: FilledButton(
              onPressed: chosenCount == 0 || _saving ? null : () => _save(trip),
              child: Text(l10n.sharedPhotosSave(chosenCount)),
            ),
          ),
        ),
        _ => null,
      },
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({
    super.key,
    required this.suggestion,
    required this.chosen,
    required this.photoFile,
    required this.onChanged,
  });

  final _Suggestion suggestion;
  final bool chosen;
  final File Function(String path) photoFile;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final takenAt = suggestion.group.takenAt;
    final when = l10n.sharedPhotosDateTime(
      DateFormat.yMMMEd(l10n.localeName).format(takenAt),
      DateFormat.jm(l10n.localeName).format(takenAt),
    );
    return Card(
      child: InkWell(
        onTap: () => onChanged(!chosen),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          suggestion.place?.name ??
                              l10n.sharedPhotosUnknownPlace,
                          style: theme.textTheme.titleMedium,
                        ),
                        Text(
                          when,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Checkbox(
                    value: chosen,
                    onChanged: (value) => onChanged(value ?? false),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 72,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: suggestion.group.photoPaths.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 6),
                  itemBuilder: (context, index) => ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image(
                      image: ResizeImage(
                        FileImage(
                          photoFile(suggestion.group.photoPaths[index]),
                        ),
                        width: 216,
                      ),
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => ColoredBox(
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: const SizedBox.square(dimension: 72),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
