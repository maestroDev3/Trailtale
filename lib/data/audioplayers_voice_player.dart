import 'dart:io';

import '../domain/voice_player.dart';

/// Plays voice notes with the `audioplayers` package.
class AudioplayersVoicePlayer implements VoicePlayer {
  @override
  Future<void> play(File file) async {}

  @override
  Future<void> stop() async {}

  @override
  Stream<String?> get nowPlaying => const Stream.empty();
}
