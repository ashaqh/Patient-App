import 'dart:async';
import 'package:sqflite/sqflite.dart';

import 'database_helper.dart';
import 'database_constants.dart';
import '../../domain/entities/vital_sign.dart';
import '../../core/services/database_encryption_service.dart';

class VitalSignDataSource {
  final DatabaseHelper _databaseHelper;
  final DatabaseEncryptionService _encryptionService;

  VitalSignDataSource(this._databaseHelper)
      : _encryptionService = DatabaseEncryptionService();

  // Create a new vital sign
  Future<String> createVitalSign(VitalSign vitalSign) async {
    final db = await _databaseHelper.database;
    final vitalSignMap = vitalSign.toMap();
    
    // Encrypt sensitive fields before storage
    final encryptedMap = await _encryptionService.encryptVitalSign(vitalSignMap);
    
    await db.insert(
      DatabaseConstants.tableVitalSigns,
      encryptedMap,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return vitalSign.id;
  }

  // Get vital sign by ID
  Future<VitalSign?> getVitalSignById(String id) async {
    final db = await _databaseHelper.database;
    final maps = await db.query(
      DatabaseConstants.tableVitalSigns,
      where: '${DatabaseConstants.columnId} = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      final vitalSignMap = maps.first;
      
      // Decrypt sensitive fields after retrieval
      final decryptedMap = await _encryptionService.decryptVitalSign(vitalSignMap);
      
      return VitalSign.fromMap(decryptedMap);
    }
    return null;
  }

  // Get all vital signs
  Future<List<VitalSign>> getAllVitalSigns() async {
    final db = await _databaseHelper.database;
    
    final maps = await db.query(
      DatabaseConstants.tableVitalSigns,
      orderBy: '${DatabaseConstants.columnVitalSignReadingTime} DESC',
    );

    // Decrypt sensitive fields for all vital signs
    final decryptedMaps = await _encryptionService.batchDecryptVitalSigns(maps);
    
    return decryptedMaps.map((map) => VitalSign.fromMap(map)).toList();
  }

  // Get vital signs by type
  Future<List<VitalSign>> getVitalSignsByType(VitalSignType type) async {
    final db = await _databaseHelper.database;
    
    final maps = await db.query(
      DatabaseConstants.tableVitalSigns,
      where: '${DatabaseConstants.columnVitalSignType} = ?',
      whereArgs: [type.name],
      orderBy: '${DatabaseConstants.columnVitalSignReadingTime} DESC',
    );

    final decryptedMaps = await _encryptionService.batchDecryptVitalSigns(maps);
    return decryptedMaps.map((map) => VitalSign.fromMap(map)).toList();
  }

  // Get vital signs by date range
  Future<List<VitalSign>> getVitalSignsByDateRange(DateTime startDate, DateTime endDate) async {
    final db = await _databaseHelper.database;
    
    final startDateStr = startDate.toIso8601String();
    final endDateStr = endDate.toIso8601String();
    
    final maps = await db.query(
      DatabaseConstants.tableVitalSigns,
      where: '${DatabaseConstants.columnVitalSignReadingTime} >= ? AND ${DatabaseConstants.columnVitalSignReadingTime} <= ?',
      whereArgs: [startDateStr, endDateStr],
      orderBy: '${DatabaseConstants.columnVitalSignReadingTime} DESC',
    );

    final decryptedMaps = await _encryptionService.batchDecryptVitalSigns(maps);
    return decryptedMaps.map((map) => VitalSign.fromMap(map)).toList();
  }

  // Get vital signs by type and date range
  Future<List<VitalSign>> getVitalSignsByTypeAndDateRange(
    VitalSignType type, 
    DateTime startDate, 
    DateTime endDate
  ) async {
    final db = await _databaseHelper.database;
    
    final startDateStr = startDate.toIso8601String();
    final endDateStr = endDate.toIso8601String();
    
    final maps = await db.query(
      DatabaseConstants.tableVitalSigns,
      where: '${DatabaseConstants.columnVitalSignType} = ? AND ${DatabaseConstants.columnVitalSignReadingTime} >= ? AND ${DatabaseConstants.columnVitalSignReadingTime} <= ?',
      whereArgs: [type.name, startDateStr, endDateStr],
      orderBy: '${DatabaseConstants.columnVitalSignReadingTime} DESC',
    );

    final decryptedMaps = await _encryptionService.batchDecryptVitalSigns(maps);
    return decryptedMaps.map((map) => VitalSign.fromMap(map)).toList();
  }

  // Get latest vital sign by type
  Future<VitalSign?> getLatestVitalSignByType(VitalSignType type) async {
    final db = await _databaseHelper.database;
    
    final maps = await db.query(
      DatabaseConstants.tableVitalSigns,
      where: '${DatabaseConstants.columnVitalSignType} = ?',
      whereArgs: [type.name],
      orderBy: '${DatabaseConstants.columnVitalSignReadingTime} DESC',
      limit: 1,
    );

    if (maps.isNotEmpty) {
      final decryptedMap = await _encryptionService.decryptVitalSign(maps.first);
      return VitalSign.fromMap(decryptedMap);
    }
    return null;
  }

  // Get vital signs for today
  Future<List<VitalSign>> getTodaysVitalSigns() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
    
    return getVitalSignsByDateRange(startOfDay, endOfDay);
  }

  // Get vital signs for last 7 days
  Future<List<VitalSign>> getLast7DaysVitalSigns() async {
    final now = DateTime.now();
    final startDate = now.subtract(const Duration(days: 7));
    
    return getVitalSignsByDateRange(startDate, now);
  }

  // Get vital signs for last 30 days
  Future<List<VitalSign>> getLast30DaysVitalSigns() async {
    final now = DateTime.now();
    final startDate = now.subtract(const Duration(days: 30));
    
    return getVitalSignsByDateRange(startDate, now);
  }

  // Update vital sign
  Future<int> updateVitalSign(VitalSign vitalSign) async {
    final db = await _databaseHelper.database;
    final vitalSignMap = vitalSign.toMap();
    
    final encryptedMap = await _encryptionService.encryptVitalSign(vitalSignMap);
    
    return await db.update(
      DatabaseConstants.tableVitalSigns,
      encryptedMap,
      where: '${DatabaseConstants.columnId} = ?',
      whereArgs: [vitalSign.id],
    );
  }

  // Delete vital sign by ID
  Future<int> deleteVitalSignById(String id) async {
    final db = await _databaseHelper.database;
    return await db.delete(
      DatabaseConstants.tableVitalSigns,
      where: '${DatabaseConstants.columnId} = ?',
      whereArgs: [id],
    );
  }

  // Delete all vital signs
  Future<int> deleteAllVitalSigns() async {
    final db = await _databaseHelper.database;
    return await db.delete(DatabaseConstants.tableVitalSigns);
  }

  // Delete vital signs by type
  Future<int> deleteVitalSignsByType(VitalSignType type) async {
    final db = await _databaseHelper.database;
    return await db.delete(
      DatabaseConstants.tableVitalSigns,
      where: '${DatabaseConstants.columnVitalSignType} = ?',
      whereArgs: [type.name],
    );
  }

  // Get vital sign count
  Future<int> getVitalSignCount({VitalSignType? type}) async {
    final db = await _databaseHelper.database;
    
    String whereClause = '';
    List<Object?> whereArgs = [];
    
    if (type != null) {
      whereClause = '${DatabaseConstants.columnVitalSignType} = ?';
      whereArgs.add(type.name);
    }
    
    final count = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM ${DatabaseConstants.tableVitalSigns}${whereClause.isNotEmpty ? ' WHERE $whereClause' : ''}',
        whereArgs.isNotEmpty ? whereArgs : null,
      )
    ) ?? 0;
    
    return count;
  }

  // Get statistics for a specific type
  Future<Map<String, dynamic>> getVitalSignStatistics(
    VitalSignType type,
    DateTime startDate,
    DateTime endDate
  ) async {
    final vitalSigns = await getVitalSignsByTypeAndDateRange(type, startDate, endDate);
    
    if (vitalSigns.isEmpty) {
      return {
        'count': 0,
        'average': 0,
        'min': 0,
        'max': 0,
        'latest': null,
        'trend': 'stable',
      };
    }
    
    // For blood pressure, calculate statistics for systolic (value1)
    final values = vitalSigns.map((vs) => vs.value1).toList();
    
    final average = values.reduce((a, b) => a + b) / values.length;
    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);
    
    // Calculate trend (compare first and last values)
    final firstValue = vitalSigns.last.value1; // Oldest
    final lastValue = vitalSigns.first.value1; // Latest
    final trend = lastValue > firstValue ? 'up' : lastValue < firstValue ? 'down' : 'stable';
    
    return {
      'count': vitalSigns.length,
      'average': average,
      'min': min,
      'max': max,
      'latest': vitalSigns.first,
      'trend': trend,
    };
  }

  // Get trends for a specific type
  Future<List<Map<String, dynamic>>> getVitalSignTrends(
    VitalSignType type,
    int days
  ) async {
    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: days));
    final vitalSigns = await getVitalSignsByTypeAndDateRange(type, startDate, now);
    
    // Group by day
    final Map<String, List<VitalSign>> groupedByDay = {};
    
    for (final vitalSign in vitalSigns) {
      final dayKey = '${vitalSign.readingTime.year}-${vitalSign.readingTime.month}-${vitalSign.readingTime.day}';
      groupedByDay.putIfAbsent(dayKey, () => []).add(vitalSign);
    }
    
    // Calculate daily averages
    final List<Map<String, dynamic>> trends = [];
    
    for (final entry in groupedByDay.entries) {
      final dayVitalSigns = entry.value;
      final values = dayVitalSigns.map((vs) => vs.value1).toList();
      final average = values.reduce((a, b) => a + b) / values.length;
      
      trends.add({
        'date': entry.key,
        'average': average,
        'count': dayVitalSigns.length,
        'latest': dayVitalSigns.first,
      });
    }
    
    // Sort by date ascending
    trends.sort((a, b) => a['date'].compareTo(b['date']));
    
    return trends;
  }

  // Check if vital sign is abnormal
  Future<bool> isAbnormalVitalSign(VitalSign vitalSign) async {
    return !vitalSign.isWithinTargetRange;
  }

  // Get abnormal vital signs
  Future<List<VitalSign>> getAbnormalVitalSigns(DateTime startDate, DateTime endDate) async {
    final vitalSigns = await getVitalSignsByDateRange(startDate, endDate);
    return vitalSigns.where((vs) => !vs.isWithinTargetRange).toList();
  }

  // Batch insert vital signs
  Future<void> batchInsertVitalSigns(List<VitalSign> vitalSigns) async {
    final db = await _databaseHelper.database;
    
    await db.transaction((txn) async {
      for (final vitalSign in vitalSigns) {
        final vitalSignMap = vitalSign.toMap();
        final encryptedMap = await _encryptionService.encryptVitalSign(vitalSignMap);
        
        await txn.insert(
          DatabaseConstants.tableVitalSigns,
          encryptedMap,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  // Update multiple vital signs
  Future<void> batchUpdateVitalSigns(List<VitalSign> vitalSigns) async {
    final db = await _databaseHelper.database;
    
    await db.transaction((txn) async {
      for (final vitalSign in vitalSigns) {
        final vitalSignMap = vitalSign.toMap();
        final encryptedMap = await _encryptionService.encryptVitalSign(vitalSignMap);
        
        await txn.update(
          DatabaseConstants.tableVitalSigns,
          encryptedMap,
          where: '${DatabaseConstants.columnId} = ?',
          whereArgs: [vitalSign.id],
        );
      }
    });
  }
}