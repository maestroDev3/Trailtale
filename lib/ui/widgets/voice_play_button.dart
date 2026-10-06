import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../../domain/voice_player.dart';
import '../../l10n/app_localizations.dart';

/// Plays or stops a voice note; shows “play” again when it ends or another
/// voice note starts.
class VoicePlayButton extends StatefulWidget {
  const VoicePlayButton({super.key, required this.player, required this.file});

  final VoicePlayer player;
  final File file;

  @override
  State<VoicePlayButton> createState() => _VoicePlayButtonState();
}

class _VoicePlayButtonState extends State<VoicePlayButton> {
  late final StreamSubscription<String?> _subscription;
  var _playing = false;

  @override
  void initState() {
    super.initState();
    _subscription = widget.player.nowPlaying.listen((path) {
      if (mounted) setState(() => _playing = path == widget.file.path);
    });
  }

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_playing) {
      setState(() => _playing = false);
      await widget.player.stop();
    } else {
      setState(() => _playing = true);
      await widget.player.play(widget.file);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return IconButton(
      tooltip: _playing ? l10n.stopVoiceNote : l10n.playVoiceNote,
      icon: Icon(
        _playing ? Icons.stop_circle_outlined : Icons.play_circle_outline,
      ),
      color: Theme.of(context).colorScheme.primary,
      onPressed: _toggle,
    );
  }
}
