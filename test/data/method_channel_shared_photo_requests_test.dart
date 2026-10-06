import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trailtale/data/method_channel_shared_photo_requests.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('trailtale/shared_photos');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  void answerPendingPhotos(List<String> paths) {
    messenger.setMockMethodCallHandler(
      channel,
      (call) async => call.method == 'pendingPhotos' ? paths : null,
    );
  }

  Future<void> shareFromAndroid(List<String> paths) =>
      messenger.handlePlatformMessage(
        channel.name,
        const StandardMethodCodec().encodeMethodCall(
          MethodCall('photos', paths),
        ),
        (_) {},
      );

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  group('MethodChannelSharedPhotoRequests', () {
    test('emits the photos of a share that started the app', () async {
      answerPendingPhotos(['/cache/a.jpg', '/cache/b.jpg']);
      final shares = <List<String>>[];
      final subscription = MethodChannelSharedPhotoRequests().photos.listen(
        shares.add,
      );
      await pumpEventQueue();

      expect(shares, [
        ['/cache/a.jpg', '/cache/b.jpg'],
      ]);
      await subscription.cancel();
    });

    test('emits nothing for an empty pending share', () async {
      answerPendingPhotos(const []);
      final shares = <List<String>>[];
      final subscription = MethodChannelSharedPhotoRequests().photos.listen(
        shares.add,
      );
      await pumpEventQueue();

      expect(shares, isEmpty);
      await subscription.cancel();
    });

    test('emits the photos of every later share', () async {
      answerPendingPhotos(const []);
      final shares = <List<String>>[];
      final subscription = MethodChannelSharedPhotoRequests().photos.listen(
        shares.add,
      );
      await pumpEventQueue();

      await shareFromAndroid(['/cache/c.jpg']);
      await pumpEventQueue();

      expect(shares, [
        ['/cache/c.jpg'],
      ]);
      await subscription.cancel();
    });
  });
}
