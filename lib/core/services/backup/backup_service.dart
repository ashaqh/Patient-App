import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../../data/datasources/database_constants.dart';
import '../../../data/datasources/database_helper.dart';
import '../../constants/app_constants.dart';
import '../../models/backup_metadata.dart';
import '../../utils/device_info_service.dart';
import '../../utils/error_utils.dart';
import '../../utils/network_info_service.dart';
import 'backup_drive_service.dart';
import 'backup_package_service.dart';

class BackupOperationResult {
  final bool success;
  final String message;
  final BackupMetadata? metadata;

  const BackupOperationResult({
    required this.success,
    required this.message,
    this.metadata,
  });
}

class BackupSettings {
  final bool automaticBackupEnabled;
  final String frequency;
  final bool onlyOnWifi;
  final bool onlyWhileCharging;
  final int retentionCount;

  const BackupSettings({
    required this.automaticBackupEnabled,
    required this.frequency,
    required this.onlyOnWifi,
    required this.onlyWhileCharging,
    required this.retentionCount,
  });

  static const defaults = BackupSettings(
    automaticBackupEnabled: false,
    frequency: 'daily',
    onlyOnWifi: true,
    onlyWhileCharging: false,
    retentionCount: 5,
  );

  BackupSettings copyWith({
    bool? automaticBackupEnabled,
    String? frequency,
    bool? onlyOnWifi,
    bool? onlyWhileCharging,
    int? retentionCount,
  }) {
    return BackupSettings(
      automaticBackupEnabled:
          automaticBackupEnabled ?? this.automaticBackupEnabled,
      frequency: frequency ?? this.frequency,
      onlyOnWifi: onlyOnWifi ?? this.onlyOnWifi,
      onlyWhileCharging: onlyWhileCharging ?? this.onlyWhileCharging,
      retentionCount: retentionCount ?? this.retentionCount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'automaticBackupEnabled': automaticBackupEnabled,
      'frequency': frequency,
      'onlyOnWifi': onlyOnWifi,
      'onlyWhileCharging': onlyWhileCharging,
      'retentionCount': retentionCount,
    };
  }
}

class BackupService {
  static final BackupService _instance = BackupService._internal();
  factory BackupService() => _instance;
  BackupService._internal()
    : _databaseHelper = DatabaseHelper(),
      _driveService = BackupDriveService(),
      _packageService = BackupPackageService(),
      _deviceInfoService = DeviceInfoService(),
      _networkInfoService = NetworkInfoService();

  static const _lastBackupDateKey = 'backup_last_date';
  static const _lastBackupSizeKey = 'backup_last_size';
  static const _autoEnabledKey = 'backup_auto_enabled';
  static const _frequencyKey = 'backup_frequency';
  static const _wifiOnlyKey = 'backup_wifi_only';
  static const _chargingOnlyKey = 'backup_charging_only';
  static const _retentionKey = 'backup_retention_count';

  final DatabaseHelper _databaseHelper;
  final BackupDriveService _driveService;
  final BackupPackageService _packageService;
  final DeviceInfoService _deviceInfoService;
  final NetworkInfoService _networkInfoService;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  BackupAccountInfo? get currentAccount => _driveService.currentAccount;

  Future<void> initialize() async {
    await _driveService.restorePreviousSignIn();
  }

  Future<BackupAccountInfo?> connectGoogleDrive() {
    return _driveService.signIn();
  }

  Future<BackupAccountInfo?> changeAccount() {
    return _driveService.changeAccount();
  }

  Future<void> disconnectGoogleDrive() {
    return _driveService.signOut();
  }

  Future<BackupSettings> getSettings() async {
    final enabled = await _secureStorage.read(key: _autoEnabledKey);
    final frequency = await _secureStorage.read(key: _frequencyKey);
    final wifiOnly = await _secureStorage.read(key: _wifiOnlyKey);
    final chargingOnly = await _secureStorage.read(key: _chargingOnlyKey);
    final retention = await _secureStorage.read(key: _retentionKey);
    return BackupSettings(
      automaticBackupEnabled: enabled == 'true',
      frequency: frequency == 'weekly' ? 'weekly' : 'daily',
      onlyOnWifi: wifiOnly == null ? true : wifiOnly == 'true',
      onlyWhileCharging: chargingOnly == 'true',
      retentionCount:
          int.tryParse(retention ?? '') ??
          BackupSettings.defaults.retentionCount,
    );
  }

  Future<void> saveSettings(BackupSettings settings) async {
    await _secureStorage.write(
      key: _autoEnabledKey,
      value: settings.automaticBackupEnabled.toString(),
    );
    await _secureStorage.write(key: _frequencyKey, value: settings.frequency);
    await _secureStorage.write(
      key: _wifiOnlyKey,
      value: settings.onlyOnWifi.toString(),
    );
    await _secureStorage.write(
      key: _chargingOnlyKey,
      value: settings.onlyWhileCharging.toString(),
    );
    await _secureStorage.write(
      key: _retentionKey,
      value: settings.retentionCount.toString(),
    );
  }

  Future<DateTime?> getLastBackupDate() async {
    final value = await _secureStorage.read(key: _lastBackupDateKey);
    return value == null ? null : DateTime.tryParse(value);
  }

  Future<int?> getLastBackupSize() async {
    final value = await _secureStorage.read(key: _lastBackupSizeKey);
    return value == null ? null : int.tryParse(value);
  }

  Future<List<BackupDriveFile>> getAvailableBackups() async {
    return _driveService.listBackups();
  }

  Future<BackupOperationResult> createAndUploadBackup({String? note}) async {
    try {
      await initialize();
      if (!await _networkInfoService.hasInternetConnection()) {
        return const BackupOperationResult(
          success: false,
          message: 'No internet connection. Please check your network.',
        );
      }

      if (currentAccount == null) {
        final account = await connectGoogleDrive();
        if (account == null) {
          return const BackupOperationResult(
            success: false,
            message: 'Google Drive connection was cancelled.',
          );
        }
      }

      final settings = await getSettings();
      final packageResult = await _createLocalBackupPackage(note: note);
      await _driveService.uploadBackup(
        file: packageResult.file,
        metadata: packageResult.metadata,
        keepLatest: settings.retentionCount,
      );

      await _secureStorage.write(
        key: _lastBackupDateKey,
        value: packageResult.metadata.backupTimestamp.toIso8601String(),
      );
      await _secureStorage.write(
        key: _lastBackupSizeKey,
        value: packageResult.metadata.backupSize.toString(),
      );

      return BackupOperationResult(
        success: true,
        message: 'Backup completed successfully.',
        metadata: packageResult.metadata,
      );
    } catch (e, stackTrace) {
      ErrorUtils.logError(
        'Backup failed',
        error: e,
        stackTrace: stackTrace,
        tag: 'Backup',
      );
      return BackupOperationResult(
        success: false,
        message: _friendlyBackupError(e),
      );
    }
  }

  Future<File> downloadBackup(String driveFileId) async {
    final tempDir = await getTemporaryDirectory();
    final restoreDir = Directory(path.join(tempDir.path, 'carevault_restore'));
    return _driveService.downloadBackup(
      fileId: driveFileId,
      outputDirectory: restoreDir,
      fileName: '$driveFileId.cvbackup',
    );
  }

  Future<BackupPackageResult> _createLocalBackupPackage({String? note}) async {
    final backupId = const Uuid().v4();
    final tempDir = await getTemporaryDirectory();
    final outputDir = Directory(path.join(tempDir.path, 'carevault_backups'));
    final dbPath = path.join(
      await getDatabasesPath(),
      DatabaseConstants.databaseName,
    );
    final dbFile = File(dbPath);

    await _databaseHelper.close();
    if (!await dbFile.exists()) {
      await _databaseHelper.database;
      await _databaseHelper.close();
    }

    final metadata = await _createMetadata(backupId: backupId, note: note);
    final packageResult = await _packageService.createEncryptedPackage(
      outputDirectory: outputDir,
      databaseFile: dbFile,
      attachmentDirectories: await _attachmentDirectories(),
      metadata: metadata,
      settings: (await getSettings()).toJson(),
    );

    await _databaseHelper.database;
    return packageResult;
  }

  Future<BackupMetadata> _createMetadata({
    required String backupId,
    String? note,
  }) async {
    final deviceInfo = await _deviceInfoService.getAllDeviceInfo();
    final deviceName = await _deviceInfoService.getDeviceName();
    return BackupMetadata(
      id: backupId,
      appVersion: AppConstants.appVersion,
      backupTimestamp: DateTime.now().toUtc(),
      deviceInfo: deviceInfo.toString(),
      schemaVersion: DatabaseConstants.databaseVersion,
      fileCount: 0,
      encryptionVersion: 1,
      backupSize: 0,
      deviceName: deviceName,
      notes: note,
    );
  }

  Future<List<Directory>> _attachmentDirectories() async {
    final appDir = await getApplicationDocumentsDirectory();
    return [
      Directory(path.join(appDir.path, AppConstants.prescriptionsDirectory)),
      Directory(path.join(appDir.path, AppConstants.reportsDirectory)),
      Directory(path.join(appDir.path, AppConstants.imagesDirectory)),
    ];
  }

  String _friendlyBackupError(Object error) {
    final message = error.toString().toLowerCase();
    if (message.contains('quota')) {
      return 'Google Drive storage quota was exceeded.';
    }
    if (message.contains('sign') || message.contains('auth')) {
      return 'Google Drive authorization expired. Please reconnect your account.';
    }
    if (message.contains('socket') || message.contains('network')) {
      return 'Network connection failed during backup.';
    }
    return 'Backup failed. Please try again.';
  }
}
