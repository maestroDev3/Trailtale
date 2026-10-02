import 'package:flutter/material.dart';

import '../domain/trip.dart';
import 'app_services.dart';

/// Shows the shareable picture of [trip] and shares or saves it.
class SharePictureScreen extends StatefulWidget {
  const SharePictureScreen({
    super.key,
    required this.services,
    required this.trip,
  });

  final AppServices services;
  final Trip trip;

  @override
  State<SharePictureScreen> createState() => _SharePictureScreenState();
}

class _SharePictureScreenState extends State<SharePictureScreen> {
  @override
  Widget build(BuildContext context) => const Scaffold();
}
