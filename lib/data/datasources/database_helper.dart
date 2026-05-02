import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import 'database_constants.dart';
import 'migration_manager.dart';
import '../../core/utils/error_utils.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  factory DatabaseHelper() {
    return _instance;
  }

  // Get database instance
  Future<Database> get database async {
    if (_database != null) return _database!;
    
    _database = await _initDatabase();
    return _database!;
  }

  // Initialize database
  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, DatabaseConstants.databaseName);
    
    return await openDatabase(
      path,
      version: DatabaseConstants.databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onDowngrade: _onDowngrade,
    );
  }

  // Create database tables
  Future<void> _onCreate(Database db, int version) async {
    // Apply initial migrations
    await MigrationManager.migrate(db, 0, version);
    await MigrationManager.setCurrentSchemaVersion(db, version);
  }

  // Handle database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    try {
      // Backup before migration
      final backupPath = await MigrationManager.backupDatabase(db);
      ErrorUtils.logInfo('Database backup created at: $backupPath', tag: 'Database');
      
      // Apply migrations
      await MigrationManager.migrate(db, oldVersion, newVersion);
      
      // Update schema version
      await MigrationManager.setCurrentSchemaVersion(db, newVersion);
      
      // Record successful migration
      await MigrationManager.recordMigration(db, oldVersion, newVersion, true, null);
      
      ErrorUtils.logInfo('Database migrated from version $oldVersion to $newVersion', tag: 'Database');
    } catch (e, stackTrace) {
      // Record failed migration
      await MigrationManager.recordMigration(db, oldVersion, newVersion, false, e.toString());
      
      ErrorUtils.logError(
        'Database migration failed from version $oldVersion to $newVersion',
        error: e,
        stackTrace: stackTrace,
        tag: 'Database',
      );
      rethrow;
    }
  }

  // Handle database downgrades (should rarely happen)
  Future<void> _onDowngrade(Database db, int oldVersion, int newVersion) async {
    try {
      ErrorUtils.logWarning('Database downgrade requested from $oldVersion to $newVersion', tag: 'Database');
      
      // Attempt rollback
      final success = await MigrationManager.rollbackMigration(db, newVersion);
      
      if (success) {
        await MigrationManager.recordMigration(db, oldVersion, newVersion, true, 'Downgrade successful');
        ErrorUtils.logInfo('Database downgraded from version $oldVersion to $newVersion', tag: 'Database');
      } else {
        await MigrationManager.recordMigration(db, oldVersion, newVersion, false, 'Downgrade failed');
        throw Exception('Database downgrade failed');
      }
    } catch (e, stackTrace) {
      await MigrationManager.recordMigration(db, oldVersion, newVersion, false, e.toString());
      ErrorUtils.logError(
        'Database downgrade failed from version $oldVersion to $newVersion',
        error: e,
        stackTrace: stackTrace,
        tag: 'Database',
      );
      rethrow;
    }
  }

  // Close database
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  // Clear all data (for testing/reset)
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete(DatabaseConstants.tableMedicines);
    await db.delete(DatabaseConstants.tablePrescriptions);
    await db.delete(DatabaseConstants.tableReminderLogs);
    await db.delete(DatabaseConstants.tableFollowUps);
  }

  // Drop and recreate database (for testing)
  Future<void> resetDatabase() async {
    await close();
    
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, DatabaseConstants.databaseName);
    
    // Delete existing database file
    await deleteDatabase(path);
    
    // Reinitialize database
    _database = await _initDatabase();
  }

  // Get database statistics
  Future<Map<String, int>> getDatabaseStats() async {
    final db = await database;
    
    final medicinesCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM ${DatabaseConstants.tableMedicines}')
    ) ?? 0;
    
    final prescriptionsCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM ${DatabaseConstants.tablePrescriptions}')
    ) ?? 0;
    
    final reminderLogsCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM ${DatabaseConstants.tableReminderLogs}')
    ) ?? 0;
    
    final followUpsCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM ${DatabaseConstants.tableFollowUps}')
    ) ?? 0;
    
    return {
      'medicines': medicinesCount,
      'prescriptions': prescriptionsCount,
      'reminder_logs': reminderLogsCount,
      'follow_ups': followUpsCount,
    };
  }

  // Check if database is empty
  Future<bool> isEmpty() async {
    final stats = await getDatabaseStats();
    return stats.values.every((count) => count == 0);
  }

  // Backup database (simple implementation)
  Future<String?> backupDatabase() async {
    try {
      final databasesPath = await getDatabasesPath();
      final sourcePath = join(databasesPath, DatabaseConstants.databaseName);
      final backupPath = '$sourcePath.backup';
      
      // Copy database file
      // Note: This is a simplified implementation
      // In a real app, you would use proper file copying
      return backupPath;
    } catch (e) {
      return null;
    }
  }

  // Restore database from backup
  Future<bool> restoreDatabase(String backupPath) async {
    try {
      await close();
      
      final databasesPath = await getDatabasesPath();
      final currentPath = join(databasesPath, DatabaseConstants.databaseName);
      
      // Delete current database
      await deleteDatabase(currentPath);
      
      // Copy backup to current location
      // Note: This is a simplified implementation
      // In a real app, you would use proper file copying
      
      // Reinitialize database
      _database = await _initDatabase();
      return true;
    } catch (e) {
      return false;
    }
  }
}