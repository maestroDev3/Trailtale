import 'package:flutter/widgets.dart';

import '../../domain/trip.dart';
import '../../l10n/app_localizations.dart';

/// Localized date text of a trip: a single date for one-day trips, otherwise
/// the range.
String tripDatesText(BuildContext context, Trip trip) {
  final l10n = AppLocalizations.of(context);
  return trip.dayCount == 1
      ? l10n.tripSingleDate(trip.startDate)
      : l10n.tripDateRange(trip.startDate, trip.endDate);
}
