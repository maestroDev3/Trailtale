import 'package:flutter/material.dart';

import '../domain/geo_point.dart';
import '../domain/place.dart';
import 'app_services.dart';

/// The point the user picked and the town nearest to it, if any.
typedef PickedPlace = ({GeoPoint location, Place? nearestPlace});

/// Lets the user pick a place by moving a map under a fixed crosshair.
class PlacePickerScreen extends StatefulWidget {
  const PlacePickerScreen({
    super.key,
    required this.services,
    this.initialCenter,
    this.initialZoom = 15,
  });

  final AppServices services;
  final GeoPoint? initialCenter;
  final double initialZoom;

  @override
  State<PlacePickerScreen> createState() => _PlacePickerScreenState();
}

class _PlacePickerScreenState extends State<PlacePickerScreen> {
  @override
  Widget build(BuildContext context) => const Scaffold();
}
