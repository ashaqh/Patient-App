import 'package:uuid/uuid.dart';

enum VitalSignType {
  bloodPressure,
  bloodSugar,
  weight,
  temperature,
  oxygen,
}

extension VitalSignTypeExtension on VitalSignType {
  String get displayName {
    switch (this) {
      case VitalSignType.bloodPressure:
        return 'Blood Pressure';
      case VitalSignType.bloodSugar:
        return 'Blood Sugar';
      case VitalSignType.weight:
        return 'Weight';
      case VitalSignType.temperature:
        return 'Temperature';
      case VitalSignType.oxygen:
        return 'Oxygen (SpO2)';
    }
  }

  String get unit {
    switch (this) {
      case VitalSignType.bloodPressure:
        return 'mmHg';
      case VitalSignType.bloodSugar:
        return 'mg/dL';
      case VitalSignType.weight:
        return 'kg';
      case VitalSignType.temperature:
        return '°C';
      case VitalSignType.oxygen:
        return '%';
    }
  }

  bool get hasTwoValues {
    return this == VitalSignType.bloodPressure;
  }

  double get minValue {
    switch (this) {
      case VitalSignType.bloodPressure:
        return 0;
      case VitalSignType.bloodSugar:
        return 0;
      case VitalSignType.weight:
        return 0;
      case VitalSignType.temperature:
        return 30;
      case VitalSignType.oxygen:
        return 0;
    }
  }

  double get maxValue {
    switch (this) {
      case VitalSignType.bloodPressure:
        return 300;
      case VitalSignType.bloodSugar:
        return 600;
      case VitalSignType.weight:
        return 300;
      case VitalSignType.temperature:
        return 45;
      case VitalSignType.oxygen:
        return 100;
    }
  }

  double? get targetMin {
    switch (this) {
      case VitalSignType.bloodPressure:
        return 90; // systolic min
      case VitalSignType.bloodSugar:
        return 70;
      case VitalSignType.weight:
        return null;
      case VitalSignType.temperature:
        return 36.5;
      case VitalSignType.oxygen:
        return 95;
    }
  }

  double? get targetMax {
    switch (this) {
      case VitalSignType.bloodPressure:
        return 120; // systolic max
      case VitalSignType.bloodSugar:
        return 130;
      case VitalSignType.weight:
        return null;
      case VitalSignType.temperature:
        return 37.5;
      case VitalSignType.oxygen:
        return 100;
    }
  }

  String? get icon {
    switch (this) {
      case VitalSignType.bloodPressure:
        return '🫀';
      case VitalSignType.bloodSugar:
        return '🩸';
      case VitalSignType.weight:
        return '⚖️';
      case VitalSignType.temperature:
        return '🌡️';
      case VitalSignType.oxygen:
        return '🫁';
    }
  }
}

enum MealMarker {
  fasting,
  beforeMeal,
  afterMeal,
  bedtime,
  other,
}

extension MealMarkerExtension on MealMarker {
  String get displayName {
    switch (this) {
      case MealMarker.fasting:
        return 'Fasting';
      case MealMarker.beforeMeal:
        return 'Before Meal';
      case MealMarker.afterMeal:
        return 'After Meal';
      case MealMarker.bedtime:
        return 'Bedtime';
      case MealMarker.other:
        return 'Other';
    }
  }
}

class VitalSign {
  final String id;
  final VitalSignType type;
  final double value1; // Primary value (e.g., systolic for BP, glucose for sugar)
  final double? value2; // Secondary value (e.g., diastolic for BP)
  final String unit;
  final DateTime readingTime;
  final MealMarker? mealMarker;
  final String? context; // e.g., "After exercise", "Feeling stressed"
  final String? notes;
  final String? deviceSource; // e.g., "Apple Watch", "Manual entry"
  final bool isManualEntry;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime lastModified;
  final int version;

  VitalSign({
    String? id,
    required this.type,
    required this.value1,
    this.value2,
    String? unit,
    required this.readingTime,
    this.mealMarker,
    this.context,
    this.notes,
    this.deviceSource,
    this.isManualEntry = true,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastModified,
    this.version = 1,
  })  : id = id ?? Uuid().v4(),
        unit = unit ?? type.unit,
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now(),
        lastModified = lastModified ?? DateTime.now();

  // Create a copy of vital sign with updated fields
  VitalSign copyWith({
    String? id,
    VitalSignType? type,
    double? value1,
    double? value2,
    String? unit,
    DateTime? readingTime,
    MealMarker? mealMarker,
    String? context,
    String? notes,
    String? deviceSource,
    bool? isManualEntry,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastModified,
    int? version,
  }) {
    return VitalSign(
      id: id ?? this.id,
      type: type ?? this.type,
      value1: value1 ?? this.value1,
      value2: value2 ?? this.value2,
      unit: unit ?? this.unit,
      readingTime: readingTime ?? this.readingTime,
      mealMarker: mealMarker ?? this.mealMarker,
      context: context ?? this.context,
      notes: notes ?? this.notes,
      deviceSource: deviceSource ?? this.deviceSource,
      isManualEntry: isManualEntry ?? this.isManualEntry,
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
      'type': type.name,
      'value1': value1,
      'value2': value2,
      'unit': unit,
      'reading_time': readingTime.toIso8601String(),
      'meal_marker': mealMarker?.name,
      'context': context,
      'notes': notes,
      'device_source': deviceSource,
      'is_manual_entry': isManualEntry ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'last_modified': lastModified.toIso8601String(),
      'version': version,
    };
  }

  // Create from map (from database)
  factory VitalSign.fromMap(Map<String, dynamic> map) {
    return VitalSign(
      id: map['id'],
      type: VitalSignType.values.firstWhere(
        (type) => type.name == map['type'],
        orElse: () => VitalSignType.bloodPressure,
      ),
      value1: (map['value1'] as num).toDouble(),
      value2: map['value2'] != null ? (map['value2'] as num).toDouble() : null,
      unit: map['unit'],
      readingTime: DateTime.parse(map['reading_time']),
      mealMarker: map['meal_marker'] != null
          ? MealMarker.values.firstWhere(
              (marker) => marker.name == map['meal_marker'],
              orElse: () => MealMarker.other,
            )
          : null,
      context: map['context'],
      notes: map['notes'],
      deviceSource: map['device_source'],
      isManualEntry: map['is_manual_entry'] == 1,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
      lastModified: map['last_modified'] != null && map['last_modified'].toString().isNotEmpty 
          ? DateTime.parse(map['last_modified']) 
          : DateTime.now(),
      version: map['version'] ?? 1,
    );
  }

  // Get formatted display value
  String get displayValue {
    if (type.hasTwoValues && value2 != null) {
      return '${value1.toStringAsFixed(type == VitalSignType.bloodPressure ? 0 : 1)}/${value2!.toStringAsFixed(0)} $unit';
    }
    return '${value1.toStringAsFixed(type == VitalSignType.bloodPressure ? 0 : 1)} $unit';
  }

  // Check if value is within target range
  bool get isWithinTargetRange {
    final min = type.targetMin;
    final max = type.targetMax;
    
    if (min == null || max == null) return true;
    
    if (type.hasTwoValues && value2 != null) {
      // For blood pressure, check both systolic and diastolic
      final diastolicMin = 60;
      final diastolicMax = 80;
      return value1 >= min && value1 <= max && 
             value2! >= diastolicMin && value2! <= diastolicMax;
    }
    
    return value1 >= min && value1 <= max;
  }

  // Get status color based on value
  String get statusColor {
    if (isWithinTargetRange) return 'green';
    
    switch (type) {
      case VitalSignType.bloodPressure:
        if (value1 > 180 || (value2 != null && value2! > 120)) return 'red';
        if (value1 > 140 || (value2 != null && value2! > 90)) return 'orange';
        if (value1 < 90 || (value2 != null && value2! < 60)) return 'yellow';
        return 'green';
      case VitalSignType.bloodSugar:
        if (value1 > 250) return 'red';
        if (value1 > 180) return 'orange';
        if (value1 < 70) return 'yellow';
        return 'green';
      case VitalSignType.weight:
        return 'green';
      case VitalSignType.temperature:
        if (value1 > 38) return 'red';
        if (value1 > 37.5) return 'orange';
        if (value1 < 36) return 'yellow';
        return 'green';
      case VitalSignType.oxygen:
        if (value1 < 90) return 'red';
        if (value1 < 95) return 'yellow';
        return 'green';
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is VitalSign &&
        other.id == id &&
        other.type == type &&
        other.value1 == value1 &&
        other.value2 == value2 &&
        other.unit == unit &&
        other.readingTime == readingTime;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        type.hashCode ^
        value1.hashCode ^
        value2.hashCode ^
        unit.hashCode ^
        readingTime.hashCode;
  }

  @override
  String toString() {
    return 'VitalSign(id: $id, type: $type, value: $displayValue, time: $readingTime)';
  }
}
