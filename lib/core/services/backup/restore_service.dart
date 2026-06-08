import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../../../data/datasources/database_constants.dart';
import '../../../data/datasources/database_helper.dart';
import '../../constants/app_constants.dart';
import '../../utils/error_utils.dart';
import 'backup_package_service.dart';
import 'backup_service.dart';

enum RestoreMode { merge, replace }

class RestoreResult {
  final bool success;
  final String message;

  const RestoreResult({required this.success, required this.message});
}

class _RestoreFiles {
  final Directory workspace;
  final Directory stagingRoot;
  final Set<String> managedDirectories;

  const _RestoreFiles({
    required this.workspace,
    required this.stagingRoot,
    required this.managedDirectories,
  });
}

class RestoreService {
  static final RestoreService _instance = RestoreService._internal();
  static RestoreService get instance => _instance;
  RestoreService._internal()
    : _backupService = BackupService(),
      _packageService = BackupPackageService(),
      _databaseHelper = DatabaseHelper();

  final BackupService _backupService;
  final BackupPackageService _packageService;
  final DatabaseHelper _databaseHelper;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  Future<RestoreResult> restoreFromDriveBackup(
    String driveFileId, {
    required String passphrase,
    RestoreMode mode = RestoreMode.replace,
  }) async {
    ErrorUtils.logInfo('RESTORE: Started restore from Drive backup ID: $driveFileId, mode: ${mode.name}', tag: 'Restore');
    Directory? rollbackDir;
    bool restoreSuccessful = false;
    String? originalProfile;
    try {
      ErrorUtils.logInfo('RESTORE: Downloading backup file', tag: 'Restore');
      final downloadedFile = await _backupService.downloadBackup(driveFileId);
      
      ErrorUtils.logInfo('RESTORE: Decrypting package', tag: 'Restore');
      final archive = await _packageService.decryptPackage(
        downloadedFile,
        passphrase: passphrase,
      );
      
      ErrorUtils.logInfo('RESTORE: Validating schema version', tag: 'Restore');
      final metadata = _packageService.readMetadata(archive);
      _validateSchema(metadata.schemaVersion);

      ErrorUtils.logInfo('RESTORE: Storing profile data and creating rollback snapshot', tag: 'Restore');
      originalProfile = await _secureStorage.read(key: 'user_profile_data');
      rollbackDir = await _createRollbackSnapshot();
      
      ErrorUtils.logInfo('RESTORE: Restoring archive contents', tag: 'Restore');
      await _restoreArchive(archive, mode: mode);

      restoreSuccessful = true;
      ErrorUtils.logInfo('RESTORE: Completed restore successfully', tag: 'Restore');
      return const RestoreResult(
        success: true,
        message: 'Restore completed successfully.',
      );
    } catch (e, stackTrace) {
      ErrorUtils.logError(
        'Restore failed',
        error: e,
        stackTrace: stackTrace,
        tag: 'Restore',
      );
      if (rollbackDir != null) {
        try {
          ErrorUtils.logInfo('RESTORE: Initiating rollback', tag: 'Restore');
          await _rollback(rollbackDir);
          if (originalProfile != null) {
            await _secureStorage.write(
              key: 'user_profile_data',
              value: originalProfile,
            );
          } else {
            await _secureStorage.delete(key: 'user_profile_data');
          }
          ErrorUtils.logInfo('RESTORE: Rollback completed successfully', tag: 'Restore');
        } catch (rollbackError, rollbackStackTrace) {
          ErrorUtils.logError(
            'Rollback failed after restore error',
            error: rollbackError,
            stackTrace: rollbackStackTrace,
            tag: 'Restore',
          );
        }
      }
      return RestoreResult(success: false, message: _friendlyRestoreError(e));
    } finally {
      // Only ensure database connection if restore was successful
      // If restore failed, rollback already handled database state
      if (restoreSuccessful) {
        try {
          await _databaseHelper.reopenDatabase();
        } catch (dbError, dbStackTrace) {
          ErrorUtils.logError(
            'Failed to verify and reopen database connection after restore',
            error: dbError,
            stackTrace: dbStackTrace,
            tag: 'Restore',
          );
        }
      }

      // Clean up rollback directory
      if (rollbackDir != null && await rollbackDir.exists()) {
        try {
          ErrorUtils.logInfo('RESTORE: Cleaning up rollback directory', tag: 'Restore');
          await rollbackDir.delete(recursive: true);
        } catch (cleanupError) {
          ErrorUtils.logWarning(
            'Failed to clean up rollback directory: $cleanupError',
            tag: 'Restore',
          );
        }
      }
    }
  }

  Future<void> _restoreArchive(
    Archive archive, {
    required RestoreMode mode,
  }) async {
    ErrorUtils.logInfo('RESTORE: Setting up staging directory', tag: 'Restore');
    final restoreFiles = await _restoreFiles(archive);
    debugPrint(
      'Restore diagnostics: staged files under ${restoreFiles.stagingRoot.path}',
    );
    try {
      ErrorUtils.logInfo('RESTORE: Extracting backup database', tag: 'Restore');
      final backupDb = await _extractDatabase(archive, restoreFiles.workspace);
      
      ErrorUtils.logInfo('RESTORE: Rewriting file references on backup database', tag: 'Restore');
      final pathMap = await _rewriteFileReferences(
        databasePath: backupDb.path,
        manifest: _packageService.readFileManifest(archive),
      );

      switch (mode) {
        case RestoreMode.replace:
          ErrorUtils.logInfo('RESTORE: Replacing current database with backup database', tag: 'Restore');
          await _replaceDatabase(backupDb.path);
          ErrorUtils.logInfo('RESTORE: Rewriting file references on replaced database', tag: 'Restore');
          await _rewriteFileReferences(
            databasePath: path.join(
              await getDatabasesPath(),
              DatabaseConstants.databaseName,
            ),
            manifest: pathMap,
            alreadyResolved: true,
          );
          break;
        case RestoreMode.merge:
          ErrorUtils.logInfo('RESTORE: Merging backup database into current database', tag: 'Restore');
          await _mergeDatabase(backupDb.path);
          ErrorUtils.logInfo('RESTORE: Rewriting file references on merged database', tag: 'Restore');
          await _rewriteFileReferences(
            databasePath: path.join(
              await getDatabasesPath(),
              DatabaseConstants.databaseName,
            ),
            manifest: pathMap,
            alreadyResolved: true,
          );
          break;
      }

      ErrorUtils.logInfo('RESTORE: Promoting staged files', tag: 'Restore');
      await _promoteStagedFiles(restoreFiles, mode: mode);
      
      ErrorUtils.logInfo('RESTORE: Restoring settings', tag: 'Restore');
      await _restoreSettings(archive);
      
      ErrorUtils.logInfo('RESTORE: Restoring profile data', tag: 'Restore');
      await _restoreProfile(archive);
    } finally {
      if (await restoreFiles.workspace.exists()) {
        try {
          ErrorUtils.logInfo('RESTORE: Cleaning up staging workspace', tag: 'Restore');
          await restoreFiles.workspace.delete(recursive: true);
        } catch (cleanupError) {
          ErrorUtils.logWarning(
            'Failed to clean up staging workspace: $cleanupError',
            tag: 'Restore',
          );
        }
      }
    }
  }

  Future<File> _extractDatabase(Archive archive, Directory restoreRoot) async {
    final dbArchiveFile = archive.findFile('database.db');
    if (dbArchiveFile == null) {
      throw const FormatException('Backup database is missing');
    }
    final dbFile = File(path.join(restoreRoot.path, 'database.db'));
    await dbFile.writeAsBytes(_contentBytes(dbArchiveFile), flush: true);
    return dbFile;
  }

  @visibleForTesting
  Future<Directory> stageArchiveFilesForTesting(Archive archive) async {
    final restoreFiles = await _restoreFiles(archive);
    return restoreFiles.workspace;
  }

  Future<_RestoreFiles> _restoreFiles(Archive archive) async {
    final tempDir = await getTemporaryDirectory();
    final workspace = Directory(
      path.join(
        tempDir.path,
        'carevault_restore_${DateTime.now().microsecondsSinceEpoch}',
      ),
    );
    final stagingRoot = Directory(path.join(workspace.path, 'staged_files'));
    await stagingRoot.create(recursive: true);

    final managedDirectories = <String>{};
    for (final file in archive.files) {
      if (!file.isFile || !file.name.startsWith('files/')) continue;
      final relative = file.name.substring('files/'.length);
      final destinationPath = path.normalize(
        path.join(stagingRoot.path, relative),
      );
      if (!path.isWithin(stagingRoot.path, destinationPath) &&
          destinationPath != stagingRoot.path) {
        throw const FormatException('Backup contains an unsafe file path');
      }

      final destination = File(destinationPath);
      await destination.parent.create(recursive: true);
      await destination.writeAsBytes(_contentBytes(file), flush: true);

      final topLevelDir = path.split(relative).firstWhere(
        (segment) => segment.isNotEmpty,
        orElse: () => '',
      );
      if (topLevelDir.isNotEmpty) {
        managedDirectories.add(topLevelDir);
      }
    }

    return _RestoreFiles(
      workspace: workspace,
      stagingRoot: stagingRoot,
      managedDirectories: managedDirectories,
    );
  }

  Future<void> _promoteStagedFiles(
    _RestoreFiles restoreFiles, {
    required RestoreMode mode,
  }) async {
    final appDir = await getApplicationDocumentsDirectory();
    ErrorUtils.logInfo('RESTORE: Promoting staged files, mode: ${mode.name}', tag: 'Restore');

    if (mode == RestoreMode.replace) {
      for (final dirName in restoreFiles.managedDirectories) {
        final targetDir = Directory(path.join(appDir.path, dirName));
        if (await targetDir.exists()) {
          await _safeCleanDirectory(targetDir);
        }
      }
    }

    for (final dirName in restoreFiles.managedDirectories) {
      final sourceDir = Directory(path.join(restoreFiles.stagingRoot.path, dirName));
      if (!await sourceDir.exists()) continue;

      final targetDirPath = path.normalize(path.join(appDir.path, dirName));
      if (!path.isWithin(appDir.path, targetDirPath) && targetDirPath != appDir.path) {
        throw const FormatException('Backup contains an unsafe file path');
      }
      final targetDir = Directory(targetDirPath);

      if (mode == RestoreMode.replace) {
        await _copyDirectory(sourceDir, targetDir);
        continue;
      }

      await for (final entity in sourceDir.list(recursive: true, followLinks: false)) {
        final relative = path.relative(entity.path, from: sourceDir.path);
        final targetPath = path.normalize(path.join(targetDir.path, relative));
        if (!path.isWithin(targetDir.path, targetPath) &&
            targetPath != targetDir.path) {
          throw const FormatException('Backup contains an unsafe file path');
        }

        try {
          if (entity is Directory) {
            await Directory(targetPath).create(recursive: true);
          } else if (entity is File) {
            final targetFile = File(targetPath);
            if (await targetFile.exists()) continue;
            await targetFile.parent.create(recursive: true);
            await entity.copy(targetPath);
          }
        } catch (copyError) {
          ErrorUtils.logWarning(
            'RESTORE: PromoteStagedFiles (merge): Failed to copy ${entity.path} to $targetPath: $copyError',
            tag: 'Restore',
          );
        }
      }
    }
  }

  @visibleForTesting
  Future<List<Map<String, String>>> rewriteFileReferencesForTesting({
    required String databasePath,
    required List<Map<String, String>> manifest,
    bool alreadyResolved = false,
  }) {
    return _rewriteFileReferences(
      databasePath: databasePath,
      manifest: manifest,
      alreadyResolved: alreadyResolved,
    );
  }

  Future<bool> _tableExists(Database db, String tableName) async {
    try {
      final result = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
        [tableName],
      );
      return result.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _tableExistsInBackup(Database db, String tableName) async {
    try {
      final result = await db.rawQuery(
        "SELECT name FROM backup.sqlite_master WHERE type='table' AND name=?",
        [tableName],
      );
      return result.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<List<Map<String, String>>> _rewriteFileReferences({
    required String databasePath,
    required List<Map<String, String>> manifest,
    bool alreadyResolved = false,
  }) async {
    if (manifest.isEmpty) return manifest;
    final appDir = await getApplicationDocumentsDirectory();
    final resolved = manifest
        .map(
          (entry) => {
            'originalPath': entry['originalPath']!,
            'relativePath': entry['relativePath']!,
            'restoredPath': alreadyResolved
                ? entry['restoredPath'] ?? entry['originalPath']!
                : path.join(
                    appDir.path,
                    entry['relativePath']!.replaceFirst(
                      RegExp(r'^files[/\\]'),
                      '',
                    ),
                  ),
          },
        )
        .toList(growable: false);

    final db = await openDatabase(databasePath, singleInstance: false);
    try {
      final hasPrescriptions = await _tableExists(db, DatabaseConstants.tablePrescriptions);
      final hasTestReports = await _tableExists(db, DatabaseConstants.tableTestReports);

      for (final entry in resolved) {
        final originalPath = entry['originalPath']!;
        final restoredPath = entry['restoredPath']!;
        int prescriptionUpdates = 0;
        int reportUpdates = 0;

        if (hasPrescriptions) {
          try {
            prescriptionUpdates = await db.update(
              DatabaseConstants.tablePrescriptions,
              {DatabaseConstants.columnPrescriptionFilePath: restoredPath},
              where: '${DatabaseConstants.columnPrescriptionFilePath} = ?',
              whereArgs: [originalPath],
            );
          } catch (e) {
            ErrorUtils.logWarning(
              'Failed to update prescription path for $originalPath: $e',
              tag: 'Restore',
            );
          }
        }

        if (hasTestReports) {
          try {
            reportUpdates = await db.update(
              DatabaseConstants.tableTestReports,
              {DatabaseConstants.columnTestReportFilePath: restoredPath},
              where: '${DatabaseConstants.columnTestReportFilePath} = ?',
              whereArgs: [originalPath],
            );
          } catch (e) {
            ErrorUtils.logWarning(
              'Failed to update test report path for $originalPath: $e',
              tag: 'Restore',
            );
          }
        }

        if (prescriptionUpdates == 0 && reportUpdates == 0) {
          ErrorUtils.logWarning(
            'Restore path rewrite found no matching rows for $originalPath',
            tag: 'Restore',
          );
        } else {
          ErrorUtils.logInfo(
            'Restore path rewrite updated $prescriptionUpdates prescription rows and $reportUpdates report rows for $originalPath',
            tag: 'Restore',
          );
        }
      }
    } finally {
      await db.close();
    }
    return resolved;
  }


  Future<void> _replaceDatabase(String backupDatabasePath) async {
    final currentPath = path.join(
      await getDatabasesPath(),
      DatabaseConstants.databaseName,
    );
    await _safeReplaceFile(
      sourcePath: backupDatabasePath,
      destinationPath: currentPath,
    );

    await _databaseHelper.reopenDatabase();
  }

  @visibleForTesting
  Future<void> safeReplaceFileForTesting({
    required String sourcePath,
    required String destinationPath,
  }) {
    return _safeReplaceFile(
      sourcePath: sourcePath,
      destinationPath: destinationPath,
    );
  }

  @visibleForTesting
  Future<void> mergeDatabaseForTesting(String backupDatabasePath) {
    return _mergeDatabase(backupDatabasePath);
  }

  @visibleForTesting
  static Future<void> copyDirectoryForTesting(Directory source, Directory destination) {
    return _copyDirectory(source, destination);
  }

  @visibleForTesting
  static Future<void> safeCleanDirectoryForTesting(Directory directory) {
    return _safeCleanDirectory(directory);
  }

  Future<void> _safeReplaceFile({
    required String sourcePath,
    required String destinationPath,
  }) async {
    await _databaseHelper.close();

    final sourceFile = File(sourcePath);
    if (!await sourceFile.exists()) {
      throw StateError('Backup database file not found at: $sourcePath');
    }

    final destinationFile = File(destinationPath);
    final tempDestinationPath = '$destinationPath.tmp';
    final tempDestinationFile = File(tempDestinationPath);
    final backupDestinationPath = '$destinationPath.bak';
    final backupDestinationFile = File(backupDestinationPath);

    if (await tempDestinationFile.exists()) {
      await tempDestinationFile.delete();
    }
    if (await backupDestinationFile.exists()) {
      await backupDestinationFile.delete();
    }

    await sourceFile.copy(tempDestinationPath);
    if (await tempDestinationFile.length() != await sourceFile.length()) {
      throw StateError('Failed to stage replacement database file');
    }

    if (await destinationFile.exists()) {
      await destinationFile.rename(backupDestinationPath);
    }

    try {
      await tempDestinationFile.rename(destinationPath);
    } catch (error) {
      if (await backupDestinationFile.exists()) {
        await backupDestinationFile.rename(destinationPath);
      }
      rethrow;
    }

    if (await backupDestinationFile.exists()) {
      await backupDestinationFile.delete();
    }
  }

  @visibleForTesting
  Future<void> withForeignKeysGuardForTesting(
    Future<void> Function(Database db) action,
  ) async {
    final db = await _databaseHelper.database;
    await db.execute('PRAGMA foreign_keys = OFF');
    try {
      await action(db);
    } finally {
      await db.execute('PRAGMA foreign_keys = ON');
    }
  }

  Future<void> _mergeDatabase(String backupDatabasePath) async {
    ErrorUtils.logInfo('RESTORE: Merging databases from backup: $backupDatabasePath', tag: 'Restore');
    await withForeignKeysGuardForTesting((db) async {
      ErrorUtils.logInfo('RESTORE: Attaching backup database', tag: 'Restore');
      await db.execute('ATTACH DATABASE ? AS backup', [backupDatabasePath]);
      try {
        for (final table in _mergeTables) {
          try {
            final hasMainTable = await _tableExists(db, table);
            if (!hasMainTable) {
              ErrorUtils.logInfo('RESTORE: Table $table does not exist in main database, skipping.', tag: 'Restore');
              continue;
            }

            final hasBackupTable = await _tableExistsInBackup(db, table);
            if (!hasBackupTable) {
              ErrorUtils.logInfo('RESTORE: Table $table does not exist in backup database, skipping.', tag: 'Restore');
              continue;
            }

            ErrorUtils.logInfo('RESTORE: Merging table $table', tag: 'Restore');
            await db.transaction((txn) async {
              final currentColumns = await _columns(txn, table);
              final backupColumns = await _columns(txn, table, schema: 'backup');
              final columns = currentColumns
                  .where(backupColumns.contains)
                  .toList(growable: false);
              if (columns.isEmpty) {
                ErrorUtils.logInfo('RESTORE: No matching columns for table $table, skipping.', tag: 'Restore');
                return;
              }
              final columnSql = columns.map(_quoteIdentifier).join(', ');
              
              await txn.execute(
                'INSERT OR REPLACE INTO ${_quoteIdentifier(table)} ($columnSql) '
                'SELECT $columnSql FROM backup.${_quoteIdentifier(table)}',
              );
              ErrorUtils.logInfo('RESTORE: Successfully merged table $table', tag: 'Restore');
            });
          } catch (tableError, stackTrace) {
            ErrorUtils.logError(
              'RESTORE: Failed to merge table $table',
              error: tableError,
              stackTrace: stackTrace,
              tag: 'Restore',
            );
          }
        }
      } finally {
        ErrorUtils.logInfo('RESTORE: Detaching backup database', tag: 'Restore');
        try {
          await db.execute('DETACH DATABASE backup');
        } catch (detachError) {
          ErrorUtils.logWarning('RESTORE: Failed to detach backup database: $detachError', tag: 'Restore');
        }
      }
    });
  }

  Future<List<String>> _columns(
    Transaction txn,
    String table, {
    String? schema,
  }) async {
    final pragma = schema == null
        ? 'PRAGMA table_info(${_quoteIdentifier(table)})'
        : 'PRAGMA ${_quoteIdentifier(schema)}.table_info(${_quoteIdentifier(table)})';
    final rows = await txn.rawQuery(pragma);
    return rows.map((row) => row['name'] as String).toList(growable: false);
  }

  @visibleForTesting
  Map<String, String> decodeBackupSettingsForTesting(Archive archive) {
    final settingsFile = archive.findFile('settings.json');
    if (settingsFile == null) return const {};
    final decoded = jsonDecode(utf8.decode(_contentBytes(settingsFile)));
    if (decoded is! Map<String, dynamic>) return const {};
    return _normalizedBackupSettings(decoded);
  }

  Future<void> _restoreSettings(Archive archive) async {
    final normalized = decodeBackupSettingsForTesting(archive);
    if (normalized.isEmpty) return;

    for (final entry in normalized.entries) {
      await _secureStorage.write(key: entry.key, value: entry.value);
    }
  }

  @visibleForTesting
  Future<void> restoreProfileForTesting(Archive archive) {
    return _restoreProfile(archive);
  }

  Future<void> _restoreProfile(Archive archive) async {
    final profileFile = archive.findFile('profile.json');
    if (profileFile == null) return;

    final profileContent = utf8.decode(_contentBytes(profileFile));
    if (profileContent.trim().isNotEmpty) {
      await _secureStorage.write(
        key: 'user_profile_data',
        value: profileContent,
      );
    }
  }

  static Map<String, String> _normalizedBackupSettings(
    Map<String, dynamic> decoded,
  ) {
    final normalized = <String, String>{
      'backup_auto_enabled': (decoded['automaticBackupEnabled'] == true)
          .toString(),
      'backup_wifi_only': (decoded['onlyOnWifi'] != false).toString(),
      'backup_charging_only': (decoded['onlyWhileCharging'] == true).toString(),
    };

    final frequency = decoded['frequency'];
    if (frequency == 'daily' || frequency == 'weekly') {
      normalized['backup_frequency'] = frequency as String;
    }

    final retention = decoded['retentionCount'];
    final retentionValue = retention is int
        ? retention
        : int.tryParse(retention?.toString() ?? '');
    if (retentionValue != null && retentionValue > 0) {
      normalized['backup_retention_count'] = retentionValue.toString();
    }

    return normalized;
  }

  Future<Directory> _createRollbackSnapshot() async {
    await _databaseHelper.close();
    final tempDir = await getTemporaryDirectory();
    final rollbackDir = Directory(
      path.join(tempDir.path, 'carevault_restore_rollback'),
    );
    if (await rollbackDir.exists()) {
      await rollbackDir.delete(recursive: true);
    }
    await rollbackDir.create(recursive: true);

    final currentDbPath = path.join(
      await getDatabasesPath(),
      DatabaseConstants.databaseName,
    );
    final currentDbFile = File(currentDbPath);
    if (await currentDbFile.exists()) {
      await currentDbFile.copy(path.join(rollbackDir.path, 'database.db'));
    }

    final appDir = await getApplicationDocumentsDirectory();
    for (final dirName in [
      AppConstants.prescriptionsDirectory,
      AppConstants.reportsDirectory,
      AppConstants.imagesDirectory,
    ]) {
      final source = Directory(path.join(appDir.path, dirName));
      if (await source.exists()) {
        await _copyDirectory(
          source,
          Directory(path.join(rollbackDir.path, dirName)),
        );
      }
    }
    return rollbackDir;
  }

  Future<void> _rollback(Directory rollbackDir) async {
    // Close the current database connection
    await _databaseHelper.close();

    // Restore database from rollback snapshot
    final dbBackup = File(path.join(rollbackDir.path, 'database.db'));
    if (await dbBackup.exists()) {
      final currentDbPath = path.join(
        await getDatabasesPath(),
        DatabaseConstants.databaseName,
      );
      final currentFile = File(currentDbPath);
      if (await currentFile.exists()) {
        await currentFile.delete();
      }
      await dbBackup.copy(currentDbPath);
    }

    // Restore application files
    final appDir = await getApplicationDocumentsDirectory();
    for (final dirName in [
      AppConstants.prescriptionsDirectory,
      AppConstants.reportsDirectory,
      AppConstants.imagesDirectory,
    ]) {
      final source = Directory(path.join(rollbackDir.path, dirName));
      if (await source.exists()) {
        await _copyDirectory(
          source,
          Directory(path.join(appDir.path, dirName)),
        );
      }
    }

    // Re-initialize database connection after rollback without deleting it.
    await _databaseHelper.reopenDatabase();
  }

  void _validateSchema(int backupSchemaVersion) {
    if (backupSchemaVersion > DatabaseConstants.databaseVersion) {
      throw StateError(
        'Backup schema version $backupSchemaVersion is newer than app schema '
        '${DatabaseConstants.databaseVersion}',
      );
    }
  }

  String _friendlyRestoreError(Object error) {
    final message = error.toString().toLowerCase();
    if (message.contains('integrity') ||
        message.contains('checksum') ||
        message.contains('format') ||
        message.contains('passphrase')) {
      return 'This backup could not be decrypted. Check the backup passphrase and try again.';
    }
    if (message.contains('schema')) {
      return 'This backup was created by a newer app version. Please update CareVault first.';
    }
    if (message.contains('sign') || message.contains('auth')) {
      return 'Google Drive authorization expired. Please reconnect your account.';
    }
    if (message.contains('database_closed') ||
        message.contains('database closed')) {
      return 'Database connection error during restore. Please restart the app and try again.';
    }
    if (message.contains('file not found') ||
        message.contains('does not exist')) {
      return 'Backup file is missing or inaccessible.';
    }
    return 'Restore failed. Your previous local data was kept.';
  }

  static String _quoteIdentifier(String value) {
    return '"${value.replaceAll('"', '""')}"';
  }

  static Uint8List _contentBytes(ArchiveFile file) {
    final content = file.content;
    if (content is Uint8List) return content;
    if (content is List<int>) return Uint8List.fromList(content);
    throw FormatException('Unsupported archive content for ${file.name}');
  }

  static Future<void> _safeCleanDirectory(Directory directory) async {
    if (!await directory.exists()) return;
    try {
      ErrorUtils.logInfo('RESTORE: Safely cleaning directory: ${directory.path}', tag: 'Restore');
      await for (final entity in directory.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          try {
            await entity.delete();
          } catch (e) {
            ErrorUtils.logWarning(
              'RESTORE: SafeCleanDirectory: Failed to delete file ${entity.path}: $e',
              tag: 'Restore',
            );
          }
        }
      }
      // After deleting files, try to delete directories in a separate pass
      await for (final entity in directory.list(recursive: true, followLinks: false)) {
        if (entity is Directory) {
          try {
            await entity.delete(recursive: true);
          } catch (e) {
            ErrorUtils.logWarning(
              'RESTORE: SafeCleanDirectory: Failed to delete directory ${entity.path}: $e',
              tag: 'Restore',
            );
          }
        }
      }
    } catch (e) {
      ErrorUtils.logWarning(
        'RESTORE: SafeCleanDirectory: Error listing/cleaning directory ${directory.path}: $e',
        tag: 'Restore',
      );
    }
  }

  static Future<void> _copyDirectory(
    Directory source,
    Directory destination,
  ) async {
    ErrorUtils.logInfo('RESTORE: Copying directory from ${source.path} to ${destination.path}', tag: 'Restore');
    if (await destination.exists()) {
      await _safeCleanDirectory(destination);
    } else {
      await destination.create(recursive: true);
    }
    await for (final entity in source.list(
      recursive: true,
      followLinks: false,
    )) {
      final targetPath = path.join(
        destination.path,
        path.relative(entity.path, from: source.path),
      );
      try {
        if (entity is Directory) {
          await Directory(targetPath).create(recursive: true);
        } else if (entity is File) {
          await Directory(path.dirname(targetPath)).create(recursive: true);
          try {
            await entity.copy(targetPath);
          } catch (copyError) {
            ErrorUtils.logWarning(
              'RESTORE: CopyDirectory: Failed to copy file ${entity.path} to $targetPath: $copyError',
              tag: 'Restore',
            );
          }
        }
      } catch (err) {
        ErrorUtils.logWarning(
          'RESTORE: CopyDirectory: Failed to process entity ${entity.path} for target $targetPath: $err',
          tag: 'Restore',
        );
      }
    }
  }

  static const _mergeTables = [
    DatabaseConstants.tableMedicines,
    DatabaseConstants.tablePrescriptions,
    DatabaseConstants.tableTestReports,
    DatabaseConstants.tableReminderLogs,
    DatabaseConstants.tableFollowUps,
    DatabaseConstants.tableVitalSigns,
    DatabaseConstants.tableAuditLogs,
  ];
}
