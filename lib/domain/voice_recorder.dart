import 'dart:io';

/// Records voice notes from the microphone, only while the app is in use.
abstract interface class VoiceRecorder {
  /// Asks for microphone access if needed and starts recording into
  /// [target]; `false` when access was not allowed (nothing is recorded).
  Future<bool> start(File target);

  /// Stops the recording and returns its length.
  Future<Duration> stop();

  /// Stops the recording and deletes it.
  Future<void> cancel();
}
