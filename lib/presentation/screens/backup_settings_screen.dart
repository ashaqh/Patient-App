import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/spacing_constants.dart';
import '../../core/services/backup/backup_drive_service.dart';
import '../../core/services/backup/backup_scheduler_service.dart';
import '../../core/services/backup/backup_service.dart';
import '../../core/services/backup/restore_service.dart';
import '../../core/themes/app_theme.dart';
import '../providers/follow_up_provider.dart';
import '../providers/medicine_provider.dart';
import '../providers/prescription_provider.dart';
import '../providers/reminder_provider.dart';
import '../providers/test_report_provider.dart';
import '../providers/timeline_provider.dart';
import '../providers/vital_sign_provider.dart';
import '../widgets/common/glass_widgets.dart';

class _PassphraseDialog extends StatefulWidget {
  const _PassphraseDialog({
    required this.title,
    required this.message,
    required this.requireConfirmation,
    required this.submitLabel,
  });

  final String title;
  final String message;
  final bool requireConfirmation;
  final String submitLabel;

  @override
  State<_PassphraseDialog> createState() => _PassphraseDialogState();
}

class _PassphraseDialogState extends State<_PassphraseDialog> {
  late final TextEditingController _controller;
  late final TextEditingController _confirmController;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _confirmController = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _controller.text.trim();
    if (value.isEmpty) {
      setState(() => _errorText = 'Passphrase is required');
      return;
    }
    if (
      widget.requireConfirmation &&
      value != _confirmController.text.trim()
    ) {
      setState(() => _errorText = 'Passphrases do not match');
      return;
    }
    Navigator.pop(context, value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: AppTheme.outlineColor),
      ),
      title: Text(
        widget.title,
        style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.onSurfaceColor),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.m),
          TextField(
            controller: _controller,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'Passphrase',
              errorText: _errorText,
            ),
          ),
          if (widget.requireConfirmation) ...[
            const SizedBox(height: AppSpacing.m),
            TextField(
              controller: _confirmController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirm passphrase',
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
          ),
          child: Text(widget.submitLabel),
        ),
      ],
    );
  }
}

class BackupSettingsScreen extends ConsumerStatefulWidget {
  const BackupSettingsScreen({super.key});

  @override
  ConsumerState<BackupSettingsScreen> createState() =>
      _BackupSettingsScreenState();
}

class _BackupSettingsScreenState extends ConsumerState<BackupSettingsScreen> {
  final BackupService _backupService = BackupService();
  final BackupSchedulerService _schedulerService = BackupSchedulerService();
  final RestoreService _restoreService = RestoreService.instance;

  BackupAccountInfo? _account;
  BackupSettings _settings = BackupSettings.defaults;
  List<BackupDriveFile> _availableBackups = [];
  DateTime? _lastBackupDate;
  int? _lastBackupSize;
  bool _isLoading = true;
  bool _isBackingUp = false;
  bool _isRestoring = false;
  bool _hasSavedPassphrase = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    await _backupService.initialize();
    final settings = await _backupService.getSettings();
    final lastDate = await _backupService.getLastBackupDate();
    final lastSize = await _backupService.getLastBackupSize();
    final hasSavedPassphrase = await _backupService.hasBackupPassphrase();
    var backups = <BackupDriveFile>[];
    if (_backupService.currentAccount != null) {
      try {
        backups = await _backupService.getAvailableBackups();
      } catch (_) {
        backups = const [];
      }
    }
    if (!mounted) return;
    setState(() {
      _account = _backupService.currentAccount;
      _settings = settings;
      _lastBackupDate = lastDate;
      _lastBackupSize = lastSize;
      _hasSavedPassphrase = hasSavedPassphrase;
      _availableBackups = backups;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GradientOrbBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Backup & Restore'),
          backgroundColor: Colors.transparent,
          foregroundColor: AppTheme.onPrimaryColor,
          elevation: 0,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _load,
                color: AppTheme.primaryColor,
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
                  children: [
                    _section(
                      icon: Icons.account_circle_outlined,
                      title: 'Google Account',
                      child: _buildAccountSection(),
                    ),
                    const SizedBox(height: AppSpacing.l),
                    _section(
                      icon: Icons.cloud_upload_outlined,
                      title: 'Backup',
                      child: _buildBackupSection(),
                    ),
                    const SizedBox(height: AppSpacing.l),
                    _section(
                      icon: Icons.lock_outline,
                      title: 'Backup Passphrase',
                      child: _buildPassphraseSection(),
                    ),
                    const SizedBox(height: AppSpacing.l),
                    _section(
                      icon: Icons.schedule_outlined,
                      title: 'Automatic Backup',
                      child: _buildAutomaticBackupSection(),
                    ),
                    const SizedBox(height: AppSpacing.l),
                    _section(
                      icon: Icons.restore_outlined,
                      title: 'Restore',
                      child: _buildRestoreSection(),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _section({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      borderRadius: AppSpacing.borderRadiusMedium,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.primaryColor),
              const SizedBox(width: AppSpacing.m),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.m),
          child,
        ],
      ),
    );
  }

  Widget _buildAccountSection() {
    if (_account == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Backups are encrypted before upload and stored in CareVault app data on Google Drive.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.m),
          FilledButton.icon(
            onPressed: _connect,
            icon: const Icon(Icons.cloud),
            label: const Text('Connect Google Drive'),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        Row(
          children: [
            CircleAvatar(
              backgroundImage: _account!.photoUrl == null
                  ? null
                  : NetworkImage(_account!.photoUrl!),
              child: _account!.photoUrl == null
                  ? const Icon(Icons.person)
                  : null,
            ),
            const SizedBox(width: AppSpacing.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _account!.email,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const Text('Connected to Google Drive app data'),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.m),
        Wrap(
          spacing: AppSpacing.s,
          runSpacing: AppSpacing.s,
          children: [
            OutlinedButton.icon(
              onPressed: _changeAccount,
              icon: const Icon(Icons.swap_horiz),
              label: const Text('Change Account'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.onSurfaceColor,
                side: const BorderSide(color: AppTheme.outlineColor),
              ),
            ),
            OutlinedButton.icon(
              onPressed: _disconnect,
              icon: const Icon(Icons.link_off),
              label: const Text('Disconnect'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.errorColor,
                side: const BorderSide(color: AppTheme.errorColor),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBackupSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_isBackingUp) ...[
          const LinearProgressIndicator(color: AppTheme.primaryColor),
          const SizedBox(height: AppSpacing.m),
          const Text('Backup in progress...'),
        ] else
          FilledButton.icon(
            onPressed: _account == null ? null : _backupNow,
            icon: const Icon(Icons.backup_outlined),
            label: const Text('Backup Now'),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        const SizedBox(height: AppSpacing.m),
        _infoRow(
          'Last backup',
          _lastBackupDate == null ? 'Never' : _formatDateTime(_lastBackupDate!),
        ),
        _infoRow(
          'Backup size',
          _lastBackupSize == null
              ? 'Not available'
              : _formatFileSize(_lastBackupSize!),
        ),
        const SizedBox(height: AppSpacing.s),
        Text(
          'Includes database records, reminders, preferences, prescriptions, reports, images, and attachments.',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppTheme.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _buildPassphraseSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _hasSavedPassphrase
              ? 'A backup passphrase is saved on this device. You need the same passphrase to restore backups on another device.'
              : 'Set a backup passphrase before creating encrypted backups. Automatic backups stay disabled until a passphrase is configured.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.m),
        Wrap(
          spacing: AppSpacing.s,
          runSpacing: AppSpacing.s,
          children: [
            FilledButton.icon(
              onPressed: _configurePassphrase,
              icon: const Icon(Icons.password),
              label: Text(_hasSavedPassphrase ? 'Change Passphrase' : 'Set Passphrase'),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
            if (_hasSavedPassphrase)
              OutlinedButton.icon(
                onPressed: _clearPassphrase,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Clear Passphrase'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.errorColor,
                  side: const BorderSide(color: AppTheme.errorColor),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildAutomaticBackupSection() {
    return Column(
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: _settings.automaticBackupEnabled,
          activeColor: AppTheme.primaryColor,
          onChanged: _hasSavedPassphrase
              ? (value) => _saveSettings(
                    _settings.copyWith(automaticBackupEnabled: value),
                  )
              : (_) => _showSnack(
                    'Set a backup passphrase before enabling automatic backups.',
                  ),
          title: const Text('Enable Automatic Backup'),
        ),
        SegmentedButton<String>(
          style: SegmentedButton.styleFrom(
            selectedBackgroundColor: AppTheme.primaryColor,
            selectedForegroundColor: Colors.white,
          ),
          segments: const [
            ButtonSegment(
              value: 'daily',
              label: Text('Daily'),
              icon: Icon(Icons.today),
            ),
            ButtonSegment(
              value: 'weekly',
              label: Text('Weekly'),
              icon: Icon(Icons.date_range),
            ),
          ],
          selected: {_settings.frequency},
          onSelectionChanged: _settings.automaticBackupEnabled
              ? (value) =>
                    _saveSettings(_settings.copyWith(frequency: value.first))
              : null,
        ),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          value: _settings.onlyOnWifi,
          activeColor: AppTheme.primaryColor,
          onChanged: _settings.automaticBackupEnabled
              ? (value) =>
                    _saveSettings(_settings.copyWith(onlyOnWifi: value ?? true))
              : null,
          title: const Text('Only on WiFi'),
        ),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          value: _settings.onlyWhileCharging,
          activeColor: AppTheme.primaryColor,
          onChanged: _settings.automaticBackupEnabled
              ? (value) => _saveSettings(
                  _settings.copyWith(onlyWhileCharging: value ?? false),
                )
              : null,
          title: const Text('Only while charging'),
        ),
      ],
    );
  }

  Widget _buildRestoreSection() {
    if (_isRestoring) {
      return const Column(
        children: [
          LinearProgressIndicator(color: AppTheme.primaryColor),
          SizedBox(height: AppSpacing.m),
          Text('Restore in progress...'),
        ],
      );
    }

    if (_account == null) {
      return const Text('Connect Google Drive to view available backups.');
    }

    if (_availableBackups.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('No backups available'),
          const SizedBox(height: AppSpacing.m),
          OutlinedButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primaryColor,
              side: const BorderSide(color: AppTheme.primaryColor),
            ),
          ),
        ],
      );
    }

    return Column(
      children: _availableBackups.map(_backupTile).toList(growable: false),
    );
  }

  Widget _backupTile(BackupDriveFile backup) {
    final metadata = backup.metadata;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.cloud_done_outlined, color: AppTheme.primaryColor),
      title: Text(
        _formatDateTime(metadata.backupTimestamp.toLocal()),
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        '${metadata.deviceName ?? 'Unknown device'} • v${metadata.appVersion} • ${_formatFileSize(metadata.backupSize)}',
        style: const TextStyle(color: AppTheme.onSurfaceVariant),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Delete',
            icon: const Icon(Icons.delete_outline),
            color: AppTheme.errorColor,
            onPressed: () => _confirmDelete(backup),
          ),
          IconButton(
            tooltip: 'Restore',
            icon: const Icon(Icons.download, color: AppTheme.primaryColor),
            onPressed: () => _confirmRestore(backup),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(color: AppTheme.onSurfaceVariant))),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Future<void> _connect() async {
    final account = await _backupService.connectGoogleDrive();
    if (!mounted) return;
    if (account == null) {
      _showSnack('Google Drive connection cancelled.');
      return;
    }
    await _load();
  }

  Future<void> _changeAccount() async {
    final account = await _backupService.changeAccount();
    if (!mounted) return;
    if (account == null) {
      _showSnack('Google Drive connection cancelled.');
      return;
    }
    await _load();
  }

  Future<void> _disconnect() async {
    await _backupService.disconnectGoogleDrive();
    await _load();
  }

  Future<void> _backupNow() async {
    if (!_hasSavedPassphrase) {
      _showSnack('Set a backup passphrase before creating encrypted backups.');
      return;
    }

    setState(() => _isBackingUp = true);
    final result = await _backupService.createAndUploadBackup(
      note: 'Manual backup',
    );
    if (!mounted) return;
    setState(() => _isBackingUp = false);
    _showSnack(result.message);
    await _load();
  }

  Future<void> _configurePassphrase() async {
    final passphrase = await _promptForPassphrase(
      title: 'Set backup passphrase',
      message:
          'Create a passphrase for encrypted backups. You must remember this passphrase to restore backups on another device.',
      requireConfirmation: true,
      submitLabel: 'Save',
    );
    if (passphrase == null) return;

    await _backupService.saveBackupPassphrase(passphrase);
    if (!mounted) return;
    await _load();
    _showSnack('Backup passphrase saved on this device.');
  }

  Future<void> _clearPassphrase() async {
    await _backupService.clearBackupPassphrase();
    await _saveSettings(
      _settings.copyWith(automaticBackupEnabled: false),
    );
    if (!mounted) return;
    await _load();
    _showSnack('Backup passphrase cleared. Automatic backups were disabled.');
  }

  Future<String?> _promptForPassphrase({
    String title = 'Backup passphrase',
    String message = 'Enter the passphrase used to encrypt this backup.',
    bool requireConfirmation = false,
    String submitLabel = 'Continue',
  }) async {
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => _PassphraseDialog(
        title: title,
        message: message,
        requireConfirmation: requireConfirmation,
        submitLabel: submitLabel,
      ),
    );
  }

  Future<void> _saveSettings(BackupSettings settings) async {
    setState(() => _settings = settings);
    await _backupService.saveSettings(settings);
    await _schedulerService.applySettings(settings);
  }

  Future<void> _confirmDelete(BackupDriveFile backup) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceContainerHighest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppTheme.outlineColor),
        ),
        title: const Text('Delete backup?', style: TextStyle(fontWeight: FontWeight.w600)),
        content: Text(
          'Are you sure you want to delete this backup?\n\n'
          '${_formatDateTime(backup.metadata.backupTimestamp.toLocal())}\n'
          '${backup.metadata.deviceName ?? 'Unknown device'}\n'
          '${_formatFileSize(backup.metadata.backupSize)}\n\n'
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirmed != true) return;

    try {
      await _backupService.deleteBackup(backup.id);
      if (!mounted) return;
      _showSnack('Backup deleted successfully');
      await _load();
    } catch (e) {
      if (!mounted) return;
      _showSnack('Failed to delete backup: $e');
    }
  }

  Future<void> _confirmRestore(BackupDriveFile backup) async {
    final mode = await showDialog<RestoreMode>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceContainerHighest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppTheme.outlineColor),
        ),
        title: const Text('Restore backup?', style: TextStyle(fontWeight: FontWeight.w600)),
        content: const Text(
          'Restoring can overwrite local records and files. Choose Merge to combine records by ID, or Replace to replace local data with the backup.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, RestoreMode.merge),
            child: const Text('Merge'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, RestoreMode.replace),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Replace'),
          ),
        ],
      ),
    );
    if (mode == null) return;

    final savedPassphrase = await _backupService.getBackupPassphrase();
    final passphrase = savedPassphrase != null && savedPassphrase.trim().isNotEmpty
        ? savedPassphrase
        : await _promptForPassphrase(
            title: 'Enter backup passphrase',
            message:
                'Enter the passphrase that was used when this backup was created.',
            submitLabel: 'Restore',
          );
    if (passphrase == null || passphrase.trim().isEmpty) return;

    if (!mounted) return;
    setState(() => _isRestoring = true);
    try {
      final result = await _restoreService.restoreFromDriveBackup(
        backup.id,
        passphrase: passphrase,
        mode: mode,
      );
      if (!mounted) return;
      if (result.success) {
        _refreshRestoredState();
      }
      _showSnack(result.message);
    } finally {
      if (mounted) {
        setState(() => _isRestoring = false);
      }
    }
  }

  void _refreshRestoredState() {
    ref.invalidate(medicineListProvider);
    ref.invalidate(todaysMedicinesProvider);
    ref.invalidate(activeMedicinesProvider);
    ref.invalidate(medicineCountProvider);
    ref.invalidate(prescriptionListProvider);
    ref.invalidate(recentPrescriptionsProvider);
    ref.invalidate(prescriptionCountProvider);
    ref.invalidate(testReportListProvider);
    ref.invalidate(recentTestReportsProvider);
    ref.invalidate(testReportCountProvider);
    ref.invalidate(followUpListProvider);
    ref.invalidate(todaysFollowUpsProvider);
    ref.invalidate(upcomingFollowUpsProvider);
    ref.invalidate(overdueFollowUpsProvider);
    ref.invalidate(followUpStatisticsProvider);
    ref.invalidate(nextFollowUpProvider);
    ref.invalidate(vitalSignListProvider);
    ref.invalidate(todaysRemindersProvider);
    ref.invalidate(reminderStatisticsProvider);
    ref.invalidate(timelineListProvider);
  }

  void _showSnack(String message) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _formatDateTime(DateTime dateTime) {
    final local = dateTime.toLocal();
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')} '
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }
}
