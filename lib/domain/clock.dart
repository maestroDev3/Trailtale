/// Source of the current time, injected so logic and tests never depend on
/// the real clock.
typedef Clock = DateTime Function();

/// Normalizes a point in time to its calendar day at midnight UTC, so that
/// days can be compared without daylight saving time shifting them.
///
/// The calendar day is taken from [dateTime] as given (local or UTC).
DateTime dayOf(DateTime dateTime) =>
    DateTime.utc(dateTime.year, dateTime.month, dateTime.day);
