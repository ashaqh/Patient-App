import 'dart:async';
import 'package:sqflite/sqflite.dart';

import 'database_helper.dart';
import 'database_constants.dart';
import '../../domain/entities/medicine.dart';
import '../../core/services/database_encryption_service.dart';

class MedicineDataSource {
  final DatabaseHelper _databaseHelper;
  final DatabaseEncryptionService _encryptionService;

  MedicineDataSource(this._databaseHelper)
      : _encryptionService = DatabaseEncryptionService();

  // Create a new medicine
  Future<String> createMedicine(Medicine medicine) async {
    final db = await _databaseHelper.database;
    final medicineMap = medicine.toMap();
    
    // Encrypt sensitive fields before storage
    final encryptedMap = await _encryptionService.encryptMedicine(medicineMap);
    
    await db.transaction((txn) async {
      await txn.insert(
        DatabaseConstants.tableMedicines,
        encryptedMap,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await _databaseHelper.recordChange(
        txn, DatabaseConstants.tableMedicines, medicine.id, 'INSERT');
    });
    return medicine.id;
  }

  // Get medicine by ID
  Future<Medicine?> getMedicineById(String id) async {
    final db = await _databaseHelper.database;
    final maps = await db.query(
      DatabaseConstants.tableMedicines,
      where: '${DatabaseConstants.columnId} = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      final medicineMap = maps.first;
      
      // Decrypt sensitive fields after retrieval
      final decryptedMap = await _encryptionService.decryptMedicine(medicineMap);
      
      return Medicine.fromMap(decryptedMap);
    }
    return null;
  }

  // Get all medicines
  Future<List<Medicine>> getAllMedicines({bool activeOnly = false}) async {
    final db = await _databaseHelper.database;
    
    String whereClause = '';
    List<Object?> whereArgs = [];
    
    if (activeOnly) {
      whereClause = '${DatabaseConstants.columnMedicineIsActive} = ?';
      whereArgs.add(1);
    }
    
    final maps = await db.query(
      DatabaseConstants.tableMedicines,
      where: whereClause.isNotEmpty ? whereClause : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: '${DatabaseConstants.columnMedicineName} ASC',
    );

    // Decrypt sensitive fields for all medicines
    final decryptedMaps = await _encryptionService.batchDecryptMedicines(maps);
    
    return decryptedMaps.map((map) => Medicine.fromMap(map)).toList();
  }

  // Get active medicines
  Future<List<Medicine>> getActiveMedicines() async {
    return getAllMedicines(activeOnly: true);
  }

  // Get medicines for today
  Future<List<Medicine>> getMedicinesForToday() async {
    final allMedicines = await getActiveMedicines();
    return allMedicines.where((medicine) => medicine.shouldBeTakenToday()).toList();
  }

  // Get medicines by date range
  Future<List<Medicine>> getMedicinesByDateRange(DateTime startDate, DateTime endDate) async {
    final db = await _databaseHelper.database;
    
    // Convert dates to ISO strings for comparison
    final startDateStr = startDate.toIso8601String();
    final endDateStr = endDate.toIso8601String();
    
    final maps = await db.query(
      DatabaseConstants.tableMedicines,
      where: '''
        (${DatabaseConstants.columnMedicineStartDate} <= ? AND 
        (${DatabaseConstants.columnMedicineEndDate} IS NULL OR 
         ${DatabaseConstants.columnMedicineEndDate} >= ?))
      ''',
      whereArgs: [endDateStr, startDateStr],
      orderBy: '${DatabaseConstants.columnMedicineStartDate} DESC',
    );

    // Decrypt sensitive fields for all medicines
    final decryptedMaps = await _encryptionService.batchDecryptMedicines(maps);
    
    return decryptedMaps.map((map) => Medicine.fromMap(map)).toList();
  }

  // Update medicine
  Future<int> updateMedicine(Medicine medicine) async {
    final db = await _databaseHelper.database;
    // Bump version and update lastModified for updates
    final updatedMedicine = medicine.copyWith(
      version: medicine.version + 1,
      lastModified: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    final medicineMap = updatedMedicine.toMap();
    
    // Encrypt sensitive fields before storage
    final encryptedMap = await _encryptionService.encryptMedicine(medicineMap);
    
    return await db.transaction((txn) async {
      final result = await txn.update(
        DatabaseConstants.tableMedicines,
        encryptedMap,
        where: '${DatabaseConstants.columnId} = ?',
        whereArgs: [updatedMedicine.id],
      );
      await _databaseHelper.recordChange(
        txn, DatabaseConstants.tableMedicines, updatedMedicine.id, 'UPDATE');
      return result;
    });
  }

  // Delete medicine by ID
  Future<int> deleteMedicineById(String id) async {
    final db = await _databaseHelper.database;
    return await db.transaction((txn) async {
      final result = await txn.delete(
        DatabaseConstants.tableMedicines,
        where: '${DatabaseConstants.columnId} = ?',
        whereArgs: [id],
      );
      await _databaseHelper.recordChange(
        txn, DatabaseConstants.tableMedicines, id, 'DELETE');
      return result;
    });
  }

  // Delete all medicines
  Future<int> deleteAllMedicines() async {
    final db = await _databaseHelper.database;
    return await db.transaction((txn) async {
      final result = await txn.delete(DatabaseConstants.tableMedicines);
      await _databaseHelper.recordChange(
        txn, DatabaseConstants.tableMedicines, 'ALL', 'DELETE');
      return result;
    });
  }

  // Search medicines by name
  Future<List<Medicine>> searchMedicines(String query) async {
    final db = await _databaseHelper.database;
    final maps = await db.query(
      DatabaseConstants.tableMedicines,
      where: '${DatabaseConstants.columnMedicineName} LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: '${DatabaseConstants.columnMedicineName} ASC',
    );

    // Decrypt sensitive fields for all medicines
    final decryptedMaps = await _encryptionService.batchDecryptMedicines(maps);
    
    return decryptedMaps.map((map) => Medicine.fromMap(map)).toList();
  }

  // Get medicine count
  Future<int> getMedicineCount({bool activeOnly = false}) async {
    final db = await _databaseHelper.database;
    
    String whereClause = '';
    List<Object?> whereArgs = [];
    
    if (activeOnly) {
      whereClause = '${DatabaseConstants.columnMedicineIsActive} = ?';
      whereArgs.add(1);
    }
    
    final count = Sqflite.firstIntValue(
      await db.rawQuery(
        '''
        SELECT COUNT(*) FROM ${DatabaseConstants.tableMedicines}
        ${whereClause.isNotEmpty ? 'WHERE $whereClause' : ''}
        ''',
        whereArgs.isNotEmpty ? whereArgs : null,
      )
    );
    
    return count ?? 0;
  }

  // Toggle medicine active status
  Future<int> toggleMedicineStatus(String id, bool isActive) async {
    final db = await _databaseHelper.database;
    return await db.transaction((txn) async {
      // First, get the current version to bump it
      final maps = await txn.query(
        DatabaseConstants.tableMedicines,
        columns: [DatabaseConstants.columnVersion],
        where: '${DatabaseConstants.columnId} = ?',
        whereArgs: [id],
      );
      
      int currentVersion = 1;
      if (maps.isNotEmpty) {
        currentVersion = (maps.first[DatabaseConstants.columnVersion] as int?) ?? 1;
      }
      
      final result = await txn.update(
        DatabaseConstants.tableMedicines,
        {
          DatabaseConstants.columnMedicineIsActive: isActive ? 1 : 0,
          DatabaseConstants.columnUpdatedAt: DateTime.now().toIso8601String(),
          DatabaseConstants.columnLastModified: DateTime.now().toIso8601String(),
          DatabaseConstants.columnVersion: currentVersion + 1,
        },
        where: '${DatabaseConstants.columnId} = ?',
        whereArgs: [id],
      );
      
      await _databaseHelper.recordChange(
        txn, DatabaseConstants.tableMedicines, id, 'UPDATE');
      
      return result;
    });
  }

  // Get medicines that need reminders today
  Future<List<Medicine>> getMedicinesNeedingRemindersToday() async {
    final medicines = await getMedicinesForToday();
    return medicines.where((medicine) => medicine.getNextReminderTime() != null).toList();
  }

  // Batch insert medicines
  Future<void> batchInsertMedicines(List<Medicine> medicines) async {
    final db = await _databaseHelper.database;
    
    await db.transaction((txn) async {
      for (final medicine in medicines) {
        final medicineMap = medicine.toMap();
        
        // Encrypt sensitive fields before storage
        final encryptedMap = await _encryptionService.encryptMedicine(medicineMap);
        
        await txn.insert(
          DatabaseConstants.tableMedicines,
          encryptedMap,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        
        await _databaseHelper.recordChange(
          txn, DatabaseConstants.tableMedicines, medicine.id, 'INSERT');
      }
    });
  }

  // Update multiple medicines
  Future<void> batchUpdateMedicines(List<Medicine> medicines) async {
    final db = await _databaseHelper.database;
    
    await db.transaction((txn) async {
      for (var medicine in medicines) {
        // Bump version and update lastModified for updates
        medicine = medicine.copyWith(
          version: medicine.version + 1,
          lastModified: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        final medicineMap = medicine.toMap();
        
        // Encrypt sensitive fields before storage
        final encryptedMap = await _encryptionService.encryptMedicine(medicineMap);
        
        await txn.update(
          DatabaseConstants.tableMedicines,
          encryptedMap,
          where: '${DatabaseConstants.columnId} = ?',
          whereArgs: [medicine.id],
        );
        
        await _databaseHelper.recordChange(
          txn, DatabaseConstants.tableMedicines, medicine.id, 'UPDATE');
      }
    });
  }
}
