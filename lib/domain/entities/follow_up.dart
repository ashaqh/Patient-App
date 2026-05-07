import 'package:uuid/uuid.dart';

enum FollowUpStatus {
  scheduled,
  completed,
  cancelled,
  rescheduled;

  static FollowUpStatus fromDbValue(int value) {
    switch (value) {
      case 0:
        return FollowUpStatus.scheduled;
      case 1:
        return FollowUpStatus.completed;
      case 2:
        return FollowUpStatus.cancelled;
      case 3:
        return FollowUpStatus.rescheduled;
      default:
        return FollowUpStatus.scheduled;
    }
  }
}

extension FollowUpStatusExtension on FollowUpStatus {
  String get displayName {
    switch (this) {
      case FollowUpStatus.scheduled:
        return 'Scheduled';
      case FollowUpStatus.completed:
        return 'Completed';
      case FollowUpStatus.cancelled:
        return 'Cancelled';
      case FollowUpStatus.rescheduled:
        return 'Rescheduled';
    }
  }

  String get emoji {
    switch (this) {
      case FollowUpStatus.scheduled:
        return '📅';
      case FollowUpStatus.completed:
        return '✅';
      case FollowUpStatus.cancelled:
        return '❌';
      case FollowUpStatus.rescheduled:
        return '🔄';
    }
  }

  int get dbValue {
    switch (this) {
      case FollowUpStatus.scheduled:
        return 0;
      case FollowUpStatus.completed:
        return 1;
      case FollowUpStatus.cancelled:
        return 2;
      case FollowUpStatus.rescheduled:
        return 3;
    }
  }
}

class FollowUp {
  final String id;
  final String title;
  final DateTime date;
  final String? notes;
  final String? doctorName;
  final String? clinicName;
  final String? location;
  final FollowUpStatus status;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime lastModified;
  final int version;

  FollowUp({
    String? id,
    required this.title,
    required this.date,
    this.notes,
    this.doctorName,
    this.clinicName,
    this.location,
    this.status = FollowUpStatus.scheduled,
    this.completedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastModified,
    this.version = 1,
  })  : id = id ?? Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now(),
        lastModified = lastModified ?? DateTime.now();

  // Create a copy of follow-up with updated fields
  FollowUp copyWith({
    String? id,
    String? title,
    DateTime? date,
    String? notes,
    String? doctorName,
    String? clinicName,
    String? location,
    FollowUpStatus? status,
    DateTime? completedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastModified,
    int? version,
    // Note: The following properties are added to support the plan's cross-entity features,
    // though they might not be persisted directly in the DB
    String? medicineId,
    String? medicineName,
  }) {
    return FollowUp(
      id: id ?? this.id,
      title: title ?? this.title,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      doctorName: doctorName ?? this.doctorName,
      clinicName: clinicName ?? this.clinicName,
      location: location ?? this.location,
      status: status ?? this.status,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      lastModified: lastModified ?? DateTime.now(),
      version: version ?? this.version,
    );
  }

  // Convert to map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'date': date.toIso8601String(),
      'notes': notes,
      'doctor_name': doctorName,
      'clinic_name': clinicName,
      'location': location,
      'status': status.dbValue,
      'completed_at': completedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'last_modified': lastModified.toIso8601String(),
      'version': version,
    };
  }

  // Create from map (from database)
  factory FollowUp.fromMap(Map<String, dynamic> map) {
    return FollowUp(
      id: map['id'],
      title: map['title'],
      date: DateTime.parse(map['date']),
      notes: map['notes'],
      doctorName: map['doctor_name'],
      clinicName: map['clinic_name'],
      location: map['location'],
      status: FollowUpStatus.fromDbValue(map['status']),
      completedAt: map['completed_at'] != null ? DateTime.parse(map['completed_at']) : null,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
      lastModified: map['last_modified'] != null && map['last_modified'].toString().isNotEmpty 
          ? DateTime.parse(map['last_modified']) 
          : DateTime.now(),
      version: map['version'] ?? 1,
    );
  }

  // Check if follow-up is today
  bool get isToday {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  // Check if follow-up is upcoming (future date and scheduled)
  bool get isUpcoming {
    if (status != FollowUpStatus.scheduled) return false;
    return date.isAfter(DateTime.now());
  }

  // Check if follow-up is overdue (past date and still scheduled)
  bool get isOverdue {
    if (status != FollowUpStatus.scheduled) return false;
    return date.isBefore(DateTime.now());
  }

  // Check if follow-up is completed
  bool get isCompleted {
    return status == FollowUpStatus.completed;
  }

  // Check if follow-up is cancelled
  bool get isCancelled {
    return status == FollowUpStatus.cancelled;
  }

  // Get days until follow-up (negative if overdue)
  int get daysUntil {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final followUpDay = DateTime(date.year, date.month, date.day);
    return followUpDay.difference(today).inDays;
  }

  // Get display date in readable format
  String get displayDate {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final followUpDay = DateTime(date.year, date.month, date.day);
    
    final difference = followUpDay.difference(today).inDays;
    
    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Tomorrow';
    } else if (difference == -1) {
      return 'Yesterday';
    } else if (difference > 0 && difference < 7) {
      return 'In $difference days';
    } else if (difference < 0 && difference > -7) {
      return '${difference.abs()} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  // Get time in readable format
  String get displayTime {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  // Get urgency level (1-3, with 3 being most urgent)
  int get urgencyLevel {
    if (isCompleted || isCancelled) return 0;
    
    final days = daysUntil;
    if (days < 0) return 3; // Overdue
    if (days == 0) return 3; // Today
    if (days <= 1) return 2; // Tomorrow
    if (days <= 3) return 1; // Within 3 days
    return 0; // Not urgent
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is FollowUp &&
        other.id == id &&
        other.title == title &&
        other.date == date &&
        other.notes == notes &&
        other.doctorName == doctorName &&
        other.clinicName == clinicName &&
        other.location == location &&
        other.status == status &&
        other.completedAt == completedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        title.hashCode ^
        date.hashCode ^
        notes.hashCode ^
        doctorName.hashCode ^
        clinicName.hashCode ^
        location.hashCode ^
        status.hashCode ^
        completedAt.hashCode;
  }

  @override
  String toString() {
    return 'FollowUp(id: $id, title: $title, date: $date, status: ${status.displayName})';
  }
}
