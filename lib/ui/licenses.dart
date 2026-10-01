import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Adds the attribution of the bundled place data (GeoNames, CC BY 4.0) to
/// the app's licenses page.
void registerPlaceDataLicense() {
  LicenseRegistry.addLicense(() async* {
    final text = await rootBundle.loadString(
      'assets/places/GEONAMES_LICENSE.txt',
    );
    yield LicenseEntryWithLineBreaks(['GeoNames'], text);
  });
}
