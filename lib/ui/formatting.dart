import 'package:intl/intl.dart';

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
