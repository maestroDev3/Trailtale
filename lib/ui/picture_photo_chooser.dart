import 'package:flutter/material.dart';

import '../domain/entry.dart';
import 'app_services.dart';

/// Lets the traveler choose up to four photos for the trip picture.
class PicturePhotoChooser extends StatefulWidget {
  const PicturePhotoChooser({
    super.key,
    required this.services,
    required this.entries,
    required this.selected,
  });

  final AppServices services;
  final List<Entry> entries;
  final List<String> selected;

  @override
  State<PicturePhotoChooser> createState() => _PicturePhotoChooserState();
}

class _PicturePhotoChooserState extends State<PicturePhotoChooser> {
  @override
  Widget build(BuildContext context) => const Scaffold();
}
