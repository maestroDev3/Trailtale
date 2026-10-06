import 'package:flutter/services.dart';

import '../domain/quick_capture_requests.dart';

/// Quick capture requests from Android (home screen widget “I'm here”).
class MethodChannelQuickCaptureRequests implements QuickCaptureRequests {
  MethodChannelQuickCaptureRequests([
    this._channel = const MethodChannel('trailtale/quick_capture'),
  ]);

  final MethodChannel _channel;

  @override
  Stream<void> get requests => const Stream.empty();
}
