import 'package:sqflite/sqflite.dart';

import 'database_constants.dart';

class MigrationManager {
  // Migration scripts for each version
  static final Map<int, List<String>> _migrations = {
    1: _getVersion1Migrations(),
    2: _getVersion2Migrations(),
    3: _getVersion3Migrations(),
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

  // Get migration scripts for version 2 (example future version)
  static List<String> _getVersion2Migrations() {
    return [
      // Example: Add new column to medicines table
      '''
      ALTER TABLE ${DatabaseConstants.tableMedicines} 
      ADD COLUMN new_column TEXT
      ''',
      
      // Example: Create new table
      '''
      CREATE TABLE IF NOT EXISTS new_table (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
      ''',
    ];
  }

  // Get migration scripts for version 3 (example future version)
  static List<String> _getVersion3Migrations() {
    return [
      // Example: Add index to new column
      '''
      CREATE INDEX IF NOT EXISTS idx_new_column 
      ON ${DatabaseConstants.tableMedicines}(new_column)
      ''',
      
      // Example: Drop old table if exists
      '''
      DROP TABLE IF EXISTS old_table
      ''',
    ];
  }

  // Apply migrations from oldVersion to newVersion
  static Future<void> migrate(Database db, int oldVersion, int newVersion) async {
    for (int version = oldVersion + 1; version <= newVersion; version++) {
      if (_migrations.containsKey(version)) {
        final migrations = _migrations[version]!;
        await _applyMigrations(db, migrations, version);
      }
    }
  }

  // Apply specific migration scripts
  static Future<void> _applyMigrations(Database db, List<String> migrations, int version) async {
    await db.transaction((txn) async {
      for (final migration in migrations) {
        try {
          await txn.execute(migration);
        } catch (e) {
          // Log migration error but continue
          print('Migration $version failed: $e\nSQL: $migration');
          // In production, you might want to handle this more gracefully
          // For now, we'll rethrow to fail the migration
          rethrow;
        }
      }
    });
  }

  // Get current database schema version
  static Future<int?> getCurrentSchemaVersion(Database db) async {
    try {
      // Check if schema_version table exists
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='schema_version'"
      );
      
      if (tables.isEmpty) {
        // Table doesn't exist, assume version 1 (initial version)
        return 1;
      }
      
      // Get version from schema_version table
      final version = await db.rawQuery('SELECT version FROM schema_version LIMIT 1');
      
      if (version.isNotEmpty) {
        return version.first['version'] as int?;
      }
      
      return 1;
    } catch (e) {
      // If any error occurs, assume version 1
      return 1;
    }
  }

  // Set current database schema version
  static Future<void> setCurrentSchemaVersion(Database db, int version) async {
    try {
      // Create schema_version table if it doesn't exist
      await db.execute('''
        CREATE TABLE IF NOT EXISTS schema_version (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          version INTEGER NOT NULL,
          migrated_at TEXT NOT NULL
        )
      ''');
      
      // Clear existing version record
      await db.delete('schema_version');
      
      // Insert new version record
      await db.insert(
        'schema_version',
        {
          'version': version,
          'migrated_at': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      print('Failed to set schema version: $e');
    }
  }

  // Check if migration is needed
  static Future<bool> needsMigration(Database db, int targetVersion) async {
    final currentVersion = await getCurrentSchemaVersion(db);
    return currentVersion != targetVersion;
  }

  // Backup database before migration (simplified)
  static Future<String?> backupDatabase(Database db) async {
    try {
      // Get database path
      final path = await db.getPath();
      final backupPath = '$path.backup_${DateTime.now().millisecondsSinceEpoch}';
      
      // In a real app, you would copy the database file here
      // For now, we'll just return the backup path
      return backupPath;
    } catch (e) {
      print('Failed to backup database: $e');
      return null;
    }
  }

  // Validate database schema
  static Future<bool> validateSchema(Database db, int expectedVersion) async {
    try {
      // Check if all required tables exist
      final requiredTables = [
        DatabaseConstants.tableMedicines,
        DatabaseConstants.tablePrescriptions,
        DatabaseConstants.tableReminderLogs,
        DatabaseConstants.tableFollowUps,
      ];
      
      for (final table in requiredTables) {
        final result = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='$table'"
        );
        
        if (result.isEmpty) {
          print('Missing table: $table');
          return false;
        }
      }
      
      // Check schema version
      final currentVersion = await getCurrentSchemaVersion(db);
      if (currentVersion != expectedVersion) {
        print('Schema version mismatch: expected $expectedVersion, got $currentVersion');
        return false;
      }
      
      return true;
    } catch (e) {
      print('Schema validation failed: $e');
      return false;
    }
  }

  // Get migration history
  static Future<List<Map<String, dynamic>>> getMigrationHistory(Database db) async {
    try {
      // Check if migration_history table exists
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='migration_history'"
      );
      
      if (tables.isEmpty) {
        return [];
      }
      
      return await db.query(
        'migration_history',
        orderBy: 'applied_at DESC',
      );
    } catch (e) {
      return [];
    }
  }

  // Record migration in history
  static Future<void> recordMigration(
    Database db, 
    int fromVersion, 
    int toVersion, 
    bool success,
    String? error,
  ) async {
    try {
      // Create migration_history table if it doesn't exist
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
      
      // Insert migration record
      await db.insert(
        'migration_history',
        {
          'from_version': fromVersion,
          'to_version': toVersion,
          'success': success ? 1 : 0,
          'error': error,
          'applied_at': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      print('Failed to record migration: $e');
    }
  }

  // Rollback migration (simplified - in production you'd need more sophisticated rollback)
  static Future<bool> rollbackMigration(Database db, int targetVersion) async {
    try {
      // This is a simplified rollback - in production, you would need
      // to implement proper rollback scripts for each version
      print('Rollback to version $targetVersion requested');
      print('Note: Full rollback not implemented in this simplified version');
      
      // For now, we'll just update the schema version
      await setCurrentSchemaVersion(db, targetVersion);
      return true;
    } catch (e) {
      print('Rollback failed: $e');
      return false;
    }
  }

  // Check database integrity
  static Future<bool> checkDatabaseIntegrity(Database db) async {
    try {
      final result = await db.rawQuery('PRAGMA integrity_check');
      
      if (result.isNotEmpty) {
        final integrityCheck = result.first['integrity_check'] as String?;
        return integrityCheck == 'ok';
      }
      
      return false;
    } catch (e) {
      print('Database integrity check failed: $e');
      return false;
    }
  }

  // Optimize database
  static Future<void> optimizeDatabase(Database db) async {
    try {
      await db.execute('VACUUM');
      await db.execute('ANALYZE');
    } catch (e) {
      print('Database optimization failed: $e');
    }
  }
}