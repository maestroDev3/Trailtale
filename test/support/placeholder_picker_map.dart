import 'package:trailtale/domain/geo_point.dart';
import 'package:trailtale/ui/widgets/picker_map.dart';

/// A [PickerMapBuilder] for widget tests (no network). Shows its center as
/// “Map center: lat, lng”; with [panTo], a “Pan map” button simulates the
/// user moving the map there.
PickerMapBuilder placeholderPickerMap({GeoPoint? panTo}) =>
    throw UnimplementedError();
