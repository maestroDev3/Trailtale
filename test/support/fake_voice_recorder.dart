import 'dart:io';

import 'package:trailtale/domain/voice_recorder.dart';

/// [VoiceRecorder] for widget tests that records nothing but remembers what
/// happened.
class FakeVoiceRecorder implements VoiceRecorder {
  FakeVoiceRecorder({
    this.allowed = true,
    this.length = const Duration(seconds: 5),
  });

  /// Whether microphone access is allowed.
  bool allowed;

  /// What [stop] returns.
  Duration length;

  /// Targets of started recordings, in order.
  final started = <File>[];
  var stopCount = 0;
  var cancelCount = 0;

  @override
  Future<bool> start(File target) async {
    if (!allowed) return false;
    started.add(target);
    return true;
  }

  @override
  Future<Duration> stop() async {
    stopCount++;
    return length;
  }

  @override
  Future<void> cancel() async => cancelCount++;
}
