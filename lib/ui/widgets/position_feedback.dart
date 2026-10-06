import 'package:flutter/material.dart';

import '../../domain/position_service.dart';
import '../../l10n/app_localizations.dart';

/// Why a position request found no position; `null` for a found position.
String? positionProblemText(AppLocalizations l10n, PositionResult result) =>
    switch (result) {
      PositionFound() => null,
      PositionDenied(permanently: false) => l10n.positionDenied,
      PositionDenied(permanently: true) => l10n.positionBlocked,
      PositionServiceOff() => l10n.positionServiceOff,
      PositionUnavailable() => l10n.positionUnavailable,
    };

/// The message for a position request that found no position, with a
/// shortcut to the settings where they can help; `null` for a found
/// position.
SnackBar? positionProblemSnackBar(
  AppLocalizations l10n,
  PositionResult result,
  PositionService service,
) {
  final message = positionProblemText(l10n, result);
  if (message == null) return null;
  return SnackBar(
    content: Text(message),
    action: positionSettingsAction(l10n, result, service),
  );
}

/// A shortcut to the settings that can fix [result], if there is one.
SnackBarAction? positionSettingsAction(
  AppLocalizations l10n,
  PositionResult result,
  PositionService service,
) => switch (result) {
  PositionDenied(permanently: true) => SnackBarAction(
    label: l10n.positionOpenSettings,
    onPressed: service.openAppSettings,
  ),
  PositionServiceOff() => SnackBarAction(
    label: l10n.positionTurnOn,
    onPressed: service.openLocationSettings,
  ),
  _ => null,
};
