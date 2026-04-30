import 'dart:async';
import 'package:sqflite/sqflite.dart';

import 'database_helper.dart';
import 'database_constants.dart';
import '../../domain/entities/medicine.dart';

class MedicineDataSource {
  final DatabaseHelper _databaseHelper;

  MedicineDataSource(this._databaseHelper);

  // Create a new medicine
  Future<String> createMedicine(Medicine medicine) async {
    final db = await _databaseHelper.database;
    await db.insert(
      DatabaseConstants.tableMedicines,
      medicine.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
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
      return Medicine.fromMap(maps.first);
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

    return maps.map((map) => Medicine.fromMap(map)).toList();
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

    return maps.map((map) => Medicine.fromMap(map)).toList();
  }

  // Update medicine
  Future<int> updateMedicine(Medicine medicine) async {
    final db = await _databaseHelper.database;
    return await db.update(
      DatabaseConstants.tableMedicines,
      medicine.toMap(),
      where: '${DatabaseConstants.columnId} = ?',
      whereArgs: [medicine.id],
    );
  }

  // Delete medicine by ID
  Future<int> deleteMedicineById(String id) async {
    final db = await _databaseHelper.database;
    return await db.delete(
      DatabaseConstants.tableMedicines,
      where: '${DatabaseConstants.columnId} = ?',
      whereArgs: [id],
    );
  }

  // Delete all medicines
  Future<int> deleteAllMedicines() async {
    final db = await _databaseHelper.database;
    return await db.delete(DatabaseConstants.tableMedicines);
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

    return maps.map((map) => Medicine.fromMap(map)).toList();
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
    return await db.update(
      DatabaseConstants.tableMedicines,
      {
        DatabaseConstants.columnMedicineIsActive: isActive ? 1 : 0,
        DatabaseConstants.columnUpdatedAt: DateTime.now().toIso8601String(),
      },
      where: '${DatabaseConstants.columnId} = ?',
      whereArgs: [id],
    );
  }

  // Get medicines that need reminders today
  Future<List<Medicine>> getMedicinesNeedingRemindersToday() async {
    final medicines = await getMedicinesForToday();
    return medicines.where((medicine) => medicine.getNextReminderTime() != null).toList();
  }

  // Batch insert medicines
  Future<void> batchInsertMedicines(List<Medicine> medicines) async {
    final db = await _databaseHelper.database;
    final batch = db.batch();
    
    for (final medicine in medicines) {
      batch.insert(
        DatabaseConstants.tableMedicines,
        medicine.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    
    await batch.commit(noResult: true);
  }

  // Update multiple medicines
  Future<void> batchUpdateMedicines(List<Medicine> medicines) async {
    final db = await _databaseHelper.database;
    final batch = db.batch();
    
    for (final medicine in medicines) {
      batch.update(
        DatabaseConstants.tableMedicines,
        medicine.toMap(),
        where: '${DatabaseConstants.columnId} = ?',
        whereArgs: [medicine.id],
      );
    }
    
    await batch.commit(noResult: true);
  }
}