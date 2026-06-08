import '../../domain/entities/audit_log.dart';
import '../../domain/repositories/audit_log_repository.dart';
import '../datasources/audit_log_data_source.dart';
import '../datasources/database_helper.dart';
import '../../core/utils/error_utils.dart';

class AuditLogRepositoryImpl implements AuditLogRepository {
  final AuditLogDataSource _auditLogDataSource;

  AuditLogRepositoryImpl(DatabaseHelper databaseHelper)
      : _auditLogDataSource = AuditLogDataSource(databaseHelper);

  @override
  Future<String> createAuditLog(AuditLog auditLog) {
    return _auditLogDataSource.createAuditLog(auditLog);
  }

  @override
  Future<AuditLog?> getAuditLogById(String id) {
    return _auditLogDataSource.getAuditLogById(id);
  }

  @override
  Future<List<AuditLog>> getAllAuditLogs({
    int? limit,
    int? offset,
    bool? descending,
  }) {
    return _auditLogDataSource.getAllAuditLogs(
      limit: limit,
      offset: offset,
      descending: descending,
    );
  }

  @override
  Future<List<AuditLog>> getAuditLogsByUserId(
    String userId, {
    int? limit,
    int? offset,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _auditLogDataSource.getAuditLogsByUserId(
      userId,
      limit: limit,
      offset: offset,
      startDate: startDate,
      endDate: endDate,
    );
  }

  @override
  Future<List<AuditLog>> getAuditLogsByResourceType(
    AuditLogResourceType resourceType, {
    int? limit,
    int? offset,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _auditLogDataSource.getAuditLogsByResourceType(
      resourceType,
      limit: limit,
      offset: offset,
      startDate: startDate,
      endDate: endDate,
    );
  }

  @override
  Future<List<AuditLog>> getAuditLogsByAction(
    AuditLogAction action, {
    int? limit,
    int? offset,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _auditLogDataSource.getAuditLogsByAction(
      action,
      limit: limit,
      offset: offset,
      startDate: startDate,
      endDate: endDate,
    );
  }

  @override
  Future<List<AuditLog>> getAuditLogsBySeverity(
    AuditLogSeverity severity, {
    int? limit,
    int? offset,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _auditLogDataSource.getAuditLogsBySeverity(
      severity,
      limit: limit,
      offset: offset,
      startDate: startDate,
      endDate: endDate,
    );
  }

  @override
  Future<List<AuditLog>> getAuditLogsRequiringReview({
    int? limit,
    int? offset,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _auditLogDataSource.getAuditLogsRequiringReview(
      limit: limit,
      offset: offset,
      startDate: startDate,
      endDate: endDate,
    );
  }

  @override
  Future<List<AuditLog>> getDataAccessAuditLogs({
    int? limit,
    int? offset,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _auditLogDataSource.getDataAccessAuditLogs(
      limit: limit,
      offset: offset,
      startDate: startDate,
      endDate: endDate,
    );
  }

  @override
  Future<Map<String, dynamic>> getAuditStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _auditLogDataSource.getAuditStatistics(
      startDate: startDate,
      endDate: endDate,
    );
  }

  @override
  Future<int> deleteOldAuditLogs(DateTime cutoffDate) {
    return _auditLogDataSource.deleteOldAuditLogs(cutoffDate);
  }

  @override
  Future<int> getAuditLogCount({
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _auditLogDataSource.getAuditLogCount(
      startDate: startDate,
      endDate: endDate,
    );
  }

  @override
  Future<List<Map<String, dynamic>>> getUserActivitySummary({
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    try {
      final db = await _auditLogDataSource.database;

      
      final where = <String>[];
      final whereArgs = <dynamic>[];
      
      if (startDate != null) {
        where.add('timestamp >= ?');
        whereArgs.add(startDate.toIso8601String());
      }
      
      if (endDate != null) {
        where.add('timestamp <= ?');
        whereArgs.add(endDate.toIso8601String());
      }
      
      final whereClause = where.isNotEmpty ? 'WHERE ${where.join(' AND ')}' : '';
      final limitClause = limit != null ? 'LIMIT $limit' : '';
      
      final result = await db.rawQuery('''
        SELECT 
          user_id,
          user_role,
          COUNT(*) as activity_count,
          SUM(CASE WHEN success = 1 THEN 1 ELSE 0 END) as success_count,
          SUM(CASE WHEN success = 0 THEN 1 ELSE 0 END) as failure_count,
          MIN(timestamp) as first_activity,
          MAX(timestamp) as last_activity
        FROM audit_logs
        $whereClause
        GROUP BY user_id
        ORDER BY activity_count DESC
        $limitClause
      ''', whereArgs);
      
      return result;
    } catch (e) {
      ErrorUtils.logError('Failed to get user activity summary: $e');
      rethrow;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getResourceAccessSummary({
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    try {
      final db = await _auditLogDataSource.database;

      
      final where = <String>[];
      final whereArgs = <dynamic>[];
      
      if (startDate != null) {
        where.add('timestamp >= ?');
        whereArgs.add(startDate.toIso8601String());
      }
      
      if (endDate != null) {
        where.add('timestamp <= ?');
        whereArgs.add(endDate.toIso8601String());
      }
      
      final whereClause = where.isNotEmpty ? 'WHERE ${where.join(' AND ')}' : '';
      final limitClause = limit != null ? 'LIMIT $limit' : '';
      
      final result = await db.rawQuery('''
        SELECT 
          resource_type,
          COUNT(*) as access_count,
          COUNT(DISTINCT user_id) as unique_users,
          SUM(CASE WHEN action = 'read' THEN 1 ELSE 0 END) as read_count,
          SUM(CASE WHEN action = 'create' THEN 1 ELSE 0 END) as create_count,
          SUM(CASE WHEN action = 'update' THEN 1 ELSE 0 END) as update_count,
          SUM(CASE WHEN action = 'delete' THEN 1 ELSE 0 END) as delete_count,
          SUM(CASE WHEN action = 'export' THEN 1 ELSE 0 END) as export_count
        FROM audit_logs
        $whereClause
        GROUP BY resource_type
        ORDER BY access_count DESC
        $limitClause
      ''', whereArgs);
      
      return result;
    } catch (e) {
      ErrorUtils.logError('Failed to get resource access summary: $e');
      rethrow;
    }
  }

  @override
  Future<List<AuditLog>> getSecurityIncidents({
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
    int? offset,
  }) async {
    try {
      final db = await _auditLogDataSource.database;

      
      final where = <String>[];
      final whereArgs = <dynamic>[];
      
      where.add('(success = 0 OR severity = ? OR action = ?)');
      whereArgs.addAll(['security', 'accessDenied']);
      
      if (startDate != null) {
        where.add('timestamp >= ?');
        whereArgs.add(startDate.toIso8601String());
      }
      
      if (endDate != null) {
        where.add('timestamp <= ?');
        whereArgs.add(endDate.toIso8601String());
      }
      
      final whereClause = where.join(' AND ');
      final limitClause = limit != null ? 'LIMIT $limit' : '';
      final offsetClause = offset != null ? 'OFFSET $offset' : '';
      
      final maps = await db.query(
        'audit_logs',
        where: whereClause,
        whereArgs: whereArgs,
        orderBy: 'timestamp DESC',
        limit: limit,
        offset: offset,
      );

      final decryptedMaps = await _auditLogDataSource.decryptAuditLogs(maps);

      return decryptedMaps.map((map) => AuditLog.fromMap(map)).toList();
    } catch (e) {
      ErrorUtils.logError('Failed to get security incidents: $e');
      rethrow;
    }
  }

  @override
  Future<String> exportAuditLogs({
    DateTime? startDate,
    DateTime? endDate,
    String format = 'json',
  }) {

    // Implementation for audit log export
    // This would typically generate CSV, JSON, or PDF files
    // For now, return a placeholder implementation
    throw UnimplementedError('Export functionality not yet implemented');
  }

  @override
  Future<int> archiveAuditLogs(DateTime cutoffDate) async {
    try {
      // In a real implementation, this would:
      // 1. Export logs to long-term storage
      // 2. Delete from primary database
      // 3. Update archive index
      
      // For now, just delete old logs (same as deleteOldAuditLogs)
      return await deleteOldAuditLogs(cutoffDate);
    } catch (e) {
      ErrorUtils.logError('Failed to archive audit logs: $e');
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> getRetentionStatus() async {
    try {
      final db = await _auditLogDataSource.database;

      
      // Get oldest and newest audit logs
      final oldestResult = await db.rawQuery('''
        SELECT timestamp FROM audit_logs ORDER BY timestamp ASC LIMIT 1
      ''');
      
      final newestResult = await db.rawQuery('''
        SELECT timestamp FROM audit_logs ORDER BY timestamp DESC LIMIT 1
      ''');
      
      final totalCount = await getAuditLogCount();
      
      DateTime? oldestDate;
      DateTime? newestDate;
      
      if (oldestResult.isNotEmpty) {
        oldestDate = DateTime.parse(oldestResult.first['timestamp'] as String);
      }
      
      if (newestResult.isNotEmpty) {
        newestDate = DateTime.parse(newestResult.first['timestamp'] as String);
      }
      
      // Calculate days to retention limit
      int? daysToRetentionLimit;
      if (oldestDate != null) {
        final retentionLimit = DateTime.now().subtract(const Duration(days: 2190)); // 6 years
        daysToRetentionLimit = retentionLimit.difference(oldestDate).inDays;
      }
      
      return {
        'total_logs': totalCount,
        'oldest_log_date': oldestDate?.toIso8601String(),
        'newest_log_date': newestDate?.toIso8601String(),
        'days_to_retention_limit': daysToRetentionLimit,
        'retention_period_days': 2190,
        'requires_cleanup': daysToRetentionLimit != null && daysToRetentionLimit < 0,
      };
    } catch (e) {
      ErrorUtils.logError('Failed to get retention status: $e');
      rethrow;
    }
  }

  @override
  Future<bool> validateAuditLogIntegrity() async {
    try {
      final db = await _auditLogDataSource.database;

      
      // Check for missing required fields
      final integrityCheck = await db.rawQuery('''
        SELECT COUNT(*) as invalid_count FROM audit_logs 
        WHERE user_id IS NULL OR user_role IS NULL OR timestamp IS NULL
      ''');
      
      final invalidCount = integrityCheck.first['invalid_count'] as int? ?? 0;
      
      // Check for duplicate IDs
      final duplicateCheck = await db.rawQuery('''
        SELECT id, COUNT(*) as count FROM audit_logs GROUP BY id HAVING COUNT(*) > 1
      ''');
      
      final duplicateCount = duplicateCheck.length;
      
      return invalidCount == 0 && duplicateCount == 0;
    } catch (e) {
      ErrorUtils.logError('Failed to validate audit log integrity: $e');
      return false;
    }
  }

  @override
  Future<Map<String, dynamic>> getSystemHealthMetrics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final statistics = await getAuditStatistics(startDate: startDate, endDate: endDate);
      final retentionStatus = await getRetentionStatus();
      final integrityValid = await validateAuditLogIntegrity();
      
      return {
        'audit_statistics': statistics,
        'retention_status': retentionStatus,
        'integrity_valid': integrityValid,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      ErrorUtils.logError('Failed to get system health metrics: $e');
      rethrow;
    }
  }

  @override
  Future<int> clearAllAuditLogs() async {
    try {
      final db = await _auditLogDataSource.database;

      return await db.delete('audit_logs');
    } catch (e) {
      ErrorUtils.logError('Failed to clear all audit logs: $e');
      rethrow;
    }
  }

  @override
  Future<void> batchCreateAuditLogs(List<AuditLog> auditLogs) async {
    try {
      final db = await _auditLogDataSource.database;

      await db.transaction((txn) async {
        for (final auditLog in auditLogs) {
          final auditLogMap = auditLog.toMap();
          final encryptedMap = await _auditLogDataSource.encryptAuditLog(auditLogMap);

          await txn.insert('audit_logs', encryptedMap);
        }
      });
    } catch (e) {
      ErrorUtils.logError('Failed to batch create audit logs: $e');
      rethrow;
    }
  }

  @override
  Future<List<AuditLog>> searchAuditLogs({
    String? userId,
    AuditLogResourceType? resourceType,
    AuditLogAction? action,
    AuditLogSeverity? severity,
    bool? success,
    String? sessionId,
    DateTime? startDate,
    DateTime? endDate,
    String? keyword,
    int? limit,
    int? offset,
  }) async {
    try {
      final db = await _auditLogDataSource.database;

      
      final where = <String>[];
      final whereArgs = <dynamic>[];
      
      if (userId != null) {
        where.add('user_id = ?');
        whereArgs.add(userId);
      }
      
      if (resourceType != null) {
        where.add('resource_type = ?');
        whereArgs.add(resourceType.name);
      }
      
      if (action != null) {
        where.add('action = ?');
        whereArgs.add(action.name);
      }
      
      if (severity != null) {
        where.add('severity = ?');
        whereArgs.add(severity.name);
      }
      
      if (success != null) {
        where.add('success = ?');
        whereArgs.add(success ? 1 : 0);
      }
      
      if (sessionId != null) {
        where.add('session_id = ?');
        whereArgs.add(sessionId);
      }
      
      if (startDate != null) {
        where.add('timestamp >= ?');
        whereArgs.add(startDate.toIso8601String());
      }
      
      if (endDate != null) {
        where.add('timestamp <= ?');
        whereArgs.add(endDate.toIso8601String());
      }
      
      // Keyword search (searches in details and error_message)
      if (keyword != null && keyword.isNotEmpty) {
        where.add('(details LIKE ? OR error_message LIKE ?)');
        whereArgs.addAll(['%$keyword%', '%$keyword%']);
      }
      
      final whereClause = where.isNotEmpty ? where.join(' AND ') : null;
      
      final maps = await db.query(
        'audit_logs',
        where: whereClause,
        whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
        orderBy: 'timestamp DESC',
        limit: limit,
        offset: offset,
      );

      final decryptedMaps = await _auditLogDataSource.decryptAuditLogs(maps);

      return decryptedMaps.map((map) => AuditLog.fromMap(map)).toList();
    } catch (e) {
      ErrorUtils.logError('Failed to search audit logs: $e');
      rethrow;
    }
  }
}
