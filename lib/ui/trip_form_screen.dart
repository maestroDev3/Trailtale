import 'package:flutter/material.dart';

import '../domain/clock.dart';
import '../domain/id_generator.dart';
import '../domain/trip.dart';
import '../domain/trip_repository.dart';
import '../l10n/app_localizations.dart';
import 'widgets/trip_dates.dart';

/// Form for creating a new trip or, when [trip] is given, editing it.
class TripFormScreen extends StatefulWidget {
  const TripFormScreen({
    super.key,
    required this.tripRepository,
    required this.newId,
    this.clock = DateTime.now,
    this.trip,
  });

  final TripRepository tripRepository;
  final IdGenerator newId;
  final Clock clock;
  final Trip? trip;

  @override
  State<TripFormScreen> createState() => _TripFormScreenState();
}

class _TripFormScreenState extends State<TripFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late DateTimeRange _dates;

  @override
  void initState() {
    super.initState();
    final trip = widget.trip;
    _title = TextEditingController(text: trip?.title ?? '');
    final today = _localDay(widget.clock());
    _dates = trip == null
        ? DateTimeRange(start: today, end: today)
        : DateTimeRange(
            start: _localDay(trip.startDate),
            end: _localDay(trip.endDate),
          );
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _pickDates() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(1900),
      lastDate: DateTime(2200),
      initialDateRange: _dates,
    );
    if (picked == null || !mounted) return;
    setState(() => _dates = picked);
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final trip = Trip(
      id: widget.trip?.id ?? widget.newId(),
      title: _title.text,
      startDate: _dates.start,
      endDate: _dates.end,
    );
    await widget.tripRepository.saveTrip(trip);
    if (!mounted) return;
    await Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.trip == null ? l10n.newTrip : l10n.editTrip),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _title,
              autofocus: widget.trip == null,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: l10n.tripTitleLabel,
                border: const OutlineInputBorder(),
              ),
              validator: (value) =>
                  (value ?? '').trim().isEmpty ? l10n.tripTitleRequired : null,
            ),
            const SizedBox(height: 16),
            _DatesField(dates: _dates, onTap: _pickDates),
            const SizedBox(height: 24),
            FilledButton(onPressed: _save, child: Text(l10n.save)),
          ],
        ),
      ),
    );
  }
}

class _DatesField extends StatelessWidget {
  const _DatesField({required this.dates, required this.onTap});

  final DateTimeRange dates;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: const Icon(Icons.date_range),
        title: Text(dateRangeText(context, dates.start, dates.end)),
        subtitle: Text(AppLocalizations.of(context).tripDatesLabel),
        onTap: onTap,
      ),
    );
  }
}

DateTime _localDay(DateTime dateTime) =>
    DateTime(dateTime.year, dateTime.month, dateTime.day);
