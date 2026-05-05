import 'package:uuid/uuid.dart';

import 'medicine.dart';
import 'prescription.dart';
import 'follow_up.dart';
import 'reminder_log.dart';

enum TimelineItemType {
  medicine,
  prescription,
  followUp,
  reminderLog;
  
  String get displayName {
    switch (this) {
      case TimelineItemType.medicine:
        return 'Medicine';
      case TimelineItemType.prescription:
        return 'Prescription';
      case TimelineItemType.followUp:
        return 'Follow-up';
      case TimelineItemType.reminderLog:
        return 'Reminder';
    }
  }
  
  String get icon {
    switch (this) {
      case TimelineItemType.medicine:
        return '💊';
      case TimelineItemType.prescription:
        return '📄';
      case TimelineItemType.followUp:
        return '📅';
      case TimelineItemType.reminderLog:
        return '⏰';
    }
  }
}

class TimelineItem {
  final String id;
  final TimelineItemType type;
  final DateTime date;
  final String title;
  final String description;
  final String status;
  final Map<String, dynamic>? metadata;

  TimelineItem({
    String? id,
    required this.type,
    required this.date,
    required this.title,
    required this.description,
    required this.status,
    this.metadata,
  }) : id = id ?? Uuid().v4();

  // Create from Medicine
  factory TimelineItem.fromMedicine(Medicine medicine) {
    return TimelineItem(
      type: TimelineItemType.medicine,
      date: medicine.createdAt,
      title: medicine.name,
      description: '${medicine.dosage} - ${medicine.frequency}',
      status: medicine.isActive ? 'Active' : 'Inactive',
      metadata: {
        'medicineId': medicine.id,
        'dosage': medicine.dosage,
        'frequency': medicine.frequency,
        'times': medicine.times,
        'startDate': medicine.startDate.toIso8601String(),
        'endDate': medicine.endDate?.toIso8601String(),
        'notes': medicine.notes,
        'instructions': medicine.instructions,
        'isActive': medicine.isActive,
      },
    );
  }

  // Create from Prescription
  factory TimelineItem.fromPrescription(Prescription prescription) {
    return TimelineItem(
      type: TimelineItemType.prescription,
      date: prescription.date,
      title: prescription.fileName,
      description: prescription.doctorName ?? 'Prescription',
      status: 'Uploaded',
      metadata: {
        'prescriptionId': prescription.id,
        'filePath': prescription.filePath,
        'fileName': prescription.fileName,
        'fileType': prescription.fileType,
        'fileSize': prescription.fileSize,
        'doctorName': prescription.doctorName,
        'clinicName': prescription.clinicName,
        'notes': prescription.notes,
      },
    );
  }

  // Create from FollowUp
  factory TimelineItem.fromFollowUp(FollowUp followUp) {
    return TimelineItem(
      type: TimelineItemType.followUp,
      date: followUp.date,
      title: followUp.title,
      description: followUp.doctorName ?? followUp.clinicName ?? 'Follow-up',
      status: followUp.status.displayName,
      metadata: {
        'followUpId': followUp.id,
        'title': followUp.title,
        'date': followUp.date.toIso8601String(),
        'doctorName': followUp.doctorName,
        'clinicName': followUp.clinicName,
        'location': followUp.location,
        'notes': followUp.notes,
        'status': followUp.status.name,
        'completedAt': followUp.completedAt?.toIso8601String(),
      },
    );
  }

  // Create from ReminderLog
  factory TimelineItem.fromReminderLog(ReminderLog reminderLog) {
    return TimelineItem(
      type: TimelineItemType.reminderLog,
      date: reminderLog.scheduledTime,
      title: reminderLog.medicineName,
      description: '${reminderLog.dosage} at ${reminderLog.displayTime}',
      status: reminderLog.status.displayName,
      metadata: {
        'reminderLogId': reminderLog.id,
        'medicineId': reminderLog.medicineId,
        'medicineName': reminderLog.medicineName,
        'dosage': reminderLog.dosage,
        'scheduledTime': reminderLog.scheduledTime.toIso8601String(),
        'actualTime': reminderLog.actualTime?.toIso8601String(),
        'status': reminderLog.status.name,
        'notes': reminderLog.notes,
        'isOverdue': reminderLog.isOverdue,
        'isToday': reminderLog.isToday,
      },
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'date': date.toIso8601String(),
      'title': title,
      'description': description,
      'status': status,
      'metadata': metadata,
    };
  }

  // Create from JSON
  factory TimelineItem.fromJson(Map<String, dynamic> json) {
    return TimelineItem(
      id: json['id'],
      type: TimelineItemType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => TimelineItemType.medicine,
      ),
      date: DateTime.parse(json['date']),
      title: json['title'],
      description: json['description'],
      status: json['status'],
      metadata: json['metadata'] != null 
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : null,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is TimelineItem &&
        other.id == id &&
        other.type == type &&
        other.date == date &&
        other.title == title &&
        other.description == description &&
        other.status == status;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        type.hashCode ^
        date.hashCode ^
        title.hashCode ^
        description.hashCode ^
        status.hashCode;
  }

  @override
  String toString() {
    return 'TimelineItem(id: $id, type: ${type.name}, date: $date, title: $title, status: $status)';
  }
}
