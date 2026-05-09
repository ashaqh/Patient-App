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
      _availableBackups = backups;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.secondaryColor,
      appBar: AppBar(
        title: const Text('Backup & Restore'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: AppTheme.onPrimaryColor,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
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
    );
  }

  Widget _section({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMedium),
        side: const BorderSide(width: 1, color: AppTheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppTheme.primaryColor),
                const SizedBox(width: AppSpacing.m),
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppTheme.onSurfaceColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.m),
            child,
          ],
        ),
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
            ),
            OutlinedButton.icon(
              onPressed: _disconnect,
              icon: const Icon(Icons.link_off),
              label: const Text('Disconnect'),
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
          const LinearProgressIndicator(),
          const SizedBox(height: AppSpacing.m),
          const Text('Backup in progress...'),
        ] else
          FilledButton.icon(
            onPressed: _account == null ? null : _backupNow,
            icon: const Icon(Icons.backup_outlined),
            label: const Text('Backup Now'),
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

  Widget _buildAutomaticBackupSection() {
    return Column(
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: _settings.automaticBackupEnabled,
          onChanged: (value) =>
              _saveSettings(_settings.copyWith(automaticBackupEnabled: value)),
          title: const Text('Enable Automatic Backup'),
        ),
        SegmentedButton<String>(
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
          onChanged: _settings.automaticBackupEnabled
              ? (value) =>
                    _saveSettings(_settings.copyWith(onlyOnWifi: value ?? true))
              : null,
          title: const Text('Only on WiFi'),
        ),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          value: _settings.onlyWhileCharging,
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
          LinearProgressIndicator(),
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
      leading: const Icon(Icons.cloud_done_outlined),
      title: Text(_formatDateTime(metadata.backupTimestamp.toLocal())),
      subtitle: Text(
        '${metadata.deviceName ?? 'Unknown device'} • v${metadata.appVersion} • ${_formatFileSize(metadata.backupSize)}',
      ),
      trailing: IconButton(
        tooltip: 'Restore',
        icon: const Icon(Icons.download),
        onPressed: () => _confirmRestore(backup),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(child: Text(label)),
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
    setState(() => _isBackingUp = true);
    final result = await _backupService.createAndUploadBackup(
      note: 'Manual backup',
    );
    if (!mounted) return;
    setState(() => _isBackingUp = false);
    _showSnack(result.message);
    await _load();
  }

  Future<void> _saveSettings(BackupSettings settings) async {
    setState(() => _settings = settings);
    await _backupService.saveSettings(settings);
    await _schedulerService.applySettings(settings);
  }

  Future<void> _confirmRestore(BackupDriveFile backup) async {
    final mode = await showDialog<RestoreMode>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore backup?'),
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
            child: const Text('Replace'),
          ),
        ],
      ),
    );
    if (mode == null) return;

    setState(() => _isRestoring = true);
    final result = await _restoreService.restoreFromDriveBackup(
      backup.id,
      mode: mode,
    );
    if (!mounted) return;
    setState(() => _isRestoring = false);
    if (result.success) {
      _refreshRestoredState();
    }
    _showSnack(result.message);
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
