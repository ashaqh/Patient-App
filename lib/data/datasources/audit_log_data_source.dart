import 'dart:async';
import 'package:sqflite/sqflite.dart';

import 'database_helper.dart';
import 'database_constants.dart';
import '../../domain/entities/audit_log.dart';
import '../../core/services/database_encryption_service.dart';

class AuditLogDataSource {
  final DatabaseHelper _databaseHelper;
  final DatabaseEncryptionService _encryptionService;

  AuditLogDataSource(this._databaseHelper)
      : _encryptionService = DatabaseEncryptionService();

  // Create a new audit log entry
  Future<String> createAuditLog(AuditLog auditLog) async {
    final db = await _databaseHelper.database;
    final auditLogMap = auditLog.toMap();
    
    // Encrypt sensitive fields before storage
    final encryptedMap = await _encryptionService.encryptAuditLog(auditLogMap);
    
    await db.insert(
      DatabaseConstants.tableAuditLogs,
      encryptedMap,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return auditLog.id;
  }

  // Get audit log by ID
  Future<AuditLog?> getAuditLogById(String id) async {
    final db = await _databaseHelper.database;
    final maps = await db.query(
      DatabaseConstants.tableAuditLogs,
      where: '${DatabaseConstants.columnId} = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      final auditLogMap = maps.first;
      
      // Decrypt sensitive fields after retrieval
      final decryptedMap = await _encryptionService.decryptAuditLog(auditLogMap);
      
      return AuditLog.fromMap(decryptedMap);
    }
    return null;
  }

  // Get all audit logs with pagination
  Future<List<AuditLog>> getAllAuditLogs({
    int? limit,
    int? offset,
    bool? descending,
  }) async {
    final db = await _databaseHelper.database;
    
    String orderBy = '${DatabaseConstants.columnAuditLogTimestamp}';
    if (descending ?? true) {
      orderBy += ' DESC';
    }
    
    final maps = await db.query(
      DatabaseConstants.tableAuditLogs,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );

    // Decrypt sensitive fields for all audit logs
    final decryptedMaps = await _encryptionService.batchDecryptAuditLogs(maps);
    
    return decryptedMaps.map((map) => AuditLog.fromMap(map)).toList();
  }

  // Get audit logs by user ID
  Future<List<AuditLog>> getAuditLogsByUserId(
    String userId, {
    int? limit,
    int? offset,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await _databaseHelper.database;
    
    final where = <String>[];
    final whereArgs = <dynamic>[userId];
    
    where.add('${DatabaseConstants.columnAuditLogUserId} = ?');
    
    if (startDate != null) {
      where.add('${DatabaseConstants.columnAuditLogTimestamp} >= ?');
      whereArgs.add(startDate.toIso8601String());
    }
    
    if (endDate != null) {
      where.add('${DatabaseConstants.columnAuditLogTimestamp} <= ?');
      whereArgs.add(endDate.toIso8601String());
    }
    
    final maps = await db.query(
      DatabaseConstants.tableAuditLogs,
      where: where.join(' AND '),
      whereArgs: whereArgs,
      orderBy: '${DatabaseConstants.columnAuditLogTimestamp} DESC',
      limit: limit,
      offset: offset,
    );

    final decryptedMaps = await _encryptionService.batchDecryptAuditLogs(maps);
    return decryptedMaps.map((map) => AuditLog.fromMap(map)).toList();
  }

  // Get audit logs by resource type
  Future<List<AuditLog>> getAuditLogsByResourceType(
    AuditLogResourceType resourceType, {
    int? limit,
    int? offset,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await _databaseHelper.database;
    
    final where = <String>[];
    final whereArgs = <dynamic>[resourceType.name];
    
    where.add('${DatabaseConstants.columnAuditLogResourceType} = ?');
    
    if (startDate != null) {
      where.add('${DatabaseConstants.columnAuditLogTimestamp} >= ?');
      whereArgs.add(startDate.toIso8601String());
    }
    
    if (endDate != null) {
      where.add('${DatabaseConstants.columnAuditLogTimestamp} <= ?');
      whereArgs.add(endDate.toIso8601String());
    }
    
    final maps = await db.query(
      DatabaseConstants.tableAuditLogs,
      where: where.join(' AND '),
      whereArgs: whereArgs,
      orderBy: '${DatabaseConstants.columnAuditLogTimestamp} DESC',
      limit: limit,
      offset: offset,
    );

    final decryptedMaps = await _encryptionService.batchDecryptAuditLogs(maps);
    return decryptedMaps.map((map) => AuditLog.fromMap(map)).toList();
  }

  // Get audit logs by action type
  Future<List<AuditLog>> getAuditLogsByAction(
    AuditLogAction action, {
    int? limit,
    int? offset,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await _databaseHelper.database;
    
    final where = <String>[];
    final whereArgs = <dynamic>[action.name];
    
    where.add('${DatabaseConstants.columnAuditLogAction} = ?');
    
    if (startDate != null) {
      where.add('${DatabaseConstants.columnAuditLogTimestamp} >= ?');
      whereArgs.add(startDate.toIso8601String());
    }
    
    if (endDate != null) {
      where.add('${DatabaseConstants.columnAuditLogTimestamp} <= ?');
      whereArgs.add(endDate.toIso8601String());
    }
    
    final maps = await db.query(
      DatabaseConstants.tableAuditLogs,
      where: where.join(' AND '),
      whereArgs: whereArgs,
      orderBy: '${DatabaseConstants.columnAuditLogTimestamp} DESC',
      limit: limit,
      offset: offset,
    );

    final decryptedMaps = await _encryptionService.batchDecryptAuditLogs(maps);
    return decryptedMaps.map((map) => AuditLog.fromMap(map)).toList();
  }

  // Get audit logs by severity
  Future<List<AuditLog>> getAuditLogsBySeverity(
    AuditLogSeverity severity, {
    int? limit,
    int? offset,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await _databaseHelper.database;
    
    final where = <String>[];
    final whereArgs = <dynamic>[severity.name];
    
    where.add('${DatabaseConstants.columnAuditLogSeverity} = ?');
    
    if (startDate != null) {
      where.add('${DatabaseConstants.columnAuditLogTimestamp} >= ?');
      whereArgs.add(startDate.toIso8601String());
    }
    
    if (endDate != null) {
      where.add('${DatabaseConstants.columnAuditLogTimestamp} <= ?');
      whereArgs.add(endDate.toIso8601String());
    }
    
    final maps = await db.query(
      DatabaseConstants.tableAuditLogs,
      where: where.join(' AND '),
      whereArgs: whereArgs,
      orderBy: '${DatabaseConstants.columnAuditLogTimestamp} DESC',
      limit: limit,
      offset: offset,
    );

    final decryptedMaps = await _encryptionService.batchDecryptAuditLogs(maps);
    return decryptedMaps.map((map) => AuditLog.fromMap(map)).toList();
  }

  // Get audit logs that require review
  Future<List<AuditLog>> getAuditLogsRequiringReview({
    int? limit,
    int? offset,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await _databaseHelper.database;
    
    final where = <String>[];
    final whereArgs = <dynamic>[];
    
    where.add('(${DatabaseConstants.columnAuditLogSuccess} = 0 OR '
        '${DatabaseConstants.columnAuditLogSeverity} = ?)');
    whereArgs.add(AuditLogSeverity.security.name);
    
    if (startDate != null) {
      where.add('${DatabaseConstants.columnAuditLogTimestamp} >= ?');
      whereArgs.add(startDate.toIso8601String());
    }
    
    if (endDate != null) {
      where.add('${DatabaseConstants.columnAuditLogTimestamp} <= ?');
      whereArgs.add(endDate.toIso8601String());
    }
    
    final maps = await db.query(
      DatabaseConstants.tableAuditLogs,
      where: where.join(' AND '),
      whereArgs: whereArgs,
      orderBy: '${DatabaseConstants.columnAuditLogTimestamp} DESC',
      limit: limit,
      offset: offset,
    );

    final decryptedMaps = await _encryptionService.batchDecryptAuditLogs(maps);
    return decryptedMaps.map((map) => AuditLog.fromMap(map)).toList();
  }

  // Get audit logs for data export (HIPAA compliance)
  Future<List<AuditLog>> getDataAccessAuditLogs({
    int? limit,
    int? offset,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await _databaseHelper.database;
    
    final where = <String>[];
    final whereArgs = <dynamic>[];
    
    // Filter for data access actions (create, read, update, delete, export)
    final dataAccessActions = [
      AuditLogAction.create,
      AuditLogAction.read,
      AuditLogAction.update,
      AuditLogAction.delete,
      AuditLogAction.export,
    ];
    
    where.add('${DatabaseConstants.columnAuditLogAction} IN ('
        '${dataAccessActions.map((a) => "'${a.name}'").join(',')})');
    
    // Filter for sensitive resource types
    final sensitiveResources = [
      AuditLogResourceType.vitalSign,
      AuditLogResourceType.medicine,
      AuditLogResourceType.prescription,
      AuditLogResourceType.patientProfile,
    ];
    
    where.add('${DatabaseConstants.columnAuditLogResourceType} IN ('
        '${sensitiveResources.map((r) => "'${r.name}'").join(',')})');
    
    if (startDate != null) {
      where.add('${DatabaseConstants.columnAuditLogTimestamp} >= ?');
      whereArgs.add(startDate.toIso8601String());
    }
    
    if (endDate != null) {
      where.add('${DatabaseConstants.columnAuditLogTimestamp} <= ?');
      whereArgs.add(endDate.toIso8601String());
    }
    
    final maps = await db.query(
      DatabaseConstants.tableAuditLogs,
      where: where.join(' AND '),
      whereArgs: whereArgs,
      orderBy: '${DatabaseConstants.columnAuditLogTimestamp} DESC',
      limit: limit,
      offset: offset,
    );

    final decryptedMaps = await _encryptionService.batchDecryptAuditLogs(maps);
    return decryptedMaps.map((map) => AuditLog.fromMap(map)).toList();
  }

  // Get audit statistics for reporting
  Future<Map<String, dynamic>> getAuditStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await _databaseHelper.database;
    
    final where = <String>[];
    final whereArgs = <dynamic>[];
    
    if (startDate != null) {
      where.add('${DatabaseConstants.columnAuditLogTimestamp} >= ?');
      whereArgs.add(startDate.toIso8601String());
    }
    
    if (endDate != null) {
      where.add('${DatabaseConstants.columnAuditLogTimestamp} <= ?');
      whereArgs.add(endDate.toIso8601String());
    }
    
    final whereClause = where.isNotEmpty ? 'WHERE ${where.join(' AND ')}' : '';
    
    // Get total count
    final totalResult = await db.rawQuery('''
      SELECT COUNT(*) as count FROM ${DatabaseConstants.tableAuditLogs} $whereClause
    ''', whereArgs);
    final totalCount = totalResult.first['count'] as int? ?? 0;
    
    // Get success/failure count
    final successResult = await db.rawQuery('''
      SELECT 
        COUNT(CASE WHEN ${DatabaseConstants.columnAuditLogSuccess} = 1 THEN 1 END) as success_count,
        COUNT(CASE WHEN ${DatabaseConstants.columnAuditLogSuccess} = 0 THEN 1 END) as failure_count
      FROM ${DatabaseConstants.tableAuditLogs} $whereClause
    ''', whereArgs);
    final successCount = successResult.first['success_count'] as int? ?? 0;
    final failureCount = successResult.first['failure_count'] as int? ?? 0;
    
    // Get action distribution
    final actionResult = await db.rawQuery('''
      SELECT 
        ${DatabaseConstants.columnAuditLogAction},
        COUNT(*) as count
      FROM ${DatabaseConstants.tableAuditLogs} $whereClause
      GROUP BY ${DatabaseConstants.columnAuditLogAction}
      ORDER BY count DESC
    ''', whereArgs);
    
    // Get resource type distribution
    final resourceResult = await db.rawQuery('''
      SELECT 
        ${DatabaseConstants.columnAuditLogResourceType},
        COUNT(*) as count
      FROM ${DatabaseConstants.tableAuditLogs} $whereClause
      GROUP BY ${DatabaseConstants.columnAuditLogResourceType}
      ORDER BY count DESC
    ''', whereArgs);
    
    // Get user activity
    final userResult = await db.rawQuery('''
      SELECT 
        ${DatabaseConstants.columnAuditLogUserId},
        ${DatabaseConstants.columnAuditLogUserRole},
        COUNT(*) as activity_count
      FROM ${DatabaseConstants.tableAuditLogs} $whereClause
      GROUP BY ${DatabaseConstants.columnAuditLogUserId}
      ORDER BY activity_count DESC
      LIMIT 10
    ''', whereArgs);
    
    return {
      'total_events': totalCount,
      'successful_events': successCount,
      'failed_events': failureCount,
      'success_rate': totalCount > 0 ? (successCount / totalCount * 100) : 0,
      'action_distribution': actionResult.map((row) => {
        'action': row[DatabaseConstants.columnAuditLogAction],
        'count': row['count'],
      }).toList(),
      'resource_distribution': resourceResult.map((row) => {
        'resource_type': row[DatabaseConstants.columnAuditLogResourceType],
        'count': row['count'],
      }).toList(),
      'top_users': userResult.map((row) => {
        'user_id': row[DatabaseConstants.columnAuditLogUserId],
        'user_role': row[DatabaseConstants.columnAuditLogUserRole],
        'activity_count': row['activity_count'],
      }).toList(),
    };
  }

  // Delete audit logs older than specified date (for retention policy)
  Future<int> deleteOldAuditLogs(DateTime cutoffDate) async {
    final db = await _databaseHelper.database;
    
    return await db.delete(
      DatabaseConstants.tableAuditLogs,
      where: '${DatabaseConstants.columnAuditLogTimestamp} < ?',
      whereArgs: [cutoffDate.toIso8601String()],
    );
  }

  // Get audit log count for monitoring
  Future<int> getAuditLogCount({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await _databaseHelper.database;
    
    final where = <String>[];
    final whereArgs = <dynamic>[];
    
    if (startDate != null) {
      where.add('${DatabaseConstants.columnAuditLogTimestamp} >= ?');
      whereArgs.add(startDate.toIso8601String());
    }
    
    if (endDate != null) {
      where.add('${DatabaseConstants.columnAuditLogTimestamp} <= ?');
      whereArgs.add(endDate.toIso8601String());
    }
    
    final maps = await db.query(
      DatabaseConstants.tableAuditLogs,
      columns: ['COUNT(*) as count'],
      where: where.isNotEmpty ? where.join(' AND ') : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
    );
    
    return maps.first['count'] as int? ?? 0;
  }
}