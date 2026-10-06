import 'dart:io';

import 'package:record/record.dart';

import '../domain/clock.dart';
import '../domain/voice_recorder.dart';

/// Records voice notes with the `record` package as AAC in an `.m4a` file;
/// microphone access is asked for on the first recording.
class RecordVoiceRecorder implements VoiceRecorder {
  RecordVoiceRecorder([this._clock = DateTime.now]);

  final Clock _clock;
  final _recorder = AudioRecorder();
  DateTime? _startedAt;

  @override
  Future<bool> start(File target) async {
    if (!await _recorder.hasPermission()) return false;
    await target.parent.create(recursive: true);
    await _recorder.start(const RecordConfig(), path: target.path);
    _startedAt = _clock();
    return true;
  }

  @override
  Future<Duration> stop() async {
    await _recorder.stop();
    final startedAt = _startedAt;
    _startedAt = null;
    return startedAt == null ? Duration.zero : _clock().difference(startedAt);
  }

  @override
  Future<void> cancel() async {
    _startedAt = null;
    await _recorder.cancel();
  }
}
