import 'dart:async';

import 'package:trailtale/domain/quick_capture_requests.dart';

/// [QuickCaptureRequests] for widget tests; [request] simulates a tap on
/// the home screen widget.
class FakeQuickCaptureRequests implements QuickCaptureRequests {
  final _requests = StreamController<void>.broadcast();

  void request() => _requests.add(null);

  @override
  Stream<void> get requests => _requests.stream;
}
