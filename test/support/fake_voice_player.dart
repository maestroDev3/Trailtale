import 'dart:async';
import 'dart:io';

import 'package:trailtale/domain/voice_player.dart';

/// [VoicePlayer] for widget tests that plays nothing but remembers what
/// happened; [finish] simulates the end of playback.
class FakeVoicePlayer implements VoicePlayer {
  final _nowPlaying = StreamController<String?>.broadcast();

  /// Files passed to [play], in order.
  final played = <File>[];
  var stopCount = 0;

  void finish() => _nowPlaying.add(null);

  @override
  Future<void> play(File file) async {
    played.add(file);
    _nowPlaying.add(file.path);
  }

  @override
  Future<void> stop() async {
    stopCount++;
    _nowPlaying.add(null);
  }

  @override
  Stream<String?> get nowPlaying => _nowPlaying.stream;
}
