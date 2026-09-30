import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../domain/coordinates_input.dart';
import '../domain/default_entry_time.dart';
import '../domain/entry.dart';
import '../domain/trip.dart';
import '../l10n/app_localizations.dart';
import 'app_services.dart';

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
  }

  @override
  void dispose() {
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
    setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked == null || !mounted) return;
    setState(() => _time = picked);
  }

  String? _validateNote(String? note) {
    final l10n = AppLocalizations.of(context);
    final hasContent =
        (note ?? '').trim().isNotEmpty || _place.text.trim().isNotEmpty;
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
    final entry = Entry.atLocalTime(
      id: widget.entry?.id ?? widget.services.newId(),
      tripId: widget.trip.id,
      localTime: DateTime(
        _date.year,
        _date.month,
        _date.day,
        _time.hour,
        _time.minute,
      ),
      note: _note.text,
      placeName: _place.text,
      location: location,
    );
    await widget.services.entryRepository.saveEntry(entry);
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
