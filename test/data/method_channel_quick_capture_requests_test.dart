import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trailtale/data/method_channel_quick_capture_requests.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('trailtale/quick_capture');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  void answerPendingRequest({required bool pending}) {
    messenger.setMockMethodCallHandler(
      channel,
      (call) async => call.method == 'pendingRequest' ? pending : null,
    );
  }

  Future<void> captureFromAndroid() => messenger.handlePlatformMessage(
    channel.name,
    const StandardMethodCodec().encodeMethodCall(const MethodCall('capture')),
    (_) {},
  );

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  group('MethodChannelQuickCaptureRequests', () {
    test('emits a request that started the app', () async {
      answerPendingRequest(pending: true);
      var count = 0;
      final subscription = MethodChannelQuickCaptureRequests().requests.listen(
        (_) => count++,
      );
      await pumpEventQueue();

      expect(count, 1);
      await subscription.cancel();
    });

    test('emits nothing without a pending request', () async {
      answerPendingRequest(pending: false);
      var count = 0;
      final subscription = MethodChannelQuickCaptureRequests().requests.listen(
        (_) => count++,
      );
      await pumpEventQueue();

      expect(count, 0);
      await subscription.cancel();
    });

    test('emits a request for every capture call from Android', () async {
      answerPendingRequest(pending: false);
      var count = 0;
      final subscription = MethodChannelQuickCaptureRequests().requests.listen(
        (_) => count++,
      );
      await pumpEventQueue();

      await captureFromAndroid();
      await captureFromAndroid();
      await pumpEventQueue();

      expect(count, 2);
      await subscription.cancel();
    });
  });
}
