import 'dart:async';
import 'package:sqflite/sqflite.dart';

import 'database_helper.dart';
import 'database_constants.dart';
import '../../domain/entities/reminder_log.dart';

class ReminderLogDataSource {
  final DatabaseHelper _databaseHelper;

  ReminderLogDataSource(this._databaseHelper);

  // Create a new reminder log
  Future<String> createReminderLog(ReminderLog reminderLog) async {
    final db = await _databaseHelper.database;
    await db.insert(
      DatabaseConstants.tableReminderLogs,
      reminderLog.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return reminderLog.id;
  }

  // Get reminder log by ID
  Future<ReminderLog?> getReminderLogById(String id) async {
    final db = await _databaseHelper.database;
    final maps = await db.query(
      DatabaseConstants.tableReminderLogs,
      where: '${DatabaseConstants.columnId} = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return ReminderLog.fromMap(maps.first);
    }
    return null;
  }

  // Get all reminder logs
  Future<List<ReminderLog>> getAllReminderLogs({String? orderBy}) async {
    final db = await _databaseHelper.database;
    
    final maps = await db.query(
      DatabaseConstants.tableReminderLogs,
      orderBy: orderBy ?? '${DatabaseConstants.columnReminderScheduledTime} DESC',
    );

    return maps.map((map) => ReminderLog.fromMap(map)).toList();
  }

  // Get reminder logs by medicine ID
  Future<List<ReminderLog>> getReminderLogsByMedicineId(String medicineId) async {
    final db = await _databaseHelper.database;
    
    final maps = await db.query(
      DatabaseConstants.tableReminderLogs,
      where: '${DatabaseConstants.columnReminderMedicineId} = ?',
      whereArgs: [medicineId],
      orderBy: '${DatabaseConstants.columnReminderScheduledTime} DESC',
    );

    return maps.map((map) => ReminderLog.fromMap(map)).toList();
  }

  // Get reminder logs by date
  Future<List<ReminderLog>> getReminderLogsByDate(DateTime date) async {
    final db = await _databaseHelper.database;
    
    // Get start and end of day
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
    
    final startDateStr = startOfDay.toIso8601String();
    final endDateStr = endOfDay.toIso8601String();
    
    final maps = await db.query(
      DatabaseConstants.tableReminderLogs,
      where: '${DatabaseConstants.columnReminderScheduledTime} BETWEEN ? AND ?',
      whereArgs: [startDateStr, endDateStr],
      orderBy: '${DatabaseConstants.columnReminderScheduledTime} ASC',
    );

    return maps.map((map) => ReminderLog.fromMap(map)).toList();
  }

  // Get reminder logs for today
  Future<List<ReminderLog>> getReminderLogsForToday() async {
    return getReminderLogsByDate(DateTime.now());
  }

  // Get reminder logs by status
  Future<List<ReminderLog>> getReminderLogsByStatus(ReminderStatus status) async {
    final db = await _databaseHelper.database;
    
    final maps = await db.query(
      DatabaseConstants.tableReminderLogs,
      where: '${DatabaseConstants.columnReminderStatus} = ?',
      whereArgs: [status.dbValue],
      orderBy: '${DatabaseConstants.columnReminderScheduledTime} DESC',
    );

    return maps.map((map) => ReminderLog.fromMap(map)).toList();
  }

  // Get overdue reminder logs (pending and scheduled time has passed)
  Future<List<ReminderLog>> getOverdueReminderLogs() async {
    final db = await _databaseHelper.database;
    final now = DateTime.now().toIso8601String();
    
    final maps = await db.query(
      DatabaseConstants.tableReminderLogs,
      where: '''
        ${DatabaseConstants.columnReminderStatus} = ? AND
        ${DatabaseConstants.columnReminderScheduledTime} < ?
      ''',
      whereArgs: [ReminderStatus.pending.dbValue, now],
      orderBy: '${DatabaseConstants.columnReminderScheduledTime} ASC',
    );

    return maps.map((map) => ReminderLog.fromMap(map)).toList();
  }

  // Get upcoming reminder logs (pending and scheduled time is in future)
  Future<List<ReminderLog>> getUpcomingReminderLogs() async {
    final db = await _databaseHelper.database;
    final now = DateTime.now().toIso8601String();
    
    final maps = await db.query(
      DatabaseConstants.tableReminderLogs,
      where: '''
        ${DatabaseConstants.columnReminderStatus} = ? AND
        ${DatabaseConstants.columnReminderScheduledTime} > ?
      ''',
      whereArgs: [ReminderStatus.pending.dbValue, now],
      orderBy: '${DatabaseConstants.columnReminderScheduledTime} ASC',
    );

    return maps.map((map) => ReminderLog.fromMap(map)).toList();
  }

  // Update reminder log
  Future<int> updateReminderLog(ReminderLog reminderLog) async {
    final db = await _databaseHelper.database;
    return await db.update(
      DatabaseConstants.tableReminderLogs,
      reminderLog.toMap(),
      where: '${DatabaseConstants.columnId} = ?',
      whereArgs: [reminderLog.id],
    );
  }

  // Update reminder log status
  Future<int> updateReminderLogStatus(String id, ReminderStatus status, {String? notes}) async {
    final db = await _databaseHelper.database;
    
    final updateData = <String, dynamic>{
      DatabaseConstants.columnReminderStatus: status.dbValue,
    };
    
    if (status == ReminderStatus.taken || status == ReminderStatus.skipped) {
      updateData[DatabaseConstants.columnReminderActualTime] = DateTime.now().toIso8601String();
    }
    
    if (notes != null) {
      updateData[DatabaseConstants.columnReminderNotes] = notes;
    }
    
    return await db.update(
      DatabaseConstants.tableReminderLogs,
      updateData,
      where: '${DatabaseConstants.columnId} = ?',
      whereArgs: [id],
    );
  }

  // Delete reminder log by ID
  Future<int> deleteReminderLogById(String id) async {
    final db = await _databaseHelper.database;
    return await db.delete(
      DatabaseConstants.tableReminderLogs,
      where: '${DatabaseConstants.columnId} = ?',
      whereArgs: [id],
    );
  }

  // Delete all reminder logs
  Future<int> deleteAllReminderLogs() async {
    final db = await _databaseHelper.database;
    return await db.delete(DatabaseConstants.tableReminderLogs);
  }

  // Delete reminder logs by medicine ID
  Future<int> deleteReminderLogsByMedicineId(String medicineId) async {
    final db = await _databaseHelper.database;
    return await db.delete(
      DatabaseConstants.tableReminderLogs,
      where: '${DatabaseConstants.columnReminderMedicineId} = ?',
      whereArgs: [medicineId],
    );
  }

  // Get reminder log count
  Future<int> getReminderLogCount({ReminderStatus? status}) async {
    final db = await _databaseHelper.database;
    
    String whereClause = '';
    List<Object?> whereArgs = [];
    
    if (status != null) {
      whereClause = '${DatabaseConstants.columnReminderStatus} = ?';
      whereArgs.add(status.dbValue);
    }
    
    final count = Sqflite.firstIntValue(
      await db.rawQuery(
        '''
        SELECT COUNT(*) FROM ${DatabaseConstants.tableReminderLogs}
        ${whereClause.isNotEmpty ? 'WHERE $whereClause' : ''}
        ''',
        whereArgs.isNotEmpty ? whereArgs : null,
      )
    );
    
    return count ?? 0;
  }

  // Get adherence rate for a medicine (percentage of taken reminders)
  Future<double> getAdherenceRateForMedicine(String medicineId) async {
    final db = await _databaseHelper.database;
    
    // Get total reminders for this medicine
    final totalCount = Sqflite.firstIntValue(
      await db.rawQuery(
        '''
        SELECT COUNT(*) FROM ${DatabaseConstants.tableReminderLogs}
        WHERE ${DatabaseConstants.columnReminderMedicineId} = ?
        ''',
        [medicineId],
      )
    ) ?? 0;
    
    if (totalCount == 0) return 0.0;
    
    // Get taken reminders for this medicine
    final takenCount = Sqflite.firstIntValue(
      await db.rawQuery(
        '''
        SELECT COUNT(*) FROM ${DatabaseConstants.tableReminderLogs}
        WHERE ${DatabaseConstants.columnReminderMedicineId} = ? AND
              ${DatabaseConstants.columnReminderStatus} = ?
        ''',
        [medicineId, ReminderStatus.taken.dbValue],
      )
    ) ?? 0;
    
    return (takenCount / totalCount) * 100;
  }

  // Get adherence rate overall (percentage of taken reminders)
  Future<double> getOverallAdherenceRate() async {
    final db = await _databaseHelper.database;
    
    // Get total reminders
    final totalCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM ${DatabaseConstants.tableReminderLogs}')
    ) ?? 0;
    
    if (totalCount == 0) return 0.0;
    
    // Get taken reminders
    final takenCount = Sqflite.firstIntValue(
      await db.rawQuery(
        '''
        SELECT COUNT(*) FROM ${DatabaseConstants.tableReminderLogs}
        WHERE ${DatabaseConstants.columnReminderStatus} = ?
        ''',
        [ReminderStatus.taken.dbValue],
      )
    ) ?? 0;
    
    return (takenCount / totalCount) * 100;
  }

  // Get reminder logs by date range
  Future<List<ReminderLog>> getReminderLogsByDateRange(DateTime startDate, DateTime endDate) async {
    final db = await _databaseHelper.database;
    
    // Convert dates to ISO strings for comparison
    final startDateStr = startDate.toIso8601String();
    final endDateStr = endDate.toIso8601String();
    
    final maps = await db.query(
      DatabaseConstants.tableReminderLogs,
      where: '${DatabaseConstants.columnReminderScheduledTime} BETWEEN ? AND ?',
      whereArgs: [startDateStr, endDateStr],
      orderBy: '${DatabaseConstants.columnReminderScheduledTime} ASC',
    );

    return maps.map((map) => ReminderLog.fromMap(map)).toList();
  }

  // Get reminder logs for the last N days
  Future<List<ReminderLog>> getReminderLogsForLastNDays(int days) async {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: days));
    return getReminderLogsByDateRange(startDate, endDate);
  }

  // Get reminder logs grouped by date
  Future<Map<String, List<ReminderLog>>> getReminderLogsGroupedByDate() async {
    final reminderLogs = await getAllReminderLogs(orderBy: '${DatabaseConstants.columnReminderScheduledTime} ASC');
    final grouped = <String, List<ReminderLog>>{};
    
    for (final log in reminderLogs) {
      final dateKey = '${log.scheduledTime.year}-${log.scheduledTime.month.toString().padLeft(2, '0')}-${log.scheduledTime.day.toString().padLeft(2, '0')}';
      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(log);
    }
    
    return grouped;
  }

  // Get reminder logs grouped by medicine
  Future<Map<String, List<ReminderLog>>> getReminderLogsGroupedByMedicine() async {
    final reminderLogs = await getAllReminderLogs(orderBy: '${DatabaseConstants.columnReminderMedicineName} ASC');
    final grouped = <String, List<ReminderLog>>{};
    
    for (final log in reminderLogs) {
      if (!grouped.containsKey(log.medicineName)) {
        grouped[log.medicineName] = [];
      }
      grouped[log.medicineName]!.add(log);
    }
    
    return grouped;
  }

  // Batch insert reminder logs
  Future<void> batchInsertReminderLogs(List<ReminderLog> reminderLogs) async {
    final db = await _databaseHelper.database;
    final batch = db.batch();
    
    for (final log in reminderLogs) {
      batch.insert(
        DatabaseConstants.tableReminderLogs,
        log.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    
    await batch.commit(noResult: true);
  }

  // Update multiple reminder logs
  Future<void> batchUpdateReminderLogs(List<ReminderLog> reminderLogs) async {
    final db = await _databaseHelper.database;
    final batch = db.batch();
    
    for (final log in reminderLogs) {
      batch.update(
        DatabaseConstants.tableReminderLogs,
        log.toMap(),
        where: '${DatabaseConstants.columnId} = ?',
        whereArgs: [log.id],
      );
    }
    
    await batch.commit(noResult: true);
  }

  // Get reminder log statistics
  Future<Map<String, int>> getReminderLogStatistics() async {
    final db = await _databaseHelper.database;
    
    final total = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM ${DatabaseConstants.tableReminderLogs}')
    ) ?? 0;
    
    final taken = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM ${DatabaseConstants.tableReminderLogs} WHERE ${DatabaseConstants.columnReminderStatus} = ?',
        [ReminderStatus.taken.dbValue],
      )
    ) ?? 0;
    
    final skipped = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM ${DatabaseConstants.tableReminderLogs} WHERE ${DatabaseConstants.columnReminderStatus} = ?',
        [ReminderStatus.skipped.dbValue],
      )
    ) ?? 0;
    
    final missed = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM ${DatabaseConstants.tableReminderLogs} WHERE ${DatabaseConstants.columnReminderStatus} = ?',
        [ReminderStatus.missed.dbValue],
      )
    ) ?? 0;
    
    final snoozed = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM ${DatabaseConstants.tableReminderLogs} WHERE ${DatabaseConstants.columnReminderStatus} = ?',
        [ReminderStatus.snoozed.dbValue],
      )
    ) ?? 0;
    
    final pending = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM ${DatabaseConstants.tableReminderLogs} WHERE ${DatabaseConstants.columnReminderStatus} = ?',
        [ReminderStatus.pending.dbValue],
      )
    ) ?? 0;
    
    return {
      'total': total,
      'taken': taken,
      'skipped': skipped,
      'missed': missed,
      'snoozed': snoozed,
      'pending': pending,
    };
  }
}