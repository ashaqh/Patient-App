import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';

import '../../domain/entities/audit_log.dart';
import '../../domain/repositories/audit_log_repository.dart';
import '../../data/datasources/database_helper.dart';
import '../../data/repositories/audit_log_repository_impl.dart';

// Provider for DatabaseHelper
final databaseHelperProvider = Provider<DatabaseHelper>((ref) {
  return DatabaseHelper();
});

// Provider for AuditLogRepository
final auditLogRepositoryProvider = Provider<AuditLogRepository>((ref) {
  final databaseHelper = ref.watch(databaseHelperProvider);
  return AuditLogRepositoryImpl(databaseHelper);
});

// State definitions
sealed class AuditLogState {
  const AuditLogState();
}

class AuditLogLoading extends AuditLogState {
  const AuditLogLoading();
}

class AuditLogError extends AuditLogState {
  final String error;
  const AuditLogError(this.error);
}

class AuditLogEmpty extends AuditLogState {
  const AuditLogEmpty();
}

class AuditLogData extends AuditLogState {
  final List<AuditLog> logs;
  final int totalCount;
  final int successCount;
  final int failureCount;
  final int securityCount;
  final Map<String, int> resourceTypeDistribution;
  final Map<String, int> actionDistribution;

  const AuditLogData({
    required this.logs,
    required this.totalCount,
    required this.successCount,
    required this.failureCount,
    required this.securityCount,
    required this.resourceTypeDistribution,
    required this.actionDistribution,
  });

  AuditLogData copyWith({
    List<AuditLog>? logs,
    int? totalCount,
    int? successCount,
    int? failureCount,
    int? securityCount,
    Map<String, int>? resourceTypeDistribution,
    Map<String, int>? actionDistribution,
  }) {
    return AuditLogData(
      logs: logs ?? this.logs,
      totalCount: totalCount ?? this.totalCount,
      successCount: successCount ?? this.successCount,
      failureCount: failureCount ?? this.failureCount,
      securityCount: securityCount ?? this.securityCount,
      resourceTypeDistribution: resourceTypeDistribution ?? this.resourceTypeDistribution,
      actionDistribution: actionDistribution ?? this.actionDistribution,
    );
  }
}

// Notifier for audit log state management
class AuditLogNotifier extends StateNotifier<AuditLogState> {
  final AuditLogRepository _repository;
  final Ref _ref;

  AuditLogNotifier(this._repository, this._ref) : super(const AuditLogLoading());

  // Load audit logs with optional filters
  Future<void> loadAuditLogs({
    String? searchQuery,
    AuditLogResourceType? resourceType,
    AuditLogAction? action,
    AuditLogSeverity? severity,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      state = const AuditLogLoading();

      final logs = await _repository.searchAuditLogs(
        keyword: searchQuery,
        resourceType: resourceType,
        action: action,
        severity: severity,
        startDate: startDate,
        endDate: endDate,
        limit: limit,
        offset: offset,
      );

      if (logs.isEmpty) {
        state = const AuditLogEmpty();
        return;
      }

      // Calculate statistics
      final totalCount = logs.length;
      final successCount = logs.where((log) => log.success).length;
      final failureCount = totalCount - successCount;
      final securityCount = logs.where((log) => log.severity == AuditLogSeverity.security).length;

      // Calculate resource type distribution
      final resourceTypeDistribution = <String, int>{};
      for (final log in logs) {
        final type = log.resourceType.displayName;
        resourceTypeDistribution[type] = (resourceTypeDistribution[type] ?? 0) + 1;
      }

      // Calculate action distribution
      final actionDistribution = <String, int>{};
      for (final log in logs) {
        final actionName = log.action.displayName;
        actionDistribution[actionName] = (actionDistribution[actionName] ?? 0) + 1;
      }

      state = AuditLogData(
        logs: logs,
        totalCount: totalCount,
        successCount: successCount,
        failureCount: failureCount,
        securityCount: securityCount,
        resourceTypeDistribution: resourceTypeDistribution,
        actionDistribution: actionDistribution,
      );
    } catch (e) {
      state = AuditLogError('Failed to load audit logs: $e');
    }
  }

  // Refresh audit logs (similar to load but maintains existing state if error occurs)
  Future<void> refreshAuditLogs({
    String? searchQuery,
    AuditLogResourceType? resourceType,
    AuditLogAction? action,
    AuditLogSeverity? severity,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
    int offset = 0,
  }) async {
    final currentState = state;
    
    try {
      if (currentState is! AuditLogLoading) {
        state = const AuditLogLoading();
      }

      final logs = await _repository.searchAuditLogs(
        keyword: searchQuery,
        resourceType: resourceType,
        action: action,
        severity: severity,
        startDate: startDate,
        endDate: endDate,
        limit: limit,
        offset: offset,
      );

      if (logs.isEmpty) {
        state = const AuditLogEmpty();
        return;
      }

      // Calculate statistics
      final totalCount = logs.length;
      final successCount = logs.where((log) => log.success).length;
      final failureCount = totalCount - successCount;
      final securityCount = logs.where((log) => log.severity == AuditLogSeverity.security).length;

      // Calculate resource type distribution
      final resourceTypeDistribution = <String, int>{};
      for (final log in logs) {
        final type = log.resourceType.displayName;
        resourceTypeDistribution[type] = (resourceTypeDistribution[type] ?? 0) + 1;
      }

      // Calculate action distribution
      final actionDistribution = <String, int>{};
      for (final log in logs) {
        final actionName = log.action.displayName;
        actionDistribution[actionName] = (actionDistribution[actionName] ?? 0) + 1;
      }

      state = AuditLogData(
        logs: logs,
        totalCount: totalCount,
        successCount: successCount,
        failureCount: failureCount,
        securityCount: securityCount,
        resourceTypeDistribution: resourceTypeDistribution,
        actionDistribution: actionDistribution,
      );
    } catch (e) {
      // Restore previous state if it was valid
      if (currentState is AuditLogData) {
        state = currentState;
      } else {
        state = AuditLogError('Failed to refresh audit logs: $e');
      }
    }
  }

  // Load more audit logs (pagination)
  Future<void> loadMoreAuditLogs({
    String? searchQuery,
    AuditLogResourceType? resourceType,
    AuditLogAction? action,
    AuditLogSeverity? severity,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 20,
  }) async {
    final currentState = state;
    
    if (currentState is! AuditLogData) {
      return;
    }

    try {
      final currentLogs = currentState.logs;
      final offset = currentLogs.length;

      final moreLogs = await _repository.searchAuditLogs(
        keyword: searchQuery,
        resourceType: resourceType,
        action: action,
        severity: severity,
        startDate: startDate,
        endDate: endDate,
        limit: limit,
        offset: offset,
      );

      if (moreLogs.isEmpty) {
        return; // No more logs to load
      }

      final allLogs = [...currentLogs, ...moreLogs];
      final totalCount = allLogs.length;
      final successCount = allLogs.where((log) => log.success).length;
      final failureCount = totalCount - successCount;
      final securityCount = allLogs.where((log) => log.severity == AuditLogSeverity.security).length;

      // Update distributions
      final resourceTypeDistribution = Map<String, int>.from(currentState.resourceTypeDistribution);
      final actionDistribution = Map<String, int>.from(currentState.actionDistribution);

      for (final log in moreLogs) {
        final type = log.resourceType.displayName;
        resourceTypeDistribution[type] = (resourceTypeDistribution[type] ?? 0) + 1;
        
        final actionName = log.action.displayName;
        actionDistribution[actionName] = (actionDistribution[actionName] ?? 0) + 1;
      }

      state = currentState.copyWith(
        logs: allLogs,
        totalCount: totalCount,
        successCount: successCount,
        failureCount: failureCount,
        securityCount: securityCount,
        resourceTypeDistribution: resourceTypeDistribution,
        actionDistribution: actionDistribution,
      );
    } catch (e) {
      // Don't change state on error for load more
    }
  }

  // Get audit statistics
  Future<Map<String, dynamic>> getAuditStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      return await _repository.getAuditStatistics(
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      throw Exception('Failed to get audit statistics: $e');
    }
  }

  // Get audit logs requiring review
  Future<List<AuditLog>> getAuditLogsRequiringReview({
    int? limit,
    int? offset,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      return await _repository.getAuditLogsRequiringReview(
        limit: limit,
        offset: offset,
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      throw Exception('Failed to get audit logs requiring review: $e');
    }
  }

  // Get data access audit logs (HIPAA compliance)
  Future<List<AuditLog>> getDataAccessAuditLogs({
    int? limit,
    int? offset,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      return await _repository.getDataAccessAuditLogs(
        limit: limit,
        offset: offset,
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      throw Exception('Failed to get data access audit logs: $e');
    }
  }

  // Get user activity summary
  Future<List<Map<String, dynamic>>> getUserActivitySummary({
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    try {
      return await _repository.getUserActivitySummary(
        startDate: startDate,
        endDate: endDate,
        limit: limit,
      );
    } catch (e) {
      throw Exception('Failed to get user activity summary: $e');
    }
  }

  // Get resource access summary
  Future<List<Map<String, dynamic>>> getResourceAccessSummary({
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    try {
      return await _repository.getResourceAccessSummary(
        startDate: startDate,
        endDate: endDate,
        limit: limit,
      );
    } catch (e) {
      throw Exception('Failed to get resource access summary: $e');
    }
  }

  // Get security incidents
  Future<List<AuditLog>> getSecurityIncidents({
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
    int? offset,
  }) async {
    try {
      return await _repository.getSecurityIncidents(
        startDate: startDate,
        endDate: endDate,
        limit: limit,
        offset: offset,
      );
    } catch (e) {
      throw Exception('Failed to get security incidents: $e');
    }
  }

  // Get system health metrics
  Future<Map<String, dynamic>> getSystemHealthMetrics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      return await _repository.getSystemHealthMetrics(
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      throw Exception('Failed to get system health metrics: $e');
    }
  }

  // Get audit logs with filtering (for analytics)
  Future<List<AuditLog>> getAuditLogs({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      return await _repository.searchAuditLogs(
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      throw Exception('Failed to get audit logs: $e');
    }
  }

  // Clear all audit logs (admin function)
  Future<void> clearAllAuditLogs() async {
    try {
      await _repository.clearAllAuditLogs();
      state = const AuditLogEmpty();
    } catch (e) {
      throw Exception('Failed to clear audit logs: $e');
    }
  }

  // Enforce retention policy
  Future<int> enforceRetentionPolicy() async {
    try {
      return await _repository.deleteOldAuditLogs(
        DateTime.now().subtract(const Duration(days: 2190)), // 6 years
      );
    } catch (e) {
      throw Exception('Failed to enforce retention policy: $e');
    }
  }

  // Export audit logs
  Future<String> exportAuditLogs({
    DateTime? startDate,
    DateTime? endDate,
    required String format,
  }) async {
    try {
      return await _repository.exportAuditLogs(
        startDate: startDate,
        endDate: endDate,
        format: format,
      );
    } catch (e) {
      throw Exception('Failed to export audit logs: $e');
    }
  }

  // Validate audit log integrity
  Future<bool> validateAuditLogIntegrity() async {
    try {
      return await _repository.validateAuditLogIntegrity();
    } catch (e) {
      throw Exception('Failed to validate audit log integrity: $e');
    }
  }
}

// Provider for AuditLogNotifier
final auditLogProvider = StateNotifierProvider<AuditLogNotifier, AuditLogState>((ref) {
  final repository = ref.watch(auditLogRepositoryProvider);
  return AuditLogNotifier(repository, ref);
});