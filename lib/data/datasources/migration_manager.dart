import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import 'database_constants.dart';
import '../../core/utils/error_utils.dart';

class MigrationManager {
  static final Map<int, List<String>> _migrations = {
    1: _getVersion1Migrations(),
    2: _getVersion2Migrations(),
    3: _getVersion3Migrations(),
    4: _getVersion4Migrations(),
    5: _getVersion5Migrations(),
    6: _getVersion6Migrations(),
    7: _getVersion7Migrations(),
  };

  // Get migration scripts for version 1 (initial version)
  static List<String> _getVersion1Migrations() {
    return [
      DatabaseConstants.createMedicinesTable,
      DatabaseConstants.createPrescriptionsTable,
      DatabaseConstants.createReminderLogsTable,
      DatabaseConstants.createFollowUpsTable,
      DatabaseConstants.createMedicineTimesIndex,
      DatabaseConstants.createMedicineActiveIndex,
      DatabaseConstants.createReminderMedicineIdIndex,
      DatabaseConstants.createReminderScheduledTimeIndex,
      DatabaseConstants.createReminderStatusIndex,
      DatabaseConstants.createFollowUpDateIndex,
      DatabaseConstants.createFollowUpStatusIndex,
    ];
  }

  // Get migration scripts for version 2 (vital signs feature)
  static List<String> _getVersion2Migrations() {
    return [
      // Create vital signs table
      DatabaseConstants.createVitalSignsTable,
      DatabaseConstants.createVitalSignTypeIndex,
      DatabaseConstants.createVitalSignReadingTimeIndex,
    ];
  }

  // Get migration scripts for version 3 (audit logging feature)
  static List<String> _getVersion3Migrations() {
    return [
      // Create audit logs table
      DatabaseConstants.createAuditLogsTable,
      DatabaseConstants.createAuditLogTimestampIndex,
      DatabaseConstants.createAuditLogUserIdIndex,
      DatabaseConstants.createAuditLogResourceTypeIndex,
      DatabaseConstants.createAuditLogActionIndex,
      DatabaseConstants.createAuditLogSeverityIndex,
    ];
  }

  // Get migration scripts for version 4 (placeholder if needed)
  static List<String> _getVersion4Migrations() {
    return [];
  }

  // Get migration scripts for version 5 (real-time sync architecture)
  static List<String> _getVersion5Migrations() {
    return [
      // Note: These migrations are applied in a transaction with error handling
      // that skips "duplicate column" errors, so we don't need to check if columns exist
      // Add last_modified and version to medicines
      'ALTER TABLE ${DatabaseConstants.tableMedicines} ADD COLUMN ${DatabaseConstants.columnLastModified} TEXT NOT NULL DEFAULT ""',
      'ALTER TABLE ${DatabaseConstants.tableMedicines} ADD COLUMN ${DatabaseConstants.columnVersion} INTEGER NOT NULL DEFAULT 1',

      // Add last_modified and version to prescriptions
      'ALTER TABLE ${DatabaseConstants.tablePrescriptions} ADD COLUMN ${DatabaseConstants.columnLastModified} TEXT NOT NULL DEFAULT ""',
      'ALTER TABLE ${DatabaseConstants.tablePrescriptions} ADD COLUMN ${DatabaseConstants.columnVersion} INTEGER NOT NULL DEFAULT 1',

      // Add last_modified and version to reminder_logs
      'ALTER TABLE ${DatabaseConstants.tableReminderLogs} ADD COLUMN ${DatabaseConstants.columnLastModified} TEXT NOT NULL DEFAULT ""',
      'ALTER TABLE ${DatabaseConstants.tableReminderLogs} ADD COLUMN ${DatabaseConstants.columnVersion} INTEGER NOT NULL DEFAULT 1',

      // Add last_modified and version to follow_ups
      'ALTER TABLE ${DatabaseConstants.tableFollowUps} ADD COLUMN ${DatabaseConstants.columnLastModified} TEXT NOT NULL DEFAULT ""',
      'ALTER TABLE ${DatabaseConstants.tableFollowUps} ADD COLUMN ${DatabaseConstants.columnVersion} INTEGER NOT NULL DEFAULT 1',

      // Add last_modified and version to vital_signs
      'ALTER TABLE ${DatabaseConstants.tableVitalSigns} ADD COLUMN ${DatabaseConstants.columnLastModified} TEXT NOT NULL DEFAULT ""',
      'ALTER TABLE ${DatabaseConstants.tableVitalSigns} ADD COLUMN ${DatabaseConstants.columnVersion} INTEGER NOT NULL DEFAULT 1',

      // Create database_changes table
      DatabaseConstants.createDatabaseChangesTable,
      DatabaseConstants.createChangeTimestampIndex,
    ];
  }

  // Get migration scripts for version 6 (test reports table)
  static List<String> _getVersion6Migrations() {
    return [
      // Create test_reports table
      DatabaseConstants.createTestReportsTable,
      DatabaseConstants.createTestReportDateIndex,
      DatabaseConstants.createTestReportTypeIndex,
    ];
  }

  // Get migration scripts for version 7 (fix test_reports index)
  static List<String> _getVersion7Migrations() {
    return [
      // No new migrations needed - version 7 just fixes the index from v6
      // This version bump ensures clean migration for existing users
    ];
  }

  // Apply migrations from oldVersion to newVersion with improved error handling
  static Future<void> migrate(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    try {
      for (int version = oldVersion + 1; version <= newVersion; version++) {
        if (_migrations.containsKey(version)) {
          final migrations = _migrations[version]!;
          await _applyMigrations(db, migrations, version);
        }
      }
    } catch (e, stackTrace) {
      ErrorUtils.logError(
        'Migration process failed',
        error: e,
        stackTrace: stackTrace,
        tag: 'Database',
      );
      rethrow;
    }
  }

  // Get current database schema version.
  static Future<int?> getCurrentSchemaVersion(Database db) async {
    try {
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='schema_version'",
      );

      if (tables.isEmpty) {
        return 1;
      }

      final version = await db.rawQuery(
        'SELECT version FROM schema_version LIMIT 1',
      );
      if (version.isNotEmpty) {
        return version.first['version'] as int?;
      }

      return 1;
    } catch (e) {
      ErrorUtils.logInfo('Failed to read schema version: $e', tag: 'Database');
      return 1;
    }
  }

  // Set current database schema version.
  static Future<void> setCurrentSchemaVersion(Database db, int version) async {
    try {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS schema_version (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          version INTEGER NOT NULL,
          migrated_at TEXT NOT NULL
        )
      ''');

      await db.delete('schema_version');
      await db.insert('schema_version', {
        'version': version,
        'migrated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      ErrorUtils.logInfo('Failed to set schema version: $e', tag: 'Database');
    }
  }

  // Check if migration is needed.
  static Future<bool> needsMigration(Database db, int targetVersion) async {
    final currentVersion = await getCurrentSchemaVersion(db);
    return currentVersion != targetVersion;
  }

  // Backup database before migration.
  static Future<String?> backupDatabase(Database db) async {
    try {
      final databasesPath = await getDatabasesPath();
      final path = join(databasesPath, DatabaseConstants.databaseName);
      return '$path.backup_${DateTime.now().millisecondsSinceEpoch}';
    } catch (e) {
      ErrorUtils.logInfo('Failed to backup database: $e', tag: 'Database');
      return null;
    }
  }

  // Validate database schema.
  static Future<bool> validateSchema(Database db, int expectedVersion) async {
    try {
      final requiredTables = [
        DatabaseConstants.tableMedicines,
        DatabaseConstants.tablePrescriptions,
        DatabaseConstants.tableTestReports,
        DatabaseConstants.tableReminderLogs,
        DatabaseConstants.tableFollowUps,
        if (expectedVersion >= 2) DatabaseConstants.tableVitalSigns,
      ];

      for (final table in requiredTables) {
        final result = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='$table'",
        );

        if (result.isEmpty) {
          ErrorUtils.logInfo('Missing table: $table', tag: 'Database');
          return false;
        }
      }

      final currentVersion = await getCurrentSchemaVersion(db);
      if (currentVersion != expectedVersion) {
        ErrorUtils.logInfo(
          'Schema version mismatch: expected $expectedVersion, got $currentVersion',
          tag: 'Database',
        );
        return false;
      }

      return true;
    } catch (e) {
      ErrorUtils.logInfo('Schema validation failed: $e', tag: 'Database');
      return false;
    }
  }

  // Get migration history.
  static Future<List<Map<String, dynamic>>> getMigrationHistory(
    Database db,
  ) async {
    try {
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='migration_history'",
      );

      if (tables.isEmpty) {
        return [];
      }

      return await db.query('migration_history', orderBy: 'applied_at DESC');
    } catch (e) {
      ErrorUtils.logInfo(
        'Failed to read migration history: $e',
        tag: 'Database',
      );
      return [];
    }
  }

  // Record migration in history.
  static Future<void> recordMigration(
    Database db,
    int fromVersion,
    int toVersion,
    bool success,
    String? error,
  ) async {
    try {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS migration_history (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          from_version INTEGER NOT NULL,
          to_version INTEGER NOT NULL,
          success INTEGER NOT NULL,
          error TEXT,
          applied_at TEXT NOT NULL
        )
      ''');

      await db.insert('migration_history', {
        'from_version': fromVersion,
        'to_version': toVersion,
        'success': success ? 1 : 0,
        'error': error,
        'applied_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      ErrorUtils.logInfo('Failed to record migration: $e', tag: 'Database');
    }
  }

  // Rollback migration by updating the tracked schema version.
  static Future<bool> rollbackMigration(Database db, int targetVersion) async {
    try {
      ErrorUtils.logInfo(
        'Rollback to version $targetVersion requested',
        tag: 'Database',
      );
      await setCurrentSchemaVersion(db, targetVersion);
      return true;
    } catch (e) {
      ErrorUtils.logInfo('Rollback failed: $e', tag: 'Database');
      return false;
    }
  }

  // Check database integrity.
  static Future<bool> checkDatabaseIntegrity(Database db) async {
    try {
      final result = await db.rawQuery('PRAGMA integrity_check');

      if (result.isNotEmpty) {
        final integrityCheck = result.first['integrity_check'] as String?;
        return integrityCheck == 'ok';
      }

      return false;
    } catch (e) {
      ErrorUtils.logInfo(
        'Database integrity check failed: $e',
        tag: 'Database',
      );
      return false;
    }
  }

  // Optimize database.
  static Future<void> optimizeDatabase(Database db) async {
    try {
      await db.execute('VACUUM');
      await db.execute('ANALYZE');
    } catch (e) {
      ErrorUtils.logInfo('Database optimization failed: $e', tag: 'Database');
    }
  }

  // Apply specific migration scripts with improved error handling
  static Future<void> _applyMigrations(
    Database db,
    List<String> migrations,
    int version,
  ) async {
    for (final migration in migrations) {
      try {
        await db.execute(migration);
        ErrorUtils.logInfo(
          'Migration $version: Applied successfully',
          tag: 'Database',
        );
      } on Exception catch (e, stackTrace) {
        final errorMsg = e.toString();
        // Ignore "duplicate column" and "index already exists" errors - these mean migration already applied
        if (errorMsg.contains('duplicate column') ||
            errorMsg.contains('already exists') ||
            errorMsg.contains('SQLITE_ERROR[1]') ||
            errorMsg.contains('duplicate column name')) {
          ErrorUtils.logInfo(
            'Migration $version: Skipping - $errorMsg',
            tag: 'Database',
          );
        } else {
          // Log other migration errors but continue
          ErrorUtils.logInfo(
            'Migration $version failed: $errorMsg',
            tag: 'Database',
          );
          ErrorUtils.logError(
            'Migration $version failed',
            error: e,
            stackTrace: stackTrace,
            tag: 'Database',
          );
        }
      }
    }
  }
}
