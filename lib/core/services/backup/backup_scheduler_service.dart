import 'package:workmanager/workmanager.dart';

import '../../utils/error_utils.dart';
import 'backup_service.dart';

const String careVaultAutomaticBackupTask = 'carevaultAutomaticBackupTask';
const String careVaultAutomaticBackupUniqueName = 'carevaultAutomaticBackup';

@pragma('vm:entry-point')
void careVaultBackupCallbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task != careVaultAutomaticBackupTask) return true;
    final service = BackupService();
    final result = await service.createAndUploadBackup(
      note: 'Automatic backup',
    );
    if (!result.success) {
      ErrorUtils.logWarning(result.message, tag: 'BackupScheduler');
    }
    return result.success;
  });
}

class BackupSchedulerService {
  final Workmanager _workmanager;

  BackupSchedulerService({Workmanager? workmanager})
    : _workmanager = workmanager ?? Workmanager();

  Future<void> initialize() {
    return _workmanager.initialize(
      careVaultBackupCallbackDispatcher,
      isInDebugMode: false,
    );
  }

  Future<void> applySettings(BackupSettings settings) async {
    if (!settings.automaticBackupEnabled) {
      await cancel();
      return;
    }

    await _workmanager.registerPeriodicTask(
      careVaultAutomaticBackupUniqueName,
      careVaultAutomaticBackupTask,
      frequency: settings.frequency == 'weekly'
          ? const Duration(days: 7)
          : const Duration(days: 1),
      constraints: Constraints(
        networkType: settings.onlyOnWifi
            ? NetworkType.unmetered
            : NetworkType.connected,
        requiresCharging: settings.onlyWhileCharging,
      ),
      backoffPolicy: BackoffPolicy.exponential,
      backoffPolicyDelay: const Duration(minutes: 30),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
    );
  }

  Future<void> cancel() {
    return _workmanager.cancelByUniqueName(careVaultAutomaticBackupUniqueName);
  }
}
