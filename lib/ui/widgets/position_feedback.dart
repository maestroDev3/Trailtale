import 'package:flutter/material.dart';

import '../../domain/position_service.dart';
import '../../l10n/app_localizations.dart';

/// The message for a position request that found no position, with a
/// shortcut to the settings where they can help; `null` for a found
/// position.
SnackBar? positionProblemSnackBar(
  AppLocalizations l10n,
  PositionResult result,
  PositionService service,
) {
  final (message, action) = switch (result) {
    PositionFound() => (null, null),
    PositionDenied(permanently: false) => (l10n.positionDenied, null),
    PositionDenied(permanently: true) => (
      l10n.positionBlocked,
      SnackBarAction(
        label: l10n.positionOpenSettings,
        onPressed: service.openAppSettings,
      ),
    ),
    PositionServiceOff() => (
      l10n.positionServiceOff,
      SnackBarAction(
        label: l10n.positionTurnOn,
        onPressed: service.openLocationSettings,
      ),
    ),
    PositionUnavailable() => (l10n.positionUnavailable, null),
  };
  if (message == null) return null;
  return SnackBar(content: Text(message), action: action);
}
