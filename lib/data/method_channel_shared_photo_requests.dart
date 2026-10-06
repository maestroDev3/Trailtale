import 'dart:async';

import 'package:flutter/services.dart';

import '../domain/shared_photo_requests.dart';

/// Photos shared to Trailtale on Android: Android copies them into the app
/// cache; a share that started the app is asked for once (`pendingPhotos`),
/// later shares arrive as `photos` calls.
class MethodChannelSharedPhotoRequests implements SharedPhotoRequests {
  MethodChannelSharedPhotoRequests([
    this._channel = const MethodChannel('trailtale/shared_photos'),
  ]);

  final MethodChannel _channel;

  @override
  Stream<List<String>> get photos {
    late final StreamController<List<String>> controller;
    void emit(List<String>? paths) {
      if (paths != null && paths.isNotEmpty) controller.add(paths);
    }

    controller = StreamController<List<String>>(
      onListen: () {
        _channel.setMethodCallHandler((call) async {
          if (call.method == 'photos') {
            emit((call.arguments as List<Object?>?)?.whereType<String>().toList());
          }
        });
        unawaited(
          _channel
              .invokeListMethod<String>('pendingPhotos')
              .then(emit, onError: controller.addError),
        );
      },
      onCancel: () => _channel.setMethodCallHandler(null),
    );
    return controller.stream;
  }
}
