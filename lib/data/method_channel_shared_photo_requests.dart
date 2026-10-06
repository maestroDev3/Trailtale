import 'package:flutter/services.dart';

import '../domain/shared_photo_requests.dart';

/// Photos shared to Trailtale on Android.
class MethodChannelSharedPhotoRequests implements SharedPhotoRequests {
  MethodChannelSharedPhotoRequests([
    this.channel = const MethodChannel('trailtale/shared_photos'),
  ]);

  final MethodChannel channel;

  @override
  Stream<List<String>> get photos => const Stream.empty();
}
