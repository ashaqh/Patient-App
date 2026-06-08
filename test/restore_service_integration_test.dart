import 'dart:io';

import 'package:carevault/core/services/backup/restore_service.dart';
import 'package:carevault/data/datasources/database_constants.dart';
import 'package:carevault/data/datasources/database_helper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Integration test for RestoreService
/// 
/// This test verifies that the database connection lifecycle is properly managed
/// during restore operations, specifically addressing the database_closed exception
/// that occurred after restore completion.
/// 
/// Run this test on a device or emulator:
/// flutter test test/restore_service_integration_test.dart --device-id=<device-id>
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  group('RestoreService Integration Tests', () {
    late DatabaseHelper dbHelper;

    setUp(() async {
      databaseFactory = databaseFactoryFfi;
      dbHelper = DatabaseHelper();
    });

    tearDown(() async {
      await dbHelper.close();
    });

    test('database connection should remain valid after restore operation', () async {
      // This test simulates the restore workflow to verify that
      // the database connection is properly reinitialized after file replacement
      
      // Step 1: Create initial database with test data
      final db = await dbHelper.database;
      await db.insert(DatabaseConstants.tableVitalSigns, {
        DatabaseConstants.columnId: 'test-vital-original',
        DatabaseConstants.columnVitalSignType: 'blood_pressure',
        DatabaseConstants.columnVitalSignValue1: 120.0,
        DatabaseConstants.columnVitalSignValue2: 80.0,
        DatabaseConstants.columnVitalSignUnit: 'mmHg',
        DatabaseConstants.columnVitalSignReadingTime: DateTime.now().toIso8601String(),
        DatabaseConstants.columnVitalSignIsManualEntry: 1,
        DatabaseConstants.columnCreatedAt: DateTime.now().toIso8601String(),
        DatabaseConstants.columnUpdatedAt: DateTime.now().toIso8601String(),
        DatabaseConstants.columnLastModified: DateTime.now().toIso8601String(),
        DatabaseConstants.columnVersion: 1,
      });

      // Verify original data exists
      final originalData = await db.query(DatabaseConstants.tableVitalSigns);
      expect(originalData.length, 1);
      expect(originalData[0][DatabaseConstants.columnId], 'test-vital-original');

      // Step 2: Simulate the restore process
      // Close the database connection (as done in _replaceDatabase)
      await dbHelper.close();

      // Step 3: Reset database (this is what the fix does)
      // This ensures a fresh connection is created
      await dbHelper.resetDatabase();

      // Step 4: Verify database is accessible and functional
      final restoredDb = await dbHelper.database;
      expect(restoredDb.isOpen, true, reason: 'Database should be open after reset');

      // Step 5: Verify we can perform database operations
      // This is the critical test - if the connection is stale, this will fail
      final vitalSigns = await restoredDb.query(DatabaseConstants.tableVitalSigns);
      expect(vitalSigns, isNotNull, reason: 'Should be able to query database');
      
      // Step 6: Verify we can insert new data
      await restoredDb.insert(DatabaseConstants.tableVitalSigns, {
        DatabaseConstants.columnId: 'test-vital-after-restore',
        DatabaseConstants.columnVitalSignType: 'heart_rate',
        DatabaseConstants.columnVitalSignValue1: 72.0,
        DatabaseConstants.columnVitalSignUnit: 'bpm',
        DatabaseConstants.columnVitalSignReadingTime: DateTime.now().toIso8601String(),
        DatabaseConstants.columnVitalSignIsManualEntry: 1,
        DatabaseConstants.columnCreatedAt: DateTime.now().toIso8601String(),
        DatabaseConstants.columnUpdatedAt: DateTime.now().toIso8601String(),
        DatabaseConstants.columnLastModified: DateTime.now().toIso8601String(),
        DatabaseConstants.columnVersion: 1,
      });

      final afterInsert = await restoredDb.query(DatabaseConstants.tableVitalSigns);
      expect(afterInsert.length, greaterThan(0), 
        reason: 'Should be able to insert data after restore');
    });

    test('database should handle multiple close/reset cycles', () async {
      // This test verifies that the database can handle multiple
      // close and reset operations without issues
      
      for (int i = 0; i < 3; i++) {
        // Get database connection
        final db = await dbHelper.database;
        expect(db.isOpen, true, reason: 'Database should be open on iteration $i');

        // Insert test data
        await db.insert(DatabaseConstants.tableVitalSigns, {
          DatabaseConstants.columnId: 'test-vital-$i',
          DatabaseConstants.columnVitalSignType: 'temperature',
          DatabaseConstants.columnVitalSignValue1: 98.6,
          DatabaseConstants.columnVitalSignUnit: '°F',
          DatabaseConstants.columnVitalSignReadingTime: DateTime.now().toIso8601String(),
          DatabaseConstants.columnVitalSignIsManualEntry: 1,
          DatabaseConstants.columnCreatedAt: DateTime.now().toIso8601String(),
          DatabaseConstants.columnUpdatedAt: DateTime.now().toIso8601String(),
          DatabaseConstants.columnLastModified: DateTime.now().toIso8601String(),
          DatabaseConstants.columnVersion: 1,
        });

        // Close and reset
        await dbHelper.close();
        await dbHelper.resetDatabase();

        // Verify database is accessible
        final resetDb = await dbHelper.database;
        expect(resetDb.isOpen, true, 
          reason: 'Database should be open after reset on iteration $i');
      }
    });

    test('error handling should not leave database in broken state', () async {
      // This test verifies that even if an error occurs during restore,
      // the database remains accessible
      
      // Get initial database connection
      final db = await dbHelper.database;
      expect(db.isOpen, true);

      // Insert test data
      await db.insert(DatabaseConstants.tableVitalSigns, {
        DatabaseConstants.columnId: 'test-vital-error-handling',
        DatabaseConstants.columnVitalSignType: 'blood_glucose',
        DatabaseConstants.columnVitalSignValue1: 100.0,
        DatabaseConstants.columnVitalSignUnit: 'mg/dL',
        DatabaseConstants.columnVitalSignReadingTime: DateTime.now().toIso8601String(),
        DatabaseConstants.columnVitalSignIsManualEntry: 1,
        DatabaseConstants.columnCreatedAt: DateTime.now().toIso8601String(),
        DatabaseConstants.columnUpdatedAt: DateTime.now().toIso8601String(),
        DatabaseConstants.columnLastModified: DateTime.now().toIso8601String(),
        DatabaseConstants.columnVersion: 1,
      });

      // Simulate an error scenario by closing the database
      await dbHelper.close();

      // Even after an error, we should be able to get a fresh connection
      final recoveredDb = await dbHelper.database;
      expect(recoveredDb.isOpen, true, 
        reason: 'Database should be recoverable after error');

      // Verify we can still query data
      final data = await recoveredDb.query(DatabaseConstants.tableVitalSigns);
      expect(data, isNotNull, reason: 'Should be able to query after recovery');
    });
  });
}
