import 'dart:async';

import 'package:flutter/material.dart';

import '../domain/geo_point.dart';
import '../domain/place.dart';
import '../domain/position_service.dart';
import '../l10n/app_localizations.dart';
import 'app_services.dart';
import 'widgets/picker_map.dart';
import 'widgets/position_feedback.dart';

/// The point the user picked and the town nearest to it, if any.
typedef PickedPlace = ({GeoPoint location, Place? nearestPlace});

/// Lets the user pick a place by moving a map under a fixed crosshair.
///
/// Without [initialCenter] it starts on a world view and tries the current
/// position once.
class PlacePickerScreen extends StatefulWidget {
  const PlacePickerScreen({
    super.key,
    required this.services,
    this.initialCenter,
    this.initialZoom = 15,
  });

  final AppServices services;
  final GeoPoint? initialCenter;
  final double initialZoom;

  @override
  State<PlacePickerScreen> createState() => _PlacePickerScreenState();
}

class _PlacePickerScreenState extends State<PlacePickerScreen> {
  /// Where the map starts without an initial center.
  static final _worldCenter = GeoPoint(latitude: 20, longitude: 0);
  static const _worldZoom = 2.0;

  final _map = PickerMapController();
  late final Future<PlaceIndex> _places = widget.services.placeDirectory
      .load();
  late GeoPoint _center = widget.initialCenter ?? _worldCenter;
  Place? _nearest;
  var _locating = false;

  @override
  void initState() {
    super.initState();
    unawaited(_refreshNearest());
    if (widget.initialCenter == null) unawaited(_locate(quiet: true));
  }

  @override
  void dispose() {
    _map.dispose();
    super.dispose();
  }

  void _centerChanged(GeoPoint center) {
    if (center == _center) return;
    setState(() => _center = center);
    unawaited(_refreshNearest());
  }

  Future<void> _refreshNearest() async {
    final center = _center;
    final index = await _places;
    if (!mounted || center != _center) return;
    setState(() => _nearest = index.nearest(center));
  }

  /// Moves the map to the current position; [quiet] skips the message when
  /// no position is found.
  Future<void> _locate({bool quiet = false}) async {
    setState(() => _locating = true);
    final service = widget.services.positionService;
    final result = await service.currentPosition();
    if (!mounted) return;
    setState(() => _locating = false);
    if (result case PositionFound(:final location)) {
      _map.moveTo(location, zoom: 16);
      return;
    }
    if (quiet) return;
    final snackBar = positionProblemSnackBar(
      AppLocalizations.of(context),
      result,
      service,
    );
    if (snackBar == null) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(snackBar);
  }

  void _searchSelected(Place place) {
    FocusScope.of(context).unfocus();
    _map.moveTo(place.location, zoom: 13);
  }

  Future<void> _usePlace() async {
    final center = _center;
    final nearest = (await _places).nearest(center);
    if (!mounted) return;
    Navigator.of(context).pop<PickedPlace>(
      (location: center, nearestPlace: nearest),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final initialCenter = widget.initialCenter;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.pickPlaceTitle)),
      body: Stack(
        children: [
          Positioned.fill(
            child: widget.services.pickerMap(
              controller: _map,
              initialCenter: initialCenter ?? _worldCenter,
              initialZoom: initialCenter == null
                  ? _worldZoom
                  : widget.initialZoom,
              onCenterChanged: _centerChanged,
            ),
          ),
          Center(
            child: IgnorePointer(
              child: Icon(
                Icons.add,
                key: const Key('picker-crosshair'),
                size: 44,
                color: colorScheme.secondary,
                shadows: [Shadow(color: colorScheme.surface, blurRadius: 4)],
              ),
            ),
          ),
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: _TownSearch(places: _places, onSelected: _searchSelected),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.small(
        tooltip: l10n.pickerMyPosition,
        onPressed: _locating ? null : _locate,
        child: _locating
            ? const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.my_location),
      ),
      bottomNavigationBar: _PickerPanel(
        center: _center,
        nearest: _nearest,
        onUse: _usePlace,
      ),
    );
  }
}

class _TownSearch extends StatefulWidget {
  const _TownSearch({required this.places, required this.onSelected});

  final Future<PlaceIndex> places;
  final ValueChanged<Place> onSelected;

  @override
  State<_TownSearch> createState() => _TownSearchState();
}

class _TownSearchState extends State<_TownSearch> {
  final _text = TextEditingController();
  final _focus = FocusNode();

  @override
  void dispose() {
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return RawAutocomplete<Place>(
      textEditingController: _text,
      focusNode: _focus,
      displayStringForOption: (place) => place.name,
      optionsBuilder: (value) async =>
          (await widget.places).search(value.text),
      onSelected: widget.onSelected,
      fieldViewBuilder: (context, controller, focusNode, _) => Material(
        elevation: 3,
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(28),
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            hintText: l10n.pickerSearchHint,
            prefixIcon: const Icon(Icons.search),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
      optionsViewBuilder: (context, onSelected, options) => Align(
        alignment: Alignment.topLeft,
        child: Material(
          elevation: 4,
          color: theme.colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: 280,
              maxWidth: MediaQuery.sizeOf(context).width - 24,
            ),
            child: ListView(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              children: [
                for (final place in options)
                  ListTile(
                    leading: const Icon(Icons.location_city_outlined),
                    title: Text(place.name),
                    subtitle: Text(place.detail),
                    onTap: () => onSelected(place),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PickerPanel extends StatelessWidget {
  const _PickerPanel({
    required this.center,
    required this.nearest,
    required this.onUse,
  });

  final GeoPoint center;
  final Place? nearest;
  final VoidCallback onUse;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final nearest = this.nearest;
    return Material(
      color: theme.colorScheme.surfaceContainerLow,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                nearest == null
                    ? l10n.pickerNoTownNearby
                    : l10n.pickerNearPlace(nearest.label),
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                l10n.coordinatesValue(
                  center.latitude.toStringAsFixed(4),
                  center.longitude.toStringAsFixed(4),
                ),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: onUse,
                icon: const Icon(Icons.check),
                label: Text(l10n.pickerUseThisPlace),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
