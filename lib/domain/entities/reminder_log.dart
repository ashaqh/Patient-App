import 'package:uuid/uuid.dart';

enum ReminderStatus {
  taken,
  skipped,
  missed,
  snoozed,
  pending;

  static ReminderStatus fromDbValue(int value) {
    switch (value) {
      case 0:
        return ReminderStatus.taken;
      case 1:
        return ReminderStatus.skipped;
      case 2:
        return ReminderStatus.missed;
      case 3:
        return ReminderStatus.snoozed;
      case 4:
        return ReminderStatus.pending;
      default:
        return ReminderStatus.pending;
    }
  }
}

extension ReminderStatusExtension on ReminderStatus {
  String get displayName {
    switch (this) {
      case ReminderStatus.taken:
        return 'Taken';
      case ReminderStatus.skipped:
        return 'Skipped';
      case ReminderStatus.missed:
        return 'Missed';
      case ReminderStatus.snoozed:
        return 'Snoozed';
      case ReminderStatus.pending:
        return 'Pending';
    }
  }

  String get emoji {
    switch (this) {
      case ReminderStatus.taken:
        return '✅';
      case ReminderStatus.skipped:
        return '⏭️';
      case ReminderStatus.missed:
        return '❌';
      case ReminderStatus.snoozed:
        return '⏰';
      case ReminderStatus.pending:
        return '⏳';
    }
  }

  int get dbValue {
    switch (this) {
      case ReminderStatus.taken:
        return 0;
      case ReminderStatus.skipped:
        return 1;
      case ReminderStatus.missed:
        return 2;
      case ReminderStatus.snoozed:
        return 3;
      case ReminderStatus.pending:
        return 4;
    }
  }
}

class ReminderLog {
  final String id;
  final String medicineId;
  final String medicineName;
  final String dosage;
  final DateTime scheduledTime;
  final DateTime? actualTime;
  final ReminderStatus status;
  final String? notes;
  final DateTime createdAt;

  ReminderLog({
    String? id,
    required this.medicineId,
    required this.medicineName,
    required this.dosage,
    required this.scheduledTime,
    this.actualTime,
    required this.status,
    this.notes,
    DateTime? createdAt,
  })  : id = id ?? Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  // Create a copy of reminder log with updated fields
  ReminderLog copyWith({
    String? id,
    String? medicineId,
    String? medicineName,
    String? dosage,
    DateTime? scheduledTime,
    DateTime? actualTime,
    ReminderStatus? status,
    String? notes,
    DateTime? createdAt,
  }) {
    return ReminderLog(
      id: id ?? this.id,
      medicineId: medicineId ?? this.medicineId,
      medicineName: medicineName ?? this.medicineName,
      dosage: dosage ?? this.dosage,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      actualTime: actualTime ?? this.actualTime,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Convert to map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'medicine_id': medicineId,
      'medicine_name': medicineName,
      'dosage': dosage,
      'scheduled_time': scheduledTime.toIso8601String(),
      'actual_time': actualTime?.toIso8601String(),
      'status': status.dbValue,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Create from map (from database)
  factory ReminderLog.fromMap(Map<String, dynamic> map) {
    return ReminderLog(
      id: map['id'],
      medicineId: map['medicine_id'],
      medicineName: map['medicine_name'],
      dosage: map['dosage'],
      scheduledTime: DateTime.parse(map['scheduled_time']),
      actualTime: map['actual_time'] != null ? DateTime.parse(map['actual_time']) : null,
      status: ReminderStatus.fromDbValue(map['status']),
      notes: map['notes'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  // Check if reminder is for today
  bool get isToday {
    final now = DateTime.now();
    return scheduledTime.year == now.year &&
        scheduledTime.month == now.month &&
        scheduledTime.day == now.day;
  }

  // Check if reminder is overdue (scheduled time has passed and status is pending)
  bool get isOverdue {
    if (status != ReminderStatus.pending) return false;
    return scheduledTime.isBefore(DateTime.now());
  }

  // Get time difference between scheduled and actual time
  Duration? get timeDifference {
    if (actualTime == null) return null;
    return actualTime!.difference(scheduledTime);
  }

  // Get display time in readable format
  String get displayTime {
    final hour = scheduledTime.hour.toString().padLeft(2, '0');
    final minute = scheduledTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  // Get display date in readable format
  String get displayDate {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final reminderDay = DateTime(scheduledTime.year, scheduledTime.month, scheduledTime.day);
    
    final difference = today.difference(reminderDay).inDays.abs();
    
    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else if (difference < 7) {
      return '$difference days ago';
    } else {
      return '${scheduledTime.day}/${scheduledTime.month}/${scheduledTime.year}';
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is ReminderLog &&
        other.id == id &&
        other.medicineId == medicineId &&
        other.medicineName == medicineName &&
        other.dosage == dosage &&
        other.scheduledTime == scheduledTime &&
        other.actualTime == actualTime &&
        other.status == status &&
        other.notes == notes;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        medicineId.hashCode ^
        medicineName.hashCode ^
        dosage.hashCode ^
        scheduledTime.hashCode ^
        actualTime.hashCode ^
        status.hashCode ^
        notes.hashCode;
  }

  @override
  String toString() {
    return 'ReminderLog(id: $id, medicineName: $medicineName, scheduledTime: $scheduledTime, status: ${status.displayName})';
  }
}
