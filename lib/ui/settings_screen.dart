import 'package:flutter/material.dart';

import '../domain/backup_service.dart';
import '../l10n/app_localizations.dart';
import 'app_services.dart';

/// Settings: backing up and restoring all data, and the licenses.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.services});

  final AppServices services;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  var _busy = false;

  Future<void> _backUp() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      final backup = await widget.services.backupService.createBackup();
      await widget.services.fileSharer.shareFile(
        backup,
        subject: l10n.backupSubject,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restore() async {
    final services = widget.services;
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final file = await services.documentPicker.pickBackup();
    if (file == null || !mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => const _RestoreDialog(),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await services.backupService.restoreBackup(file);
      await services.tripRepository.reload();
      await services.entryRepository.reload();
      messenger.showSnackBar(SnackBar(content: Text(l10n.backupRestored)));
    } on InvalidBackupException {
      messenger.showSnackBar(SnackBar(content: Text(l10n.invalidBackup)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
        bottom: _busy
            ? const PreferredSize(
                preferredSize: Size.fromHeight(4),
                child: LinearProgressIndicator(),
              )
            : null,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _SectionTitle(l10n.backupSection),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.cloud_upload_outlined),
                  title: Text(l10n.backUpNow),
                  subtitle: Text(l10n.backUpNowDescription),
                  enabled: !_busy,
                  onTap: _backUp,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.settings_backup_restore),
                  title: Text(l10n.restoreBackup),
                  subtitle: Text(l10n.restoreBackupDescription),
                  enabled: !_busy,
                  onTap: _restore,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
            child: Text(
              l10n.autoBackupInfo,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _SectionTitle(l10n.aboutSection),
          Card(
            child: ListTile(
              leading: const Icon(Icons.description_outlined),
              title: Text(l10n.openSourceLicenses),
              onTap: () =>
                  showLicensePage(context: context, applicationName: l10n.appTitle),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 6),
      child: Text(
        text,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _RestoreDialog extends StatelessWidget {
  const _RestoreDialog();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.restoreQuestion),
      content: Text(l10n.restoreWarning),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.restore),
        ),
      ],
    );
  }
}
