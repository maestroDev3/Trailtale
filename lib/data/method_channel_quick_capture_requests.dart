import 'dart:async';

import 'package:flutter/services.dart';

import '../domain/quick_capture_requests.dart';

/// Quick capture requests from Android (home screen widget “I'm here”):
/// a request that started the app is asked for once, later ones arrive as
/// `capture` calls.
class MethodChannelQuickCaptureRequests implements QuickCaptureRequests {
  MethodChannelQuickCaptureRequests([
    this._channel = const MethodChannel('trailtale/quick_capture'),
  ]);

  final MethodChannel _channel;

  @override
  Stream<void> get requests {
    late final StreamController<void> controller;
    controller = StreamController<void>(
      onListen: () {
        _channel.setMethodCallHandler((call) async {
          if (call.method == 'capture') controller.add(null);
        });
        unawaited(
          _channel.invokeMethod<bool>('pendingRequest').then((pending) {
            if (pending ?? false) controller.add(null);
          }, onError: controller.addError),
        );
      },
      onCancel: () => _channel.setMethodCallHandler(null),
    );
    return controller.stream;
  }
}
