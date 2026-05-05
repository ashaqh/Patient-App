import 'package:uuid/uuid.dart';

enum AuditLogAction {
  create,
  read,
  update,
  delete,
  export,
  backup,
  restore,
  login,
  logout,
  accessDenied
}

enum AuditLogResourceType {
  vitalSign,
  medicine,
  prescription,
  followUp,
  reminderLog,
  patientProfile,
  systemConfig,
  userAccount
}

extension AuditLogActionExtension on AuditLogAction {
  String get displayName {
    switch (this) {
      case AuditLogAction.create:
        return 'Create';
      case AuditLogAction.read:
        return 'Read';
      case AuditLogAction.update:
        return 'Update';
      case AuditLogAction.delete:
        return 'Delete';
      case AuditLogAction.export:
        return 'Export';
      case AuditLogAction.backup:
        return 'Backup';
      case AuditLogAction.restore:
        return 'Restore';
      case AuditLogAction.login:
        return 'Login';
      case AuditLogAction.logout:
        return 'Logout';
      case AuditLogAction.accessDenied:
        return 'Access Denied';
    }
  }

  bool get isDataAccess => const {
        AuditLogAction.create,
        AuditLogAction.read,
        AuditLogAction.update,
        AuditLogAction.delete,
        AuditLogAction.export,
      }.contains(this);
}

extension AuditLogResourceTypeExtension on AuditLogResourceType {
  String get displayName {
    switch (this) {
      case AuditLogResourceType.vitalSign:
        return 'Vital Sign';
      case AuditLogResourceType.medicine:
        return 'Medicine';
      case AuditLogResourceType.prescription:
        return 'Prescription';
      case AuditLogResourceType.followUp:
        return 'Follow-up';
      case AuditLogResourceType.reminderLog:
        return 'Reminder Log';
      case AuditLogResourceType.patientProfile:
        return 'Patient Profile';
      case AuditLogResourceType.systemConfig:
        return 'System Configuration';
      case AuditLogResourceType.userAccount:
        return 'User Account';
    }
  }
}

enum AuditLogSeverity {
  info,
  warning,
  error,
  security
}

extension AuditLogSeverityExtension on AuditLogSeverity {
  String get displayName {
    switch (this) {
      case AuditLogSeverity.info:
        return 'Info';
      case AuditLogSeverity.warning:
        return 'Warning';
      case AuditLogSeverity.error:
        return 'Error';
      case AuditLogSeverity.security:
        return 'Security';
    }
  }
}

class AuditLog {
  final String id;
  final AuditLogAction action;
  final AuditLogResourceType resourceType;
  final String? resourceId;
  final String userId;
  final String userRole;
  final String? ipAddress;
  final String? deviceId;
  final String? deviceName;
  final String? location;
  final DateTime timestamp;
  final bool success;
  final String? errorMessage;
  final Map<String, dynamic>? beforeState;
  final Map<String, dynamic>? afterState;
  final String? details;
  final AuditLogSeverity severity;
  final String sessionId;

  AuditLog({
    String? id,
    required this.action,
    required this.resourceType,
    this.resourceId,
    required this.userId,
    required this.userRole,
    this.ipAddress,
    this.deviceId,
    this.deviceName,
    this.location,
    DateTime? timestamp,
    required this.success,
    this.errorMessage,
    this.beforeState,
    this.afterState,
    this.details,
    AuditLogSeverity? severity,
    required this.sessionId,
  })  : id = id ?? Uuid().v4(),
        timestamp = timestamp ?? DateTime.now(),
        severity = severity ?? (success ? AuditLogSeverity.info : AuditLogSeverity.error);

  AuditLog copyWith({
    String? id,
    AuditLogAction? action,
    AuditLogResourceType? resourceType,
    String? resourceId,
    String? userId,
    String? userRole,
    String? ipAddress,
    String? deviceId,
    String? deviceName,
    String? location,
    DateTime? timestamp,
    bool? success,
    String? errorMessage,
    Map<String, dynamic>? beforeState,
    Map<String, dynamic>? afterState,
    String? details,
    AuditLogSeverity? severity,
    String? sessionId,
  }) {
    return AuditLog(
      id: id ?? this.id,
      action: action ?? this.action,
      resourceType: resourceType ?? this.resourceType,
      resourceId: resourceId ?? this.resourceId,
      userId: userId ?? this.userId,
      userRole: userRole ?? this.userRole,
      ipAddress: ipAddress ?? this.ipAddress,
      deviceId: deviceId ?? this.deviceId,
      deviceName: deviceName ?? this.deviceName,
      location: location ?? this.location,
      timestamp: timestamp ?? this.timestamp,
      success: success ?? this.success,
      errorMessage: errorMessage ?? this.errorMessage,
      beforeState: beforeState ?? this.beforeState,
      afterState: afterState ?? this.afterState,
      details: details ?? this.details,
      severity: severity ?? this.severity,
      sessionId: sessionId ?? this.sessionId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'action': action.name,
      'resource_type': resourceType.name,
      'resource_id': resourceId,
      'user_id': userId,
      'user_role': userRole,
      'ip_address': ipAddress,
      'device_id': deviceId,
      'device_name': deviceName,
      'location': location,
      'timestamp': timestamp.toIso8601String(),
      'success': success ? 1 : 0,
      'error_message': errorMessage,
      'before_state': beforeState != null ? _serializeState(beforeState!) : null,
      'after_state': afterState != null ? _serializeState(afterState!) : null,
      'details': details,
      'severity': severity.name,
      'session_id': sessionId,
    };
  }

  factory AuditLog.fromMap(Map<String, dynamic> map) {
    return AuditLog(
      id: map['id'],
      action: AuditLogAction.values.firstWhere(
        (action) => action.name == map['action'],
        orElse: () => AuditLogAction.read,
      ),
      resourceType: AuditLogResourceType.values.firstWhere(
        (type) => type.name == map['resource_type'],
        orElse: () => AuditLogResourceType.vitalSign,
      ),
      resourceId: map['resource_id'],
      userId: map['user_id'],
      userRole: map['user_role'],
      ipAddress: map['ip_address'],
      deviceId: map['device_id'],
      deviceName: map['device_name'],
      location: map['location'],
      timestamp: DateTime.parse(map['timestamp']),
      success: map['success'] == 1,
      errorMessage: map['error_message'],
      beforeState: map['before_state'] != null ? _deserializeState(map['before_state']) : null,
      afterState: map['after_state'] != null ? _deserializeState(map['after_state']) : null,
      details: map['details'],
      severity: AuditLogSeverity.values.firstWhere(
        (severity) => severity.name == map['severity'],
        orElse: () => AuditLogSeverity.info,
      ),
      sessionId: map['session_id'],
    );
  }

  static String _serializeState(Map<String, dynamic> state) {
    return state.entries
        .map((entry) => '${entry.key}:${entry.value?.toString() ?? "null"}')
        .join('|');
  }

  static Map<String, dynamic> _deserializeState(String serialized) {
    final result = <String, dynamic>{};
    final entries = serialized.split('|');
    for (final entry in entries) {
      final parts = entry.split(':');
      if (parts.length == 2) {
        result[parts[0]] = parts[1] == 'null' ? null : parts[1];
      }
    }
    return result;
  }

  String get summary {
    final actionName = action.displayName;
    final resourceName = resourceType.displayName;
    final status = success ? 'Success' : 'Failed';
    final error = errorMessage != null ? ' - $errorMessage' : '';
    
    return '$actionName $resourceName ${resourceId != null ? "($resourceId)" : ""} - $status$error';
  }

  bool get isSensitiveAccess {
    return resourceType == AuditLogResourceType.vitalSign ||
           resourceType == AuditLogResourceType.patientProfile ||
           resourceType == AuditLogResourceType.prescription;
  }

  bool get requiresReview {
    return !success ||
           action == AuditLogAction.accessDenied ||
           severity == AuditLogSeverity.security ||
           (isSensitiveAccess && action == AuditLogAction.read && resourceId != null);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is AuditLog &&
        other.id == id &&
        other.action == action &&
        other.resourceType == resourceType &&
        other.resourceId == resourceId &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        action.hashCode ^
        resourceType.hashCode ^
        resourceId.hashCode ^
        timestamp.hashCode;
  }

  @override
  String toString() {
    return 'AuditLog(id: $id, action: $action, resourceType: $resourceType, resourceId: $resourceId, userId: $userId, timestamp: $timestamp)';
  }
}
