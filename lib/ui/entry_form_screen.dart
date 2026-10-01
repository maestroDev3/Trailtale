import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../domain/coordinates_input.dart';
import '../domain/default_entry_time.dart';
import '../domain/entry.dart';
import '../domain/geo_point.dart';
import '../domain/photo_gallery.dart';
import '../domain/photo_metadata.dart';
import '../domain/photo_suggestion.dart';
import '../domain/place.dart';
import '../domain/position_service.dart';
import '../domain/trip.dart';
import '../l10n/app_localizations.dart';
import 'app_services.dart';
import 'gallery_picker_screen.dart';
import 'place_picker_screen.dart';
import 'widgets/photo_thumbnail.dart';
import 'widgets/position_feedback.dart';

/// Form for adding an entry to [trip] or, when [entry] is given, editing or
/// deleting it.
class EntryFormScreen extends StatefulWidget {
  const EntryFormScreen({
    super.key,
    required this.services,
    required this.trip,
    this.entry,
  });

  final AppServices services;
  final Trip trip;
  final Entry? entry;

  @override
  State<EntryFormScreen> createState() => _EntryFormScreenState();
}

class _EntryFormScreenState extends State<EntryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _note;
  late final TextEditingController _place;
  late final TextEditingController _latitude;
  late final TextEditingController _longitude;
  final _placeFocus = FocusNode();
  late final Future<PlaceIndex> _places = widget.services.placeDirectory.load();
  var _showCoordinates = false;
  late DateTime _date;
  late TimeOfDay _time;
  late final List<String> _photos;

  /// Photos imported while this form is open; deleted again unless saved.
  final _importedPhotos = <String>{};
  var _saved = false;

  /// Metadata of the photos added while this form is open.
  final _addedMetadata = <PhotoMetadata>[];

  /// Whether the current position is being determined.
  var _locating = false;

  /// Whether the user picked date or time by hand; photos then keep off.
  var _dateTimeSetByUser = false;

  /// Offset recorded by the photo whose time was applied; `null` means the
  /// device's offset at that time.
  Duration? _photoOffset;

  @override
  void initState() {
    super.initState();
    final entry = widget.entry;
    final location = entry?.location;
    _note = TextEditingController(text: entry?.note ?? '');
    _place = TextEditingController(text: entry?.placeName ?? '');
    _latitude = TextEditingController(text: location?.latitude.toString());
    _longitude = TextEditingController(text: location?.longitude.toString());
    final start = entry == null
        ? defaultEntryTime(trip: widget.trip, now: widget.services.clock())
        : entry.localDateTime;
    _date = DateTime(start.year, start.month, start.day);
    _time = TimeOfDay(hour: start.hour, minute: start.minute);
    _photos = [...?entry?.photoPaths];
  }

  @override
  void dispose() {
    if (!_saved && _importedPhotos.isNotEmpty) {
      unawaited(widget.services.photoLibrary.deletePhotos(_importedPhotos));
    }
    _note.dispose();
    _place.dispose();
    _placeFocus.dispose();
    _latitude.dispose();
    _longitude.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(1900),
      lastDate: DateTime(2200),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _date = picked;
      _dateTimeSetByUser = true;
      _photoOffset = null;
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked == null || !mounted) return;
    setState(() {
      _time = picked;
      _dateTimeSetByUser = true;
      _photoOffset = null;
    });
  }

  Future<void> _addPhotos() async {
    final sources = await _pickPhotoFiles();
    if (sources == null || sources.isEmpty || !mounted) return;
    final services = widget.services;
    final imported = <String>[];
    final metadata = <PhotoMetadata>[];
    for (final source in sources) {
      final path = await services.photoLibrary.importPhoto(source);
      imported.add(path);
      metadata.add(
        await services.photoMetadataReader.read(
          services.photoLibrary.fileFor(path),
        ),
      );
    }
    _importedPhotos.addAll(imported);
    _addedMetadata.addAll(metadata);
    final suggestion = suggestFromPhotos(_addedMetadata);
    final nearestPlace = switch (suggestion.location) {
      final location? => (await _places).nearest(location),
      null => null,
    };
    if (!mounted) return;
    setState(() => _photos.addAll(imported));
    _applySuggestion(suggestion, nearestPlace, addedCount: imported.length);
  }

  /// Lets the user choose photos and returns the paths of their files:
  /// originals from the gallery (with location) when access is granted,
  /// otherwise from the system photo picker; `null` when cancelled.
  Future<List<String>?> _pickPhotoFiles() async {
    final services = widget.services;
    final gallery = services.photoGallery;
    final access = await gallery.requestAccess();
    if (!mounted) return null;
    if (access == GalleryAccess.denied) {
      return services.photoPicker.pickImages();
    }
    final ids = await Navigator.of(context).push<List<String>>(
      MaterialPageRoute(
        builder: (context) => GalleryPickerScreen(
          gallery: gallery,
          trip: widget.trip,
          access: access,
        ),
      ),
    );
    if (ids == null) return null;
    return [for (final id in ids) ?await gallery.originalFile(id)];
  }

  /// Fills date, time and coordinates from photos where the user has not
  /// set them, and tells the user what was taken over.
  void _applySuggestion(
    PhotoSuggestion suggestion,
    Place? nearestPlace, {
    required int addedCount,
  }) {
    final takenAt = suggestion.takenAt;
    final applyTime =
        takenAt != null && widget.entry == null && !_dateTimeSetByUser;
    final location = suggestion.location;
    final applyPlace =
        location != null &&
        _latitude.text.trim().isEmpty &&
        _longitude.text.trim().isEmpty;
    final coordinatesEmpty =
        _latitude.text.trim().isEmpty && _longitude.text.trim().isEmpty;
    final missingLocation = location == null && coordinatesEmpty;
    if (!applyTime && !applyPlace && !missingLocation) return;
    setState(() {
      if (applyTime) {
        _date = DateTime(takenAt.year, takenAt.month, takenAt.day);
        _time = TimeOfDay(hour: takenAt.hour, minute: takenAt.minute);
        _photoOffset = suggestion.utcOffset;
      }
      if (applyPlace) {
        _latitude.text = location.latitude.toStringAsFixed(6);
        _longitude.text = location.longitude.toStringAsFixed(6);
        if (nearestPlace != null && _place.text.trim().isEmpty) {
          _place.text = nearestPlace.name;
        }
      }
    });
    final l10n = AppLocalizations.of(context);
    final message = switch ((applyTime, applyPlace)) {
      (true, true) => l10n.takenFromPhotoDateAndPlace,
      (true, false) when missingLocation => l10n.takenFromPhotoDateNoPlace,
      (true, false) => l10n.takenFromPhotoDate,
      (false, true) => l10n.takenFromPhotoPlace,
      (false, false) => l10n.photosWithoutLocation(addedCount),
    };
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _removePhoto(String path) {
    setState(() => _photos.remove(path));
  }

  String? _validateNote(String? note) {
    final l10n = AppLocalizations.of(context);
    final hasContent =
        (note ?? '').trim().isNotEmpty ||
        _place.text.trim().isNotEmpty ||
        _photos.isNotEmpty;
    return hasContent ? null : l10n.entryNeedsContent;
  }

  String? _validateCoordinates(String? _) {
    final l10n = AppLocalizations.of(context);
    return switch (parseCoordinates(_latitude.text, _longitude.text)) {
      InvalidCoordinates(error: CoordinatesError.incomplete) =>
        l10n.coordinatesIncomplete,
      InvalidCoordinates(error: CoordinatesError.outOfRange) =>
        l10n.coordinatesOutOfRange,
      NoCoordinates() || ValidCoordinates() => null,
    };
  }

  Future<void> _useMyPosition() async {
    setState(() => _locating = true);
    final positions = widget.services.positionService;
    final result = await positions.currentPosition();
    final nearestPlace = switch (result) {
      PositionFound(:final location) when _place.text.trim().isEmpty =>
        (await _places).nearest(location),
      _ => null,
    };
    if (!mounted) return;
    setState(() {
      _locating = false;
      if (result case PositionFound(:final location)) {
        _latitude.text = location.latitude.toStringAsFixed(6);
        _longitude.text = location.longitude.toStringAsFixed(6);
        if (nearestPlace != null && _place.text.trim().isEmpty) {
          _place.text = nearestPlace.name;
        }
      }
    });
    final l10n = AppLocalizations.of(context);
    final snackBar = switch (result) {
      PositionFound(:final accuracyMeters) => SnackBar(
        content: Text(l10n.positionSet(accuracyMeters.round())),
      ),
      _ => positionProblemSnackBar(l10n, result, positions),
    };
    if (snackBar == null) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(snackBar);
  }

  Future<void> _pickOnMap() async {
    final (center, zoom) = await _pickerStart();
    if (!mounted) return;
    final picked = await Navigator.of(context).push<PickedPlace>(
      MaterialPageRoute(
        builder: (context) => PlacePickerScreen(
          services: widget.services,
          initialCenter: center,
          initialZoom: zoom,
        ),
      ),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _latitude.text = picked.location.latitude.toStringAsFixed(6);
      _longitude.text = picked.location.longitude.toStringAsFixed(6);
      if (picked.nearestPlace case final nearest?
          when _place.text.trim().isEmpty) {
        _place.text = nearest.name;
      }
    });
  }

  /// Where the map picker starts: the entry's coordinates, else the town
  /// typed as place, else no hint.
  Future<(GeoPoint?, double)> _pickerStart() async {
    if (parseCoordinates(_latitude.text, _longitude.text) case ValidCoordinates(
      :final point,
    )) {
      return (point, 16.0);
    }
    final typed = _place.text.trim();
    if (typed.isNotEmpty) {
      final match = (await _places).search(typed, limit: 1).firstOrNull;
      if (match != null) return (match.location, 13.0);
    }
    return (null, 15.0);
  }

  void _selectPlace(Place place) {
    setState(() {
      _latitude.text = place.location.latitude.toStringAsFixed(4);
      _longitude.text = place.location.longitude.toStringAsFixed(4);
    });
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      if (parseCoordinates(_latitude.text, _longitude.text)
          is InvalidCoordinates) {
        setState(() => _showCoordinates = true);
      }
      return;
    }
    final location = switch (parseCoordinates(
      _latitude.text,
      _longitude.text,
    )) {
      ValidCoordinates(:final point) => point,
      _ => null,
    };
    final id = widget.entry?.id ?? widget.services.newId();
    final (year, month, day) = (_date.year, _date.month, _date.day);
    final (hour, minute) = (_time.hour, _time.minute);
    final entry = switch (_photoOffset) {
      // The photo's own offset keeps its local time, wherever the phone is.
      final offset? => Entry(
        id: id,
        tripId: widget.trip.id,
        time: DateTime.utc(year, month, day, hour, minute).subtract(offset),
        utcOffset: offset,
        note: _note.text,
        placeName: _place.text,
        location: location,
        photoPaths: _photos,
      ),
      null => Entry.atLocalTime(
        id: id,
        tripId: widget.trip.id,
        localTime: DateTime(year, month, day, hour, minute),
        note: _note.text,
        placeName: _place.text,
        location: location,
        photoPaths: _photos,
      ),
    };
    await widget.services.entryRepository.saveEntry(entry);
    _saved = true;
    final dropped = {
      ...?widget.entry?.photoPaths,
      ..._importedPhotos,
    }.difference(_photos.toSet());
    if (dropped.isNotEmpty) {
      await widget.services.photoLibrary.deletePhotos(dropped);
    }
    if (!mounted) return;
    await Navigator.of(context).maybePop();
  }

  Future<void> _confirmDelete(Entry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => const _DeleteEntryDialog(),
    );
    if (confirmed != true) return;
    await widget.services.entryRepository.deleteEntry(entry.id);
    _saved = true;
    await widget.services.photoLibrary.deletePhotos({
      ...entry.photoPaths,
      ..._importedPhotos,
    });
    if (!mounted) return;
    await Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final entry = widget.entry;
    return Scaffold(
      appBar: AppBar(
        title: Text(entry == null ? l10n.newEntry : l10n.editEntry),
        actions: [
          if (entry != null)
            IconButton(
              tooltip: l10n.deleteEntry,
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _confirmDelete(entry),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _PhotoSection(
              files: [
                for (final path in _photos)
                  (path, widget.services.photoLibrary.fileFor(path)),
              ],
              onAdd: _addPhotos,
              onRemove: _removePhoto,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _PickerField(
                    icon: Icons.event,
                    value: DateFormat.yMMMd(locale).format(_date),
                    label: l10n.entryDateLabel,
                    onTap: _pickDate,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _PickerField(
                    icon: Icons.schedule,
                    value: _time.format(context),
                    label: l10n.entryTimeLabel,
                    onTap: _pickTime,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _note,
              minLines: 4,
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w400),
              decoration: InputDecoration(
                labelText: l10n.entryNoteLabel,
                alignLabelWithHint: true,
              ),
              validator: _validateNote,
            ),
            const SizedBox(height: 16),
            RawAutocomplete<Place>(
              textEditingController: _place,
              focusNode: _placeFocus,
              displayStringForOption: (place) => place.name,
              optionsBuilder: (value) async =>
                  (await _places).search(value.text),
              onSelected: _selectPlace,
              fieldViewBuilder: (context, controller, focusNode, _) =>
                  TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: l10n.entryPlaceLabel,
                      prefixIcon: const Icon(Icons.place_outlined),
                    ),
                  ),
              optionsViewBuilder: (context, onSelected, options) =>
                  _PlaceOptions(
                    options: options.toList(),
                    onSelected: onSelected,
                  ),
            ),
            Wrap(
              children: [
                _MyPositionButton(
                  locating: _locating,
                  onPressed: _useMyPosition,
                ),
                TextButton.icon(
                  onPressed: _pickOnMap,
                  icon: const Icon(Icons.map_outlined),
                  label: Text(l10n.pickOnMap),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _CoordinatesHeader(
              value: switch (parseCoordinates(
                _latitude.text,
                _longitude.text,
              )) {
                ValidCoordinates(:final point) => l10n.coordinatesValue(
                  point.latitude.toStringAsFixed(4),
                  point.longitude.toStringAsFixed(4),
                ),
                _ => null,
              },
              expanded: _showCoordinates,
              onTap: () => setState(() => _showCoordinates = !_showCoordinates),
            ),
            Visibility(
              visible: _showCoordinates,
              maintainState: true,
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _latitude,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                        decoration: InputDecoration(
                          labelText: l10n.latitudeLabel,
                          errorMaxLines: 3,
                        ),
                        validator: _validateCoordinates,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _longitude,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                        decoration: InputDecoration(
                          labelText: l10n.longitudeLabel,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: _save, child: Text(l10n.save)),
          ],
        ),
      ),
    );
  }
}

class _PhotoSection extends StatelessWidget {
  const _PhotoSection({
    required this.files,
    required this.onAdd,
    required this.onRemove,
  });

  /// Relative path and file of every photo, in order.
  final List<(String, File)> files;
  final VoidCallback onAdd;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (files.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (path, file) in files)
                _RemovablePhoto(file: file, onRemove: () => onRemove(path)),
            ],
          ),
          const SizedBox(height: 8),
        ],
        OutlinedButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add_photo_alternate_outlined),
          label: Text(AppLocalizations.of(context).addPhotos),
        ),
      ],
    );
  }
}

class _RemovablePhoto extends StatelessWidget {
  const _RemovablePhoto({required this.file, required this.onRemove});

  final File file;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        PhotoThumbnail(file: file, size: 96),
        Positioned(
          top: 0,
          right: 0,
          child: IconButton.filledTonal(
            tooltip: AppLocalizations.of(context).removePhoto,
            iconSize: 18,
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.close),
            onPressed: onRemove,
          ),
        ),
      ],
    );
  }
}

class _MyPositionButton extends StatelessWidget {
  const _MyPositionButton({required this.locating, required this.onPressed});

  final bool locating;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return TextButton.icon(
      onPressed: locating ? null : onPressed,
      icon: locating
          ? const SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.my_location),
      label: Text(locating ? l10n.locatingPosition : l10n.useMyPosition),
    );
  }
}

class _PlaceOptions extends StatelessWidget {
  const _PlaceOptions({required this.options, required this.onSelected});

  final List<Place> options;
  final AutocompleteOnSelected<Place> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.topLeft,
      child: Material(
        elevation: 4,
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: 280,
            maxWidth: MediaQuery.sizeOf(context).width - 32,
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
    );
  }
}

class _CoordinatesHeader extends StatelessWidget {
  const _CoordinatesHeader({
    required this.value,
    required this.expanded,
    required this.onTap,
  });

  /// The current coordinates as text, `null` if none are set.
  final String? value;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: const Icon(Icons.my_location_outlined),
        title: Text(l10n.coordinatesTitle),
        subtitle: Text(value ?? l10n.coordinatesHint),
        trailing: Icon(expanded ? Icons.expand_less : Icons.expand_more),
        onTap: onTap,
      ),
    );
  }
}

class _PickerField extends StatelessWidget {
  const _PickerField({
    required this.icon,
    required this.value,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String value;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: Icon(icon),
        title: Text(value),
        subtitle: Text(label),
        onTap: onTap,
      ),
    );
  }
}

class _DeleteEntryDialog extends StatelessWidget {
  const _DeleteEntryDialog();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.deleteEntryQuestion),
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
