import 'package:flutter/material.dart';

import '../domain/photo_gallery.dart';
import '../domain/trip.dart';

/// Lets the user choose photos from the device's gallery, starting with the
/// photos taken during [trip]; returns the chosen photo ids.
class GalleryPickerScreen extends StatefulWidget {
  const GalleryPickerScreen({
    super.key,
    required this.gallery,
    required this.trip,
    this.access = GalleryAccess.full,
    this.pageSize = 60,
  });

  final PhotoGallery gallery;
  final Trip trip;
  final GalleryAccess access;
  final int pageSize;

  @override
  State<GalleryPickerScreen> createState() => _GalleryPickerScreenState();
}

class _GalleryPickerScreenState extends State<GalleryPickerScreen> {
  @override
  Widget build(BuildContext context) => const Scaffold();
}
