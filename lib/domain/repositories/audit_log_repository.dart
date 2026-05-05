import '../entities/audit_log.dart';

abstract class AuditLogRepository {
  // Create a new audit log entry
  Future<String> createAuditLog(AuditLog auditLog);
  
  // Get audit log by ID
  Future<AuditLog?> getAuditLogById(String id);
  
  // Get all audit logs with pagination
  Future<List<AuditLog>> getAllAuditLogs({
    int? limit,
    int? offset,
    bool? descending,
  });
  
  // Get audit logs by user ID
  Future<List<AuditLog>> getAuditLogsByUserId(
    String userId, {
    int? limit,
    int? offset,
    DateTime? startDate,
    DateTime? endDate,
  });
  
  // Get audit logs by resource type
  Future<List<AuditLog>> getAuditLogsByResourceType(
    AuditLogResourceType resourceType, {
    int? limit,
    int? offset,
    DateTime? startDate,
    DateTime? endDate,
  });
  
  // Get audit logs by action type
  Future<List<AuditLog>> getAuditLogsByAction(
    AuditLogAction action, {
    int? limit,
    int? offset,
    DateTime? startDate,
    DateTime? endDate,
  });
  
  // Get audit logs by severity
  Future<List<AuditLog>> getAuditLogsBySeverity(
    AuditLogSeverity severity, {
    int? limit,
    int? offset,
    DateTime? startDate,
    DateTime? endDate,
  });
  
  // Get audit logs that require review
  Future<List<AuditLog>> getAuditLogsRequiringReview({
    int? limit,
    int? offset,
    DateTime? startDate,
    DateTime? endDate,
  });
  
  // Get data access audit logs (HIPAA compliance)
  Future<List<AuditLog>> getDataAccessAuditLogs({
    int? limit,
    int? offset,
    DateTime? startDate,
    DateTime? endDate,
  });
  
  // Get audit statistics for reporting
  Future<Map<String, dynamic>> getAuditStatistics({
    DateTime? startDate,
    DateTime? endDate,
  });
  
  // Delete audit logs older than specified date (for retention policy)
  Future<int> deleteOldAuditLogs(DateTime cutoffDate);
  
  // Get audit log count
  Future<int> getAuditLogCount({
    DateTime? startDate,
    DateTime? endDate,
  });
  
  // Get user activity summary
  Future<List<Map<String, dynamic>>> getUserActivitySummary({
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  });
  
  // Get resource access summary
  Future<List<Map<String, dynamic>>> getResourceAccessSummary({
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  });
  
  // Get security incidents
  Future<List<AuditLog>> getSecurityIncidents({
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
    int? offset,
  });
  
  // Export audit logs (for compliance reporting)
  Future<String> exportAuditLogs({
    DateTime? startDate,
    DateTime? endDate,
    String format, // 'csv', 'json', 'pdf'
  });
  
  // Archive audit logs (move to long-term storage)
  Future<int> archiveAuditLogs(DateTime cutoffDate);
  
  // Get audit log retention status
  Future<Map<String, dynamic>> getRetentionStatus();
  
  // Validate audit log integrity
  Future<bool> validateAuditLogIntegrity();
  
  // Get system health metrics
  Future<Map<String, dynamic>> getSystemHealthMetrics({
    DateTime? startDate,
    DateTime? endDate,
  });
  
  // Clear all audit logs (admin only - for testing/cleanup)
  Future<int> clearAllAuditLogs();
  
  // Batch create audit logs
  Future<void> batchCreateAuditLogs(List<AuditLog> auditLogs);
  
  // Search audit logs with multiple criteria
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
  });
}
