import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
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
    RestoreMode mode = RestoreMode.replace,
  }) async {
    Directory? rollbackDir;
    try {
      final downloadedFile = await _backupService.downloadBackup(driveFileId);
      final archive = await _packageService.decryptPackage(downloadedFile);
      final metadata = _packageService.readMetadata(archive);
      _validateSchema(metadata.schemaVersion);

      rollbackDir = await _createRollbackSnapshot();
      await _restoreArchive(archive, mode: mode);

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
        await _rollback(rollbackDir);
      }
      return RestoreResult(success: false, message: _friendlyRestoreError(e));
    } finally {
      await _databaseHelper.database;
      if (rollbackDir != null && await rollbackDir.exists()) {
        await rollbackDir.delete(recursive: true);
      }
    }
  }

  Future<void> _restoreArchive(
    Archive archive, {
    required RestoreMode mode,
  }) async {
    final restoreRoot = await _restoreFiles(archive);
    final backupDb = await _extractDatabase(archive, restoreRoot);
    final pathMap = await _rewriteFileReferences(
      databasePath: backupDb.path,
      manifest: _packageService.readFileManifest(archive),
    );
    await _restoreSettings(archive);

    switch (mode) {
      case RestoreMode.replace:
        await _replaceDatabase(backupDb.path);
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
        await _mergeDatabase(backupDb.path);
        break;
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

  Future<Directory> _restoreFiles(Archive archive) async {
    final restoreRoot = Directory(
      path.join(
        (await getTemporaryDirectory()).path,
        'carevault_restore_extract',
      ),
    );
    if (await restoreRoot.exists()) {
      await restoreRoot.delete(recursive: true);
    }
    await restoreRoot.create(recursive: true);

    final appDir = await getApplicationDocumentsDirectory();
    for (final file in archive.files) {
      if (!file.isFile || !file.name.startsWith('files/')) continue;
      final relative = file.name.substring('files/'.length);
      final destination = File(
        path.normalize(path.join(appDir.path, relative)),
      );
      if (!path.isWithin(appDir.path, destination.path) &&
          destination.path != appDir.path) {
        throw const FormatException('Backup contains an unsafe file path');
      }
      if (!await destination.parent.exists()) {
        await destination.parent.create(recursive: true);
      }
      if (!await destination.exists()) {
        await destination.writeAsBytes(_contentBytes(file), flush: true);
      }
    }
    return restoreRoot;
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

    final db = await openDatabase(databasePath);
    try {
      for (final entry in resolved) {
        final originalPath = entry['originalPath']!;
        final restoredPath = entry['restoredPath']!;
        await db.update(
          DatabaseConstants.tablePrescriptions,
          {DatabaseConstants.columnPrescriptionFilePath: restoredPath},
          where: '${DatabaseConstants.columnPrescriptionFilePath} = ?',
          whereArgs: [originalPath],
        );
        await db.update(
          DatabaseConstants.tableTestReports,
          {DatabaseConstants.columnTestReportFilePath: restoredPath},
          where: '${DatabaseConstants.columnTestReportFilePath} = ?',
          whereArgs: [originalPath],
        );
      }
    } finally {
      await db.close();
    }
    return resolved;
  }

  Future<void> _replaceDatabase(String backupDatabasePath) async {
    await _databaseHelper.close();
    final currentPath = path.join(
      await getDatabasesPath(),
      DatabaseConstants.databaseName,
    );
    await File(backupDatabasePath).copy(currentPath);
    await _databaseHelper.database;
  }

  Future<void> _mergeDatabase(String backupDatabasePath) async {
    final db = await _databaseHelper.database;
    await db.execute('PRAGMA foreign_keys = OFF');
    await db.transaction((txn) async {
      await txn.execute('ATTACH DATABASE ? AS backup', [backupDatabasePath]);
      try {
        for (final table in _mergeTables) {
          final currentColumns = await _columns(txn, table);
          final backupColumns = await _columns(txn, table, schema: 'backup');
          final columns = currentColumns
              .where(backupColumns.contains)
              .toList(growable: false);
          if (columns.isEmpty) continue;
          final columnSql = columns.map(_quoteIdentifier).join(', ');
          await txn.execute(
            'INSERT OR REPLACE INTO ${_quoteIdentifier(table)} ($columnSql) '
            'SELECT $columnSql FROM backup.${_quoteIdentifier(table)}',
          );
        }
      } finally {
        await txn.execute('DETACH DATABASE backup');
      }
    });
    await db.execute('PRAGMA foreign_keys = ON');
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

  Future<void> _restoreSettings(Archive archive) async {
    final settingsFile = archive.findFile('settings.json');
    if (settingsFile == null) return;
    final decoded = jsonDecode(utf8.decode(_contentBytes(settingsFile)));
    if (decoded is! Map<String, dynamic>) return;

    await _secureStorage.write(
      key: 'backup_auto_enabled',
      value: (decoded['automaticBackupEnabled'] == true).toString(),
    );
    if (decoded['frequency'] == 'daily' || decoded['frequency'] == 'weekly') {
      await _secureStorage.write(
        key: 'backup_frequency',
        value: decoded['frequency'] as String,
      );
    }
    await _secureStorage.write(
      key: 'backup_wifi_only',
      value: (decoded['onlyOnWifi'] != false).toString(),
    );
    await _secureStorage.write(
      key: 'backup_charging_only',
      value: (decoded['onlyWhileCharging'] == true).toString(),
    );
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
    await _databaseHelper.close();
    final dbBackup = File(path.join(rollbackDir.path, 'database.db'));
    if (await dbBackup.exists()) {
      final currentDbPath = path.join(
        await getDatabasesPath(),
        DatabaseConstants.databaseName,
      );
      await dbBackup.copy(currentDbPath);
    }

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
        message.contains('format')) {
      return 'This backup is corrupted or was modified.';
    }
    if (message.contains('schema')) {
      return 'This backup was created by a newer app version. Please update CareVault first.';
    }
    if (message.contains('sign') || message.contains('auth')) {
      return 'Google Drive authorization expired. Please reconnect your account.';
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

  static Future<void> _copyDirectory(
    Directory source,
    Directory destination,
  ) async {
    if (await destination.exists()) {
      await destination.delete(recursive: true);
    }
    await destination.create(recursive: true);
    await for (final entity in source.list(
      recursive: true,
      followLinks: false,
    )) {
      final targetPath = path.join(
        destination.path,
        path.relative(entity.path, from: source.path),
      );
      if (entity is Directory) {
        await Directory(targetPath).create(recursive: true);
      } else if (entity is File) {
        await Directory(path.dirname(targetPath)).create(recursive: true);
        await entity.copy(targetPath);
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
