/// Requests to save the current place quickly, e.g. from the home screen
/// widget “I'm here”.
abstract interface class QuickCaptureRequests {
  /// One event per request, including one that started the app.
  Stream<void> get requests;
}
