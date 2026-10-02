import 'package:intl/intl.dart';

import '../domain/trip_picture.dart';
import '../l10n/app_localizations.dart';

/// Formats a distance for summaries: one decimal below 10 km, whole
/// kilometers from 10 km, localized separators.
String formatKilometers(double meters, String locale) {
  final kilometers = meters / 1000;
  final decimals = kilometers == 0 || kilometers >= 10 ? 0 : 1;
  return NumberFormat.decimalPatternDigits(
    locale: locale,
    decimalDigits: decimals,
  ).format(kilometers);
}

/// Days, places and kilometers of a trip picture or slideshow, e.g.
/// “5 days · 3 places · 16 km”.
String pictureFactsText(AppLocalizations l10n, TripPicture picture) =>
    picture.distanceMeters > 0
    ? l10n.pictureFacts(
        picture.dayCount,
        picture.placeCount,
        formatKilometers(picture.distanceMeters, l10n.localeName),
      )
    : l10n.pictureFactsNoDistance(picture.dayCount, picture.placeCount);
