import 'dart:io';

import '../domain/voice_recorder.dart';

/// Records voice notes with the `record` package.
class RecordVoiceRecorder implements VoiceRecorder {
  @override
  Future<bool> start(File target) async => false;

  @override
  Future<Duration> stop() async => Duration.zero;

  @override
  Future<void> cancel() async {}
}
