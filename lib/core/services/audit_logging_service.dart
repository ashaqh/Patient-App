import 'dart:async';
import 'package:uuid/uuid.dart';

import '../../domain/entities/audit_log.dart';
import '../../data/datasources/database_helper.dart';
import '../../data/datasources/audit_log_data_source.dart';
import '../utils/device_info_service.dart';
import '../utils/network_info_service.dart';
import '../utils/error_utils.dart';

class AuditLoggingService {
  final DatabaseHelper _databaseHelper;
  final DeviceInfoService _deviceInfoService;
  final NetworkInfoService _networkInfoService;
  late AuditLogDataSource _auditLogDataSource;
  
  String _currentUserId = 'system';
  String _currentUserRole = 'system';
  String _currentSessionId = Uuid().v4();
  bool _isInitialized = false;
  
  // HIPAA audit log retention period (6 years as per HIPAA requirements)
  static const int retentionDays = 2190; // 6 years
  
  AuditLoggingService(this._databaseHelper)
      : _deviceInfoService = DeviceInfoService(),
        _networkInfoService = NetworkInfoService();
  
  // Initialize the service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      _auditLogDataSource = AuditLogDataSource(_databaseHelper);
      await _deviceInfoService.initialize();
      _isInitialized = true;
      
      // Log service initialization
      await _logSystemEvent(
        'Audit logging service initialized',
        AuditLogSeverity.info,
      );
    } catch (e) {
      ErrorUtils.logError('Failed to initialize audit logging service: $e');
      rethrow;
    }
  }
  
  // Set current user context
  void setUserContext(String userId, String userRole) {
    _currentUserId = userId;
    _currentUserRole = userRole;
    _currentSessionId = Uuid().v4();
    
    // Log user context change
    _logSystemEventAsync(
      'User context set: $userId ($userRole)',
      AuditLogSeverity.info,
    );
  }
  
  // Log data access event
  Future<void> logDataAccess({
    required AuditLogAction action,
    required AuditLogResourceType resourceType,
    String? resourceId,
    Map<String, dynamic>? beforeState,
    Map<String, dynamic>? afterState,
    String? details,
    bool success = true,
    String? errorMessage,
  }) async {
    if (!_isInitialized) {
      ErrorUtils.logWarning('Audit logging service not initialized');
      return;
    }
    
    try {
      final auditLog = await _createAuditLog(
        action: action,
        resourceType: resourceType,
        resourceId: resourceId,
        beforeState: beforeState,
        afterState: afterState,
        details: details,
        success: success,
        errorMessage: errorMessage,
      );
      
      await _auditLogDataSource.createAuditLog(auditLog);
    } catch (e) {
      ErrorUtils.logError('Failed to log data access event: $e');
    }
  }
  
  // Log user authentication event
  Future<void> logAuthentication({
    required AuditLogAction action,
    bool success = true,
    String? errorMessage,
    String? additionalDetails,
  }) async {
    if (!_isInitialized) {
      ErrorUtils.logWarning('Audit logging service not initialized');
      return;
    }
    
    try {
      final auditLog = await _createAuditLog(
        action: action,
        resourceType: AuditLogResourceType.userAccount,
        details: additionalDetails,
        success: success,
        errorMessage: errorMessage,
      );
      
      await _auditLogDataSource.createAuditLog(auditLog);
    } catch (e) {
      ErrorUtils.logError('Failed to log authentication event: $e');
    }
  }
  
  // Log system event
  Future<void> logSystemEvent({
    required String eventDescription,
    required AuditLogSeverity severity,
    String? resourceId,
    Map<String, dynamic>? additionalData,
  }) async {
    if (!_isInitialized) {
      ErrorUtils.logWarning('Audit logging service not initialized');
      return;
    }
    
    try {
      final auditLog = await _createAuditLog(
        action: AuditLogAction.create,
        resourceType: AuditLogResourceType.systemConfig,
        resourceId: resourceId,
        details: eventDescription,
        success: true,
        beforeState: additionalData,
      );
      
      // Override severity for system events
      final systemAuditLog = auditLog.copyWith(severity: severity);
      
      await _auditLogDataSource.createAuditLog(systemAuditLog);
    } catch (e) {
      ErrorUtils.logError('Failed to log system event: $e');
    }
  }
  
  // Log data export event (HIPAA compliance)
  Future<void> logDataExport({
    required AuditLogResourceType resourceType,
    String? resourceId,
    int? recordCount,
    String? exportFormat,
    String? exportDestination,
  }) async {
    if (!_isInitialized) {
      ErrorUtils.logWarning('Audit logging service not initialized');
      return;
    }
    
    try {
      final exportDetails = 'Export: $recordCount records, Format: $exportFormat, Destination: $exportDestination';
      
      final auditLog = await _createAuditLog(
        action: AuditLogAction.export,
        resourceType: resourceType,
        resourceId: resourceId,
        details: exportDetails,
        success: true,
      );
      
      await _auditLogDataSource.createAuditLog(auditLog);
    } catch (e) {
      ErrorUtils.logError('Failed to log data export event: $e');
    }
  }
  
  // Log backup/restore event
  Future<void> logBackupRestore({
    required AuditLogAction action,
    bool success = true,
    String? backupName,
    int? recordCount,
    String? errorMessage,
  }) async {
    if (!_isInitialized) {
      ErrorUtils.logWarning('Audit logging service not initialized');
      return;
    }
    
    try {
      final details = '${action.displayName}: $backupName ($recordCount records)';
      
      final auditLog = await _createAuditLog(
        action: action,
        resourceType: AuditLogResourceType.systemConfig,
        details: details,
        success: success,
        errorMessage: errorMessage,
      );
      
      await _auditLogDataSource.createAuditLog(auditLog);
    } catch (e) {
      ErrorUtils.logError('Failed to log backup/restore event: $e');
    }
  }
  
  // Get audit logs for reporting
  Future<List<AuditLog>> getAuditLogs({
    String? userId,
    AuditLogResourceType? resourceType,
    AuditLogAction? action,
    AuditLogSeverity? severity,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
    int? offset,
  }) async {
    if (!_isInitialized) {
      throw StateError('Audit logging service not initialized');
    }
    
    try {
      if (userId != null) {
        return await _auditLogDataSource.getAuditLogsByUserId(
          userId,
          limit: limit,
          offset: offset,
          startDate: startDate,
          endDate: endDate,
        );
      } else if (resourceType != null) {
        return await _auditLogDataSource.getAuditLogsByResourceType(
          resourceType,
          limit: limit,
          offset: offset,
          startDate: startDate,
          endDate: endDate,
        );
      } else if (action != null) {
        return await _auditLogDataSource.getAuditLogsByAction(
          action,
          limit: limit,
          offset: offset,
          startDate: startDate,
          endDate: endDate,
        );
      } else if (severity != null) {
        return await _auditLogDataSource.getAuditLogsBySeverity(
          severity,
          limit: limit,
          offset: offset,
          startDate: startDate,
          endDate: endDate,
        );
      } else {
        return await _auditLogDataSource.getAllAuditLogs(
          limit: limit,
          offset: offset,
        );
      }
    } catch (e) {
      ErrorUtils.logError('Failed to get audit logs: $e');
      rethrow;
    }
  }
  
  // Get audit logs that require review
  Future<List<AuditLog>> getAuditLogsRequiringReview({
    int? limit,
    int? offset,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (!_isInitialized) {
      throw StateError('Audit logging service not initialized');
    }
    
    try {
      return await _auditLogDataSource.getAuditLogsRequiringReview(
        limit: limit,
        offset: offset,
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      ErrorUtils.logError('Failed to get audit logs requiring review: $e');
      rethrow;
    }
  }
  
  // Get data access audit logs (HIPAA compliance reporting)
  Future<List<AuditLog>> getDataAccessAuditLogs({
    int? limit,
    int? offset,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (!_isInitialized) {
      throw StateError('Audit logging service not initialized');
    }
    
    try {
      return await _auditLogDataSource.getDataAccessAuditLogs(
        limit: limit,
        offset: offset,
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      ErrorUtils.logError('Failed to get data access audit logs: $e');
      rethrow;
    }
  }
  
  // Get audit statistics
  Future<Map<String, dynamic>> getAuditStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (!_isInitialized) {
      throw StateError('Audit logging service not initialized');
    }
    
    try {
      return await _auditLogDataSource.getAuditStatistics(
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      ErrorUtils.logError('Failed to get audit statistics: $e');
      rethrow;
    }
  }
  
  // Enforce retention policy (delete old audit logs)
  Future<int> enforceRetentionPolicy() async {
    if (!_isInitialized) {
      throw StateError('Audit logging service not initialized');
    }
    
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: retentionDays));
      final deletedCount = await _auditLogDataSource.deleteOldAuditLogs(cutoffDate);
      
      await _logSystemEvent(
        'Audit log retention policy enforced: $deletedCount records deleted (older than $cutoffDate)',
        AuditLogSeverity.info,
      );
      
      return deletedCount;
    } catch (e) {
      ErrorUtils.logError('Failed to enforce retention policy: $e');
      rethrow;
    }
  }
  
  // Get audit log count
  Future<int> getAuditLogCount({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (!_isInitialized) {
      throw StateError('Audit logging service not initialized');
    }
    
    try {
      return await _auditLogDataSource.getAuditLogCount(
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      ErrorUtils.logError('Failed to get audit log count: $e');
      rethrow;
    }
  }
  
  // Check if audit logging is enabled
  bool isEnabled() {
    return _isInitialized;
  }
  
  // Get current session ID
  String getCurrentSessionId() {
    return _currentSessionId;
  }
  
  // Create audit log with context information
  Future<AuditLog> _createAuditLog({
    required AuditLogAction action,
    required AuditLogResourceType resourceType,
    String? resourceId,
    Map<String, dynamic>? beforeState,
    Map<String, dynamic>? afterState,
    String? details,
    bool success = true,
    String? errorMessage,
  }) async {
    String? ipAddress;
    String? deviceId;
    String? deviceName;
    String? location;
    
    try {
      ipAddress = await _networkInfoService.getIpAddress();
    } catch (e) {
      // Silently fail - IP address is not critical
    }
    
    try {
      deviceId = await _deviceInfoService.getDeviceId();
      deviceName = await _deviceInfoService.getDeviceName();
    } catch (e) {
      // Silently fail - device info is not critical
    }
    
    // Determine severity based on action and success
    AuditLogSeverity severity;
    if (!success) {
      severity = AuditLogSeverity.error;
    } else if (action == AuditLogAction.accessDenied) {
      severity = AuditLogSeverity.security;
    } else if (resourceType.isSensitiveAccess) {
      severity = AuditLogSeverity.warning;
    } else {
      severity = AuditLogSeverity.info;
    }
    
    return AuditLog(
      action: action,
      resourceType: resourceType,
      resourceId: resourceId,
      userId: _currentUserId,
      userRole: _currentUserRole,
      ipAddress: ipAddress,
      deviceId: deviceId,
      deviceName: deviceName,
      location: location,
      success: success,
      errorMessage: errorMessage,
      beforeState: beforeState,
      afterState: afterState,
      details: details,
      severity: severity,
      sessionId: _currentSessionId,
    );
  }
  
  // Log system event (synchronous creation)
  Future<void> _logSystemEvent(String description, AuditLogSeverity severity) async {
    try {
      await logSystemEvent(
        eventDescription: description,
        severity: severity,
      );
    } catch (e) {
      ErrorUtils.logError('Failed to log internal system event: $e');
    }
  }
  
  // Log system event asynchronously (fire and forget)
  void _logSystemEventAsync(String description, AuditLogSeverity severity) {
    Future.microtask(() async {
      try {
        await _logSystemEvent(description, severity);
      } catch (e) {
        // Ignore errors in async logging
      }
    });
  }
  
  // Helper method to determine if resource type is sensitive (for HIPAA)
  bool _isSensitiveResource(AuditLogResourceType resourceType) {
    return const {
      AuditLogResourceType.vitalSign,
      AuditLogResourceType.medicine,
      AuditLogResourceType.prescription,
      AuditLogResourceType.patientProfile,
    }.contains(resourceType);
  }
}

// Extension to check if resource type is sensitive
extension AuditLogResourceTypeExtension on AuditLogResourceType {
  bool get isSensitiveAccess {
    return const {
      AuditLogResourceType.vitalSign,
      AuditLogResourceType.medicine,
      AuditLogResourceType.prescription,
      AuditLogResourceType.patientProfile,
    }.contains(this);
  }
}
