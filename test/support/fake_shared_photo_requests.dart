import 'dart:async';

import 'package:trailtale/domain/shared_photo_requests.dart';

/// [SharedPhotoRequests] for widget tests; [share] simulates sharing photos
/// from another app.
class FakeSharedPhotoRequests implements SharedPhotoRequests {
  final _photos = StreamController<List<String>>.broadcast();

  void share(List<String> paths) => _photos.add(paths);

  @override
  Stream<List<String>> get photos => _photos.stream;
}
