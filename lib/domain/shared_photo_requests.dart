/// Photos other apps shared to Trailtale (Android share sheet).
abstract interface class SharedPhotoRequests {
  /// One event per share with the absolute paths of the shared photos,
  /// including a share that started the app.
  Stream<List<String>> get photos;
}
