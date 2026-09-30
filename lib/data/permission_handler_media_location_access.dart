import 'package:permission_handler/permission_handler.dart';

import '../domain/media_location_access.dart';

/// Requests Android's `ACCESS_MEDIA_LOCATION` runtime permission.
class PermissionHandlerMediaLocationAccess implements MediaLocationAccess {
  @override
  Future<bool> request() async =>
      (await Permission.accessMediaLocation.request()).isGranted;
}
