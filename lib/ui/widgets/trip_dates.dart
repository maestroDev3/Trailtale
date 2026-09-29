import 'package:flutter/widgets.dart';

import '../../domain/clock.dart';
import '../../domain/trip.dart';
import '../../l10n/app_localizations.dart';

/// Localized text for a date range: a single date if both days are equal,
/// otherwise the range.
String dateRangeText(BuildContext context, DateTime start, DateTime end) {
  final l10n = AppLocalizations.of(context);
  return dayOf(start) == dayOf(end)
      ? l10n.tripSingleDate(start)
      : l10n.tripDateRange(start, end);
}

/// Localized date text of a trip.
String tripDatesText(BuildContext context, Trip trip) =>
    dateRangeText(context, trip.startDate, trip.endDate);
