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
/// Figures of a day picture, e.g. “2 places · 12 km”.
String dayPictureFactsText(AppLocalizations l10n, TripPicture picture) => [
  l10n.placeCount(picture.placeCount),
  if (picture.distanceMeters > 0)
    l10n.distanceKm(formatKilometers(picture.distanceMeters, l10n.localeName)),
].join(' · ');

String pictureFactsText(AppLocalizations l10n, TripPicture picture) =>
    picture.distanceMeters > 0
    ? l10n.pictureFacts(
        picture.dayCount,
        picture.placeCount,
        formatKilometers(picture.distanceMeters, l10n.localeName),
      )
    : l10n.pictureFactsNoDistance(picture.dayCount, picture.placeCount);

/// Length of a voice note as minutes and seconds, e.g. “0:12”.
String formatVoiceLength(Duration length) {
  final seconds = (length.inSeconds % 60).toString().padLeft(2, '0');
  return '${length.inMinutes}:$seconds';
}
