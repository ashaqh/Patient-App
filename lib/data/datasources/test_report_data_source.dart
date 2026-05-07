import 'dart:async';
import 'package:sqflite/sqflite.dart';

import 'database_helper.dart';
import 'database_constants.dart';
import '../../domain/entities/test_report.dart';

class TestReportDataSource {
  final DatabaseHelper _databaseHelper;

  TestReportDataSource(this._databaseHelper);

  Future<String> createTestReport(TestReport report) async {
    final db = await _databaseHelper.database;
    await db.transaction((txn) async {
      await txn.insert(
        DatabaseConstants.tableTestReports,
        report.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await _databaseHelper.recordChange(
        txn, DatabaseConstants.tableTestReports, report.id, 'INSERT');
    });
    return report.id;
  }

  Future<TestReport?> getTestReportById(String id) async {
    final db = await _databaseHelper.database;
    final maps = await db.query(
      DatabaseConstants.tableTestReports,
      where: '${DatabaseConstants.columnId} = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return TestReport.fromMap(maps.first);
    }
    return null;
  }

  Future<List<TestReport>> getAllTestReports({String? orderBy}) async {
    final db = await _databaseHelper.database;

    final maps = await db.query(
      DatabaseConstants.tableTestReports,
      orderBy: orderBy ?? 'date DESC',
    );

    return maps.map((map) => TestReport.fromMap(map)).toList();
  }

  Future<List<TestReport>> getTestReportsByDateRange(DateTime startDate, DateTime endDate) async {
    final db = await _databaseHelper.database;

    final startDateStr = startDate.toIso8601String();
    final endDateStr = endDate.toIso8601String();

    final maps = await db.query(
      DatabaseConstants.tableTestReports,
      where: 'date BETWEEN ? AND ?',
      whereArgs: [startDateStr, endDateStr],
      orderBy: 'date DESC',
    );

    return maps.map((map) => TestReport.fromMap(map)).toList();
  }

  Future<List<TestReport>> getTestReportsByType(String reportType) async {
    final db = await _databaseHelper.database;

    final maps = await db.query(
      DatabaseConstants.tableTestReports,
      where: 'report_type = ?',
      whereArgs: [reportType],
      orderBy: 'date DESC',
    );

    return maps.map((map) => TestReport.fromMap(map)).toList();
  }

  Future<List<TestReport>> getTestReportsByLab(String labName) async {
    final db = await _databaseHelper.database;

    final maps = await db.query(
      DatabaseConstants.tableTestReports,
      where: 'lab_name LIKE ?',
      whereArgs: ['%$labName%'],
      orderBy: 'date DESC',
    );

    return maps.map((map) => TestReport.fromMap(map)).toList();
  }

  Future<List<TestReport>> getRecentTestReports({int limit = 10}) async {
    final db = await _databaseHelper.database;

    final maps = await db.query(
      DatabaseConstants.tableTestReports,
      orderBy: 'date DESC',
      limit: limit,
    );

    return maps.map((map) => TestReport.fromMap(map)).toList();
  }

  Future<int> updateTestReport(TestReport report) async {
    final db = await _databaseHelper.database;

    final updatedReport = report.copyWith(
      version: report.version + 1,
      lastModified: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    return await db.transaction((txn) async {
      final result = await txn.update(
        DatabaseConstants.tableTestReports,
        updatedReport.toMap(),
        where: '${DatabaseConstants.columnId} = ?',
        whereArgs: [updatedReport.id],
      );
      await _databaseHelper.recordChange(
        txn, DatabaseConstants.tableTestReports, updatedReport.id, 'UPDATE');
      return result;
    });
  }

  Future<int> deleteTestReportById(String id) async {
    final db = await _databaseHelper.database;
    return await db.transaction((txn) async {
      final result = await txn.delete(
        DatabaseConstants.tableTestReports,
        where: '${DatabaseConstants.columnId} = ?',
        whereArgs: [id],
      );
      await _databaseHelper.recordChange(
        txn, DatabaseConstants.tableTestReports, id, 'DELETE');
      return result;
    });
  }

  Future<int> deleteAllTestReports() async {
    final db = await _databaseHelper.database;
    return await db.transaction((txn) async {
      final result = await txn.delete(DatabaseConstants.tableTestReports);
      await _databaseHelper.recordChange(
        txn, DatabaseConstants.tableTestReports, 'ALL', 'DELETE');
      return result;
    });
  }

  Future<List<TestReport>> searchTestReports(String query) async {
    final db = await _databaseHelper.database;
    final maps = await db.query(
      DatabaseConstants.tableTestReports,
      where: '''
      file_name LIKE ? OR
      test_name LIKE ? OR
      lab_name LIKE ? OR
      doctor_name LIKE ?
      ''',
      whereArgs: ['%$query%', '%$query%', '%$query%', '%$query%'],
      orderBy: 'date DESC',
    );

    return maps.map((map) => TestReport.fromMap(map)).toList();
  }

  Future<int> getTestReportCount() async {
    final db = await _databaseHelper.database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM ${DatabaseConstants.tableTestReports}')
    );
    return count ?? 0;
  }

  Future<List<TestReport>> getTestReportsForMonth(int year, int month) async {
    final startDate = DateTime(year, month, 1);
    final endDate = month < 12
        ? DateTime(year, month + 1, 1).subtract(const Duration(days: 1))
        : DateTime(year + 1, 1, 1).subtract(const Duration(days: 1));

    return getTestReportsByDateRange(startDate, endDate);
  }

  Future<List<TestReport>> getTestReportsForCurrentMonth() async {
    final now = DateTime.now();
    return getTestReportsForMonth(now.year, now.month);
  }

  Future<void> batchInsertTestReports(List<TestReport> reports) async {
    final db = await _databaseHelper.database;

    await db.transaction((txn) async {
      for (final report in reports) {
        await txn.insert(
          DatabaseConstants.tableTestReports,
          report.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        await _databaseHelper.recordChange(
          txn, DatabaseConstants.tableTestReports, report.id, 'INSERT');
      }
    });
  }

  Future<void> batchUpdateTestReports(List<TestReport> reports) async {
    final db = await _databaseHelper.database;

    await db.transaction((txn) async {
      for (var report in reports) {
        report = report.copyWith(
          version: report.version + 1,
          lastModified: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await txn.update(
          DatabaseConstants.tableTestReports,
          report.toMap(),
          where: '${DatabaseConstants.columnId} = ?',
          whereArgs: [report.id],
        );
        await _databaseHelper.recordChange(
          txn, DatabaseConstants.tableTestReports, report.id, 'UPDATE');
      }
    });
  }

  Future<Map<String, List<TestReport>>> getTestReportsGroupedByMonth() async {
    final reports = await getAllTestReports();
    final grouped = <String, List<TestReport>>{};

    for (final report in reports) {
      final monthKey = '${report.date.year}-${report.date.month.toString().padLeft(2, '0')}';
      if (!grouped.containsKey(monthKey)) {
        grouped[monthKey] = [];
      }
      grouped[monthKey]!.add(report);
    }

    return grouped;
  }

  Future<Map<String, List<TestReport>>> getTestReportsGroupedByLab() async {
    final reports = await getAllTestReports();
    final grouped = <String, List<TestReport>>{};

    for (final report in reports) {
      final labName = report.labName ?? 'Unknown Lab';
      if (!grouped.containsKey(labName)) {
        grouped[labName] = [];
      }
      grouped[labName]!.add(report);
    }

    return grouped;
  }

  Future<Map<String, List<TestReport>>> getTestReportsGroupedByType() async {
    final reports = await getAllTestReports();
    final grouped = <String, List<TestReport>>{};

    for (final report in reports) {
      final type = report.reportType;
      if (!grouped.containsKey(type)) {
        grouped[type] = [];
      }
      grouped[type]!.add(report);
    }

    return grouped;
  }
}
