import 'package:trailtale/domain/media_location_access.dart';

/// [MediaLocationAccess] for widget tests that records requests.
class FakeMediaLocationAccess implements MediaLocationAccess {
  FakeMediaLocationAccess({this.granted = true});

  /// What [request] answers.
  final bool granted;

  /// How often access was requested.
  var requestCount = 0;

  @override
  Future<bool> request() async {
    requestCount++;
    return granted;
  }
}
