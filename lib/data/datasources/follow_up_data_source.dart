import 'dart:async';
import 'package:sqflite/sqflite.dart';

import 'database_helper.dart';
import 'database_constants.dart';
import '../../domain/entities/follow_up.dart';

class FollowUpDataSource {
  final DatabaseHelper _databaseHelper;

  FollowUpDataSource(this._databaseHelper);

  // Create a new follow-up
  Future<String> createFollowUp(FollowUp followUp) async {
    final db = await _databaseHelper.database;
    await db.insert(
      DatabaseConstants.tableFollowUps,
      followUp.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return followUp.id;
  }

  // Get follow-up by ID
  Future<FollowUp?> getFollowUpById(String id) async {
    final db = await _databaseHelper.database;
    final maps = await db.query(
      DatabaseConstants.tableFollowUps,
      where: '${DatabaseConstants.columnId} = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return FollowUp.fromMap(maps.first);
    }
    return null;
  }

  // Get all follow-ups
  Future<List<FollowUp>> getAllFollowUps({String? orderBy}) async {
    final db = await _databaseHelper.database;
    
    final maps = await db.query(
      DatabaseConstants.tableFollowUps,
      orderBy: orderBy ?? '${DatabaseConstants.columnFollowUpDate} ASC',
    );

    return maps.map((map) => FollowUp.fromMap(map)).toList();
  }

  // Get upcoming follow-ups (future dates, scheduled status)
  Future<List<FollowUp>> getUpcomingFollowUps({int? limit}) async {
    final db = await _databaseHelper.database;
    final now = DateTime.now().toIso8601String();
    
    final maps = await db.query(
      DatabaseConstants.tableFollowUps,
      where: '''
        ${DatabaseConstants.columnFollowUpDate} > ? AND
        ${DatabaseConstants.columnFollowUpStatus} = ?
      ''',
      whereArgs: [now, FollowUpStatus.scheduled.dbValue],
      orderBy: '${DatabaseConstants.columnFollowUpDate} ASC',
      limit: limit,
    );

    return maps.map((map) => FollowUp.fromMap(map)).toList();
  }

  // Get overdue follow-ups (past dates, scheduled status)
  Future<List<FollowUp>> getOverdueFollowUps() async {
    final db = await _databaseHelper.database;
    final now = DateTime.now().toIso8601String();
    
    final maps = await db.query(
      DatabaseConstants.tableFollowUps,
      where: '''
        ${DatabaseConstants.columnFollowUpDate} < ? AND
        ${DatabaseConstants.columnFollowUpStatus} = ?
      ''',
      whereArgs: [now, FollowUpStatus.scheduled.dbValue],
      orderBy: '${DatabaseConstants.columnFollowUpDate} ASC',
    );

    return maps.map((map) => FollowUp.fromMap(map)).toList();
  }

  // Get follow-ups for today
  Future<List<FollowUp>> getFollowUpsForToday() async {
    final db = await _databaseHelper.database;
    
    // Get start and end of today
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
    
    final startDateStr = startOfDay.toIso8601String();
    final endDateStr = endOfDay.toIso8601String();
    
    final maps = await db.query(
      DatabaseConstants.tableFollowUps,
      where: '${DatabaseConstants.columnFollowUpDate} BETWEEN ? AND ?',
      whereArgs: [startDateStr, endDateStr],
      orderBy: '${DatabaseConstants.columnFollowUpDate} ASC',
    );

    return maps.map((map) => FollowUp.fromMap(map)).toList();
  }

  // Get follow-ups by status
  Future<List<FollowUp>> getFollowUpsByStatus(FollowUpStatus status) async {
    final db = await _databaseHelper.database;
    
    final maps = await db.query(
      DatabaseConstants.tableFollowUps,
      where: '${DatabaseConstants.columnFollowUpStatus} = ?',
      whereArgs: [status.dbValue],
      orderBy: '${DatabaseConstants.columnFollowUpDate} DESC',
    );

    return maps.map((map) => FollowUp.fromMap(map)).toList();
  }

  // Get follow-ups by doctor name
  Future<List<FollowUp>> getFollowUpsByDoctor(String doctorName) async {
    final db = await _databaseHelper.database;
    
    final maps = await db.query(
      DatabaseConstants.tableFollowUps,
      where: '${DatabaseConstants.columnFollowUpDoctorName} LIKE ?',
      whereArgs: ['%$doctorName%'],
      orderBy: '${DatabaseConstants.columnFollowUpDate} DESC',
    );

    return maps.map((map) => FollowUp.fromMap(map)).toList();
  }

  // Get follow-ups by date range
  Future<List<FollowUp>> getFollowUpsByDateRange(DateTime startDate, DateTime endDate) async {
    final db = await _databaseHelper.database;
    
    // Convert dates to ISO strings for comparison
    final startDateStr = startDate.toIso8601String();
    final endDateStr = endDate.toIso8601String();
    
    final maps = await db.query(
      DatabaseConstants.tableFollowUps,
      where: '${DatabaseConstants.columnFollowUpDate} BETWEEN ? AND ?',
      whereArgs: [startDateStr, endDateStr],
      orderBy: '${DatabaseConstants.columnFollowUpDate} ASC',
    );

    return maps.map((map) => FollowUp.fromMap(map)).toList();
  }

  // Get follow-ups for a specific month
  Future<List<FollowUp>> getFollowUpsForMonth(int year, int month) async {
    final startDate = DateTime(year, month, 1);
    final endDate = month < 12 
      ? DateTime(year, month + 1, 1).subtract(const Duration(days: 1))
      : DateTime(year + 1, 1, 1).subtract(const Duration(days: 1));
    
    return getFollowUpsByDateRange(startDate, endDate);
  }

  // Get follow-ups for current month
  Future<List<FollowUp>> getFollowUpsForCurrentMonth() async {
    final now = DateTime.now();
    return getFollowUpsForMonth(now.year, now.month);
  }

  // Update follow-up
  Future<int> updateFollowUp(FollowUp followUp) async {
    final db = await _databaseHelper.database;
    return await db.update(
      DatabaseConstants.tableFollowUps,
      followUp.toMap(),
      where: '${DatabaseConstants.columnId} = ?',
      whereArgs: [followUp.id],
    );
  }

  // Update follow-up status
  Future<int> updateFollowUpStatus(String id, FollowUpStatus status, {DateTime? completedAt}) async {
    final db = await _databaseHelper.database;
    
    final updateData = <String, dynamic>{
      DatabaseConstants.columnFollowUpStatus: status.dbValue,
      DatabaseConstants.columnUpdatedAt: DateTime.now().toIso8601String(),
    };
    
    if (status == FollowUpStatus.completed && completedAt != null) {
      updateData[DatabaseConstants.columnFollowUpCompletedAt] = completedAt.toIso8601String();
    }
    
    return await db.update(
      DatabaseConstants.tableFollowUps,
      updateData,
      where: '${DatabaseConstants.columnId} = ?',
      whereArgs: [id],
    );
  }

  // Mark follow-up as completed
  Future<int> markFollowUpAsCompleted(String id) async {
    return updateFollowUpStatus(id, FollowUpStatus.completed, completedAt: DateTime.now());
  }

  // Delete follow-up by ID
  Future<int> deleteFollowUpById(String id) async {
    final db = await _databaseHelper.database;
    return await db.delete(
      DatabaseConstants.tableFollowUps,
      where: '${DatabaseConstants.columnId} = ?',
      whereArgs: [id],
    );
  }

  // Delete all follow-ups
  Future<int> deleteAllFollowUps() async {
    final db = await _databaseHelper.database;
    return await db.delete(DatabaseConstants.tableFollowUps);
  }

  // Search follow-ups
  Future<List<FollowUp>> searchFollowUps(String query) async {
    final db = await _databaseHelper.database;
    final maps = await db.query(
      DatabaseConstants.tableFollowUps,
      where: '''
        ${DatabaseConstants.columnFollowUpTitle} LIKE ? OR
        ${DatabaseConstants.columnFollowUpDoctorName} LIKE ? OR
        ${DatabaseConstants.columnFollowUpClinicName} LIKE ? OR
        ${DatabaseConstants.columnFollowUpLocation} LIKE ? OR
        ${DatabaseConstants.columnFollowUpNotes} LIKE ?
      ''',
      whereArgs: ['%$query%', '%$query%', '%$query%', '%$query%', '%$query%'],
      orderBy: '${DatabaseConstants.columnFollowUpDate} DESC',
    );

    return maps.map((map) => FollowUp.fromMap(map)).toList();
  }

  // Get follow-up count
  Future<int> getFollowUpCount({FollowUpStatus? status}) async {
    final db = await _databaseHelper.database;
    
    String whereClause = '';
    List<Object?> whereArgs = [];
    
    if (status != null) {
      whereClause = '${DatabaseConstants.columnFollowUpStatus} = ?';
      whereArgs.add(status.dbValue);
    }
    
    final count = Sqflite.firstIntValue(
      await db.rawQuery(
        '''
        SELECT COUNT(*) FROM ${DatabaseConstants.tableFollowUps}
        ${whereClause.isNotEmpty ? 'WHERE $whereClause' : ''}
        ''',
        whereArgs.isNotEmpty ? whereArgs : null,
      )
    );
    
    return count ?? 0;
  }

  // Get follow-ups due in next N days
  Future<List<FollowUp>> getFollowUpsDueInNextNDays(int days) async {
    final now = DateTime.now();
    final endDate = now.add(Duration(days: days));
    
    final db = await _databaseHelper.database;
    final nowStr = now.toIso8601String();
    final endDateStr = endDate.toIso8601String();
    
    final maps = await db.query(
      DatabaseConstants.tableFollowUps,
      where: '''
        ${DatabaseConstants.columnFollowUpDate} BETWEEN ? AND ? AND
        ${DatabaseConstants.columnFollowUpStatus} = ?
      ''',
      whereArgs: [nowStr, endDateStr, FollowUpStatus.scheduled.dbValue],
      orderBy: '${DatabaseConstants.columnFollowUpDate} ASC',
    );

    return maps.map((map) => FollowUp.fromMap(map)).toList();
  }

  // Get follow-ups for the last N days
  Future<List<FollowUp>> getFollowUpsForLastNDays(int days) async {
    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: days));
    
    final db = await _databaseHelper.database;
    final startDateStr = startDate.toIso8601String();
    final nowStr = now.toIso8601String();
    
    final maps = await db.query(
      DatabaseConstants.tableFollowUps,
      where: '${DatabaseConstants.columnFollowUpDate} BETWEEN ? AND ?',
      whereArgs: [startDateStr, nowStr],
      orderBy: '${DatabaseConstants.columnFollowUpDate} DESC',
    );

    return maps.map((map) => FollowUp.fromMap(map)).toList();
  }

  // Get follow-ups grouped by month
  Future<Map<String, List<FollowUp>>> getFollowUpsGroupedByMonth() async {
    final followUps = await getAllFollowUps(orderBy: '${DatabaseConstants.columnFollowUpDate} ASC');
    final grouped = <String, List<FollowUp>>{};
    
    for (final followUp in followUps) {
      final monthKey = '${followUp.date.year}-${followUp.date.month.toString().padLeft(2, '0')}';
      if (!grouped.containsKey(monthKey)) {
        grouped[monthKey] = [];
      }
      grouped[monthKey]!.add(followUp);
    }
    
    return grouped;
  }

  // Get follow-ups grouped by doctor
  Future<Map<String, List<FollowUp>>> getFollowUpsGroupedByDoctor() async {
    final followUps = await getAllFollowUps(orderBy: '${DatabaseConstants.columnFollowUpDoctorName} ASC');
    final grouped = <String, List<FollowUp>>{};
    
    for (final followUp in followUps) {
      final doctorName = followUp.doctorName ?? 'Unknown Doctor';
      if (!grouped.containsKey(doctorName)) {
        grouped[doctorName] = [];
      }
      grouped[doctorName]!.add(followUp);
    }
    
    return grouped;
  }

  // Get follow-ups grouped by status
  Future<Map<String, List<FollowUp>>> getFollowUpsGroupedByStatus() async {
    final followUps = await getAllFollowUps();
    final grouped = <String, List<FollowUp>>{};
    
    for (final followUp in followUps) {
      final statusKey = followUp.status.displayName;
      if (!grouped.containsKey(statusKey)) {
        grouped[statusKey] = [];
      }
      grouped[statusKey]!.add(followUp);
    }
    
    return grouped;
  }

  // Batch insert follow-ups
  Future<void> batchInsertFollowUps(List<FollowUp> followUps) async {
    final db = await _databaseHelper.database;
    final batch = db.batch();
    
    for (final followUp in followUps) {
      batch.insert(
        DatabaseConstants.tableFollowUps,
        followUp.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    
    await batch.commit(noResult: true);
  }

  // Update multiple follow-ups
  Future<void> batchUpdateFollowUps(List<FollowUp> followUps) async {
    final db = await _databaseHelper.database;
    final batch = db.batch();
    
    for (final followUp in followUps) {
      batch.update(
        DatabaseConstants.tableFollowUps,
        followUp.toMap(),
        where: '${DatabaseConstants.columnId} = ?',
        whereArgs: [followUp.id],
      );
    }
    
    await batch.commit(noResult: true);
  }

  // Get follow-up statistics
  Future<Map<String, int>> getFollowUpStatistics() async {
    final db = await _databaseHelper.database;
    
    final total = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM ${DatabaseConstants.tableFollowUps}')
    ) ?? 0;
    
    final scheduled = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM ${DatabaseConstants.tableFollowUps} WHERE ${DatabaseConstants.columnFollowUpStatus} = ?',
        [FollowUpStatus.scheduled.dbValue],
      )
    ) ?? 0;
    
    final completed = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM ${DatabaseConstants.tableFollowUps} WHERE ${DatabaseConstants.columnFollowUpStatus} = ?',
        [FollowUpStatus.completed.dbValue],
      )
    ) ?? 0;
    
    final cancelled = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM ${DatabaseConstants.tableFollowUps} WHERE ${DatabaseConstants.columnFollowUpStatus} = ?',
        [FollowUpStatus.cancelled.dbValue],
      )
    ) ?? 0;
    
    final rescheduled = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM ${DatabaseConstants.tableFollowUps} WHERE ${DatabaseConstants.columnFollowUpStatus} = ?',
        [FollowUpStatus.rescheduled.dbValue],
      )
    ) ?? 0;
    
    return {
      'total': total,
      'scheduled': scheduled,
      'completed': completed,
      'cancelled': cancelled,
      'rescheduled': rescheduled,
    };
  }

  // Get next follow-up (closest upcoming scheduled follow-up)
  Future<FollowUp?> getNextFollowUp() async {
    final upcoming = await getUpcomingFollowUps(limit: 1);
    return upcoming.isNotEmpty ? upcoming.first : null;
  }
}