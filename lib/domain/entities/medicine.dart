import 'package:uuid/uuid.dart';

class Medicine {
  final String id;
  final String name;
  final String dosage;
  final String frequency;
  final List<String> times; // List of times as "HH:mm" strings
  final DateTime startDate;
  final DateTime? endDate;
  final String? notes;
  final String? instructions;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Medicine({
    String? id,
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.times,
    required this.startDate,
    this.endDate,
    this.notes,
    this.instructions,
    this.isActive = true,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // Create a copy of medicine with updated fields
  Medicine copyWith({
    String? id,
    String? name,
    String? dosage,
    String? frequency,
    List<String>? times,
    DateTime? startDate,
    DateTime? endDate,
    String? notes,
    String? instructions,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Medicine(
      id: id ?? this.id,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      frequency: frequency ?? this.frequency,
      times: times ?? this.times,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      notes: notes ?? this.notes,
      instructions: instructions ?? this.instructions,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  // Convert to map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'dosage': dosage,
      'frequency': frequency,
      'times': times.join(','), // Store times as comma-separated string
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'notes': notes,
      'instructions': instructions,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Create from map (from database)
  factory Medicine.fromMap(Map<String, dynamic> map) {
    return Medicine(
      id: map['id'],
      name: map['name'],
      dosage: map['dosage'],
      frequency: map['frequency'],
      times: (map['times'] as String).split(',').where((t) => t.isNotEmpty).toList(),
      startDate: DateTime.parse(map['start_date']),
      endDate: map['end_date'] != null ? DateTime.parse(map['end_date']) : null,
      notes: map['notes'],
      instructions: map['instructions'],
      isActive: map['is_active'] == 1,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  // Check if medicine should be taken today
  bool shouldBeTakenToday() {
    final now = DateTime.now();
    if (!isActive) return false;
    if (now.isBefore(startDate)) return false;
    if (endDate != null && now.isAfter(endDate!)) return false;
    return true;
  }

  // Get next reminder time
  DateTime? getNextReminderTime() {
    if (!shouldBeTakenToday()) return null;
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    for (final timeStr in times) {
      final parts = timeStr.split(':');
      if (parts.length != 2) continue;
      
      try {
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        final reminderTime = DateTime(today.year, today.month, today.day, hour, minute);
        
        if (reminderTime.isAfter(now)) {
          return reminderTime;
        }
      } catch (e) {
        continue;
      }
    }
    
    // If all times have passed, return the first time tomorrow
    if (times.isNotEmpty) {
      final firstTimeStr = times.first;
      final parts = firstTimeStr.split(':');
      if (parts.length == 2) {
        try {
          final hour = int.parse(parts[0]);
          final minute = int.parse(parts[1]);
          final tomorrow = today.add(const Duration(days: 1));
          return DateTime(tomorrow.year, tomorrow.month, tomorrow.day, hour, minute);
        } catch (e) {
          return null;
        }
      }
    }
    
    return null;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is Medicine &&
        other.id == id &&
        other.name == name &&
        other.dosage == dosage &&
        other.frequency == frequency &&
        other.times.length == times.length &&
        other.times.every((t) => times.contains(t)) &&
        other.startDate == startDate &&
        other.endDate == endDate &&
        other.notes == notes &&
        other.instructions == instructions &&
        other.isActive == isActive;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        dosage.hashCode ^
        frequency.hashCode ^
        times.hashCode ^
        startDate.hashCode ^
        endDate.hashCode ^
        notes.hashCode ^
        instructions.hashCode ^
        isActive.hashCode;
  }

  @override
  String toString() {
    return 'Medicine(id: $id, name: $name, dosage: $dosage, frequency: $frequency, times: $times, isActive: $isActive)';
  }
}