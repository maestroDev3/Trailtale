/// Access to the location stored in the user's photos. Without it, Android
/// removes GPS data from picked photos; everything else keeps working.
abstract interface class MediaLocationAccess {
  /// Asks the user if needed; returns whether access is granted.
  Future<bool> request();
}
