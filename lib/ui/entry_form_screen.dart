import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../domain/coordinates_input.dart';
import '../domain/default_entry_time.dart';
import '../domain/entry.dart';
import '../domain/photo_metadata.dart';
import '../domain/photo_suggestion.dart';
import '../domain/trip.dart';
import '../l10n/app_localizations.dart';
import 'app_services.dart';
import 'widgets/photo_thumbnail.dart';

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
  late DateTime _date;
  late TimeOfDay _time;
  late final List<String> _photos;

  /// Photos imported while this form is open; deleted again unless saved.
  final _importedPhotos = <String>{};
  var _saved = false;

  /// Metadata of the photos added while this form is open.
  final _addedMetadata = <PhotoMetadata>[];

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
    final services = widget.services;
    final picked = await services.photoPicker.pickImages();
    final imported = <String>[];
    for (final source in picked) {
      imported.add(await services.photoLibrary.importPhoto(source));
    }
    _importedPhotos.addAll(imported);
    for (final path in imported) {
      final file = services.photoLibrary.fileFor(path);
      _addedMetadata.add(await services.photoMetadataReader.read(file));
    }
    if (!mounted) return;
    setState(() => _photos.addAll(imported));
    _applySuggestion(suggestFromPhotos(_addedMetadata));
  }

  /// Fills date, time and coordinates from photos where the user has not
  /// set them, and tells the user what was taken over.
  void _applySuggestion(PhotoSuggestion suggestion) {
    final takenAt = suggestion.takenAt;
    final applyTime =
        takenAt != null && widget.entry == null && !_dateTimeSetByUser;
    final location = suggestion.location;
    final applyPlace =
        location != null &&
        _latitude.text.trim().isEmpty &&
        _longitude.text.trim().isEmpty;
    if (!applyTime && !applyPlace) return;
    setState(() {
      if (applyTime) {
        _date = DateTime(takenAt.year, takenAt.month, takenAt.day);
        _time = TimeOfDay(hour: takenAt.hour, minute: takenAt.minute);
        _photoOffset = suggestion.utcOffset;
      }
      if (applyPlace) {
        _latitude.text = location.latitude.toStringAsFixed(6);
        _longitude.text = location.longitude.toStringAsFixed(6);
      }
    });
    final l10n = AppLocalizations.of(context);
    final message = switch ((applyTime, applyPlace)) {
      (true, true) => l10n.takenFromPhotoDateAndPlace,
      (true, false) => l10n.takenFromPhotoDate,
      _ => l10n.takenFromPhotoPlace,
    };
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
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

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
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
            _PickerField(
              icon: Icons.event,
              value: DateFormat.yMMMd(locale).format(_date),
              label: l10n.entryDateLabel,
              onTap: _pickDate,
            ),
            const SizedBox(height: 8),
            _PickerField(
              icon: Icons.schedule,
              value: _time.format(context),
              label: l10n.entryTimeLabel,
              onTap: _pickTime,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _note,
              minLines: 3,
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: l10n.entryNoteLabel,
                border: const OutlineInputBorder(),
              ),
              validator: _validateNote,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _place,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: l10n.entryPlaceLabel,
                prefixIcon: const Icon(Icons.place_outlined),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            _PhotoSection(
              files: [
                for (final path in _photos)
                  (path, widget.services.photoLibrary.fileFor(path)),
              ],
              onAdd: _addPhotos,
              onRemove: _removePhoto,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _latitude,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              decoration: InputDecoration(
                labelText: l10n.latitudeLabel,
                border: const OutlineInputBorder(),
              ),
              validator: _validateCoordinates,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _longitude,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              decoration: InputDecoration(
                labelText: l10n.longitudeLabel,
                border: const OutlineInputBorder(),
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
