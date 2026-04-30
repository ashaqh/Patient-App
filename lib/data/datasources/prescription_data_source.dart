import 'dart:async';
import 'package:sqflite/sqflite.dart';

import 'database_helper.dart';
import 'database_constants.dart';
import '../../domain/entities/prescription.dart';

class PrescriptionDataSource {
  final DatabaseHelper _databaseHelper;

  PrescriptionDataSource(this._databaseHelper);

  // Create a new prescription
  Future<String> createPrescription(Prescription prescription) async {
    final db = await _databaseHelper.database;
    await db.insert(
      DatabaseConstants.tablePrescriptions,
      prescription.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return prescription.id;
  }

  // Get prescription by ID
  Future<Prescription?> getPrescriptionById(String id) async {
    final db = await _databaseHelper.database;
    final maps = await db.query(
      DatabaseConstants.tablePrescriptions,
      where: '${DatabaseConstants.columnId} = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Prescription.fromMap(maps.first);
    }
    return null;
  }

  // Get all prescriptions
  Future<List<Prescription>> getAllPrescriptions({String? orderBy}) async {
    final db = await _databaseHelper.database;
    
    final maps = await db.query(
      DatabaseConstants.tablePrescriptions,
      orderBy: orderBy ?? '${DatabaseConstants.columnPrescriptionDate} DESC',
    );

    return maps.map((map) => Prescription.fromMap(map)).toList();
  }

  // Get prescriptions by date range
  Future<List<Prescription>> getPrescriptionsByDateRange(DateTime startDate, DateTime endDate) async {
    final db = await _databaseHelper.database;
    
    // Convert dates to ISO strings for comparison
    final startDateStr = startDate.toIso8601String();
    final endDateStr = endDate.toIso8601String();
    
    final maps = await db.query(
      DatabaseConstants.tablePrescriptions,
      where: '${DatabaseConstants.columnPrescriptionDate} BETWEEN ? AND ?',
      whereArgs: [startDateStr, endDateStr],
      orderBy: '${DatabaseConstants.columnPrescriptionDate} DESC',
    );

    return maps.map((map) => Prescription.fromMap(map)).toList();
  }

  // Get prescriptions by doctor name
  Future<List<Prescription>> getPrescriptionsByDoctor(String doctorName) async {
    final db = await _databaseHelper.database;
    
    final maps = await db.query(
      DatabaseConstants.tablePrescriptions,
      where: '${DatabaseConstants.columnPrescriptionDoctorName} LIKE ?',
      whereArgs: ['%$doctorName%'],
      orderBy: '${DatabaseConstants.columnPrescriptionDate} DESC',
    );

    return maps.map((map) => Prescription.fromMap(map)).toList();
  }

  // Get recent prescriptions
  Future<List<Prescription>> getRecentPrescriptions({int limit = 10}) async {
    final db = await _databaseHelper.database;
    
    final maps = await db.query(
      DatabaseConstants.tablePrescriptions,
      orderBy: '${DatabaseConstants.columnPrescriptionDate} DESC',
      limit: limit,
    );

    return maps.map((map) => Prescription.fromMap(map)).toList();
  }

  // Update prescription
  Future<int> updatePrescription(Prescription prescription) async {
    final db = await _databaseHelper.database;
    return await db.update(
      DatabaseConstants.tablePrescriptions,
      prescription.toMap(),
      where: '${DatabaseConstants.columnId} = ?',
      whereArgs: [prescription.id],
    );
  }

  // Delete prescription by ID
  Future<int> deletePrescriptionById(String id) async {
    final db = await _databaseHelper.database;
    return await db.delete(
      DatabaseConstants.tablePrescriptions,
      where: '${DatabaseConstants.columnId} = ?',
      whereArgs: [id],
    );
  }

  // Delete all prescriptions
  Future<int> deleteAllPrescriptions() async {
    final db = await _databaseHelper.database;
    return await db.delete(DatabaseConstants.tablePrescriptions);
  }

  // Search prescriptions
  Future<List<Prescription>> searchPrescriptions(String query) async {
    final db = await _databaseHelper.database;
    final maps = await db.query(
      DatabaseConstants.tablePrescriptions,
      where: '''
        ${DatabaseConstants.columnPrescriptionFileName} LIKE ? OR
        ${DatabaseConstants.columnPrescriptionDoctorName} LIKE ? OR
        ${DatabaseConstants.columnPrescriptionNotes} LIKE ?
      ''',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      orderBy: '${DatabaseConstants.columnPrescriptionDate} DESC',
    );

    return maps.map((map) => Prescription.fromMap(map)).toList();
  }

  // Get prescription count
  Future<int> getPrescriptionCount() async {
    final db = await _databaseHelper.database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM ${DatabaseConstants.tablePrescriptions}')
    );
    return count ?? 0;
  }

  // Get prescriptions by file type
  Future<List<Prescription>> getPrescriptionsByFileType(String fileType) async {
    final db = await _databaseHelper.database;
    
    final maps = await db.query(
      DatabaseConstants.tablePrescriptions,
      where: '${DatabaseConstants.columnPrescriptionFileType} LIKE ?',
      whereArgs: ['%$fileType%'],
      orderBy: '${DatabaseConstants.columnPrescriptionDate} DESC',
    );

    return maps.map((map) => Prescription.fromMap(map)).toList();
  }

  // Get image prescriptions
  Future<List<Prescription>> getImagePrescriptions() async {
    final allPrescriptions = await getAllPrescriptions();
    return allPrescriptions.where((p) => p.isImage).toList();
  }

  // Get PDF prescriptions
  Future<List<Prescription>> getPdfPrescriptions() async {
    final allPrescriptions = await getAllPrescriptions();
    return allPrescriptions.where((p) => p.isPdf).toList();
  }

  // Get document prescriptions
  Future<List<Prescription>> getDocumentPrescriptions() async {
    final allPrescriptions = await getAllPrescriptions();
    return allPrescriptions.where((p) => p.isDocument).toList();
  }

  // Get prescriptions for a specific month
  Future<List<Prescription>> getPrescriptionsForMonth(int year, int month) async {
    final startDate = DateTime(year, month, 1);
    final endDate = month < 12 
      ? DateTime(year, month + 1, 1).subtract(const Duration(days: 1))
      : DateTime(year + 1, 1, 1).subtract(const Duration(days: 1));
    
    return getPrescriptionsByDateRange(startDate, endDate);
  }

  // Get prescriptions for current month
  Future<List<Prescription>> getPrescriptionsForCurrentMonth() async {
    final now = DateTime.now();
    return getPrescriptionsForMonth(now.year, now.month);
  }

  // Batch insert prescriptions
  Future<void> batchInsertPrescriptions(List<Prescription> prescriptions) async {
    final db = await _databaseHelper.database;
    final batch = db.batch();
    
    for (final prescription in prescriptions) {
      batch.insert(
        DatabaseConstants.tablePrescriptions,
        prescription.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    
    await batch.commit(noResult: true);
  }

  // Update multiple prescriptions
  Future<void> batchUpdatePrescriptions(List<Prescription> prescriptions) async {
    final db = await _databaseHelper.database;
    final batch = db.batch();
    
    for (final prescription in prescriptions) {
      batch.update(
        DatabaseConstants.tablePrescriptions,
        prescription.toMap(),
        where: '${DatabaseConstants.columnId} = ?',
        whereArgs: [prescription.id],
      );
    }
    
    await batch.commit(noResult: true);
  }

  // Get prescriptions grouped by month
  Future<Map<String, List<Prescription>>> getPrescriptionsGroupedByMonth() async {
    final prescriptions = await getAllPrescriptions();
    final grouped = <String, List<Prescription>>{};
    
    for (final prescription in prescriptions) {
      final monthKey = '${prescription.date.year}-${prescription.date.month.toString().padLeft(2, '0')}';
      if (!grouped.containsKey(monthKey)) {
        grouped[monthKey] = [];
      }
      grouped[monthKey]!.add(prescription);
    }
    
    return grouped;
  }

  // Get prescriptions grouped by doctor
  Future<Map<String, List<Prescription>>> getPrescriptionsGroupedByDoctor() async {
    final prescriptions = await getAllPrescriptions();
    final grouped = <String, List<Prescription>>{};
    
    for (final prescription in prescriptions) {
      final doctorName = prescription.doctorName ?? 'Unknown Doctor';
      if (!grouped.containsKey(doctorName)) {
        grouped[doctorName] = [];
      }
      grouped[doctorName]!.add(prescription);
    }
    
    return grouped;
  }
}