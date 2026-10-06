import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';

import '../domain/voice_player.dart';

/// Plays voice notes with the `audioplayers` package, one at a time.
class AudioplayersVoicePlayer implements VoicePlayer {
  AudioplayersVoicePlayer() {
    _player.onPlayerComplete.listen((_) => _nowPlaying.add(null));
  }

  final _player = AudioPlayer();
  final _nowPlaying = StreamController<String?>.broadcast();

  @override
  Future<void> play(File file) async {
    await _player.stop();
    _nowPlaying.add(file.path);
    await _player.play(DeviceFileSource(file.path));
  }

  @override
  Future<void> stop() async {
    _nowPlaying.add(null);
    await _player.stop();
  }

  @override
  Stream<String?> get nowPlaying => _nowPlaying.stream;
}
