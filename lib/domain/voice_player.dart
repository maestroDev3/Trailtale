import 'dart:io';

/// Plays voice notes, one at a time.
abstract interface class VoicePlayer {
  /// Plays [file], stopping whatever played before.
  Future<void> play(File file);

  /// Stops playing.
  Future<void> stop();

  /// The path of the file playing now, `null` when nothing plays; emits on
  /// every change, including the end of playback.
  Stream<String?> get nowPlaying;
}
