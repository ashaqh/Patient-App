import 'dart:math';
import 'package:intl/intl.dart';

import '../../domain/entities/vital_sign.dart';

class TestDataGenerator {
  static final Random _random = Random();
  static final DateFormat _dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

  // Generate test vital signs for demonstration
  static List<VitalSign> generateTestVitalSigns({
    int countPerType = 10,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final now = DateTime.now();
    final start = startDate ?? now.subtract(const Duration(days: 30));
    final end = endDate ?? now;
    
    final vitalSigns = <VitalSign>[];
    
    for (final type in VitalSignType.values) {
      for (int i = 0; i < countPerType; i++) {
        final readingTime = _randomDate(start, end);
        final value1 = _generateValueForType(type, isFirstValue: true);
        final value2 = type == VitalSignType.bloodPressure 
            ? _generateValueForType(type, isFirstValue: false)
            : null;
        
        final vitalSign = VitalSign(
          type: type,
          value1: value1,
          value2: value2,
          readingTime: readingTime,
          mealMarker: type == VitalSignType.bloodSugar
              ? MealMarker.values[_random.nextInt(MealMarker.values.length)]
              : null,
          context: _randomContext(),
          notes: _random.nextBool() ? _randomNotes() : null,
          deviceSource: _randomDeviceSource(),
          isManualEntry: _random.nextBool(),
        );
        
        vitalSigns.add(vitalSign);
      }
    }
    
    // Sort by reading time
    vitalSigns.sort((a, b) => b.readingTime.compareTo(a.readingTime));
    
    return vitalSigns;
  }

  static double _generateValueForType(VitalSignType type, {bool isFirstValue = true}) {
    switch (type) {
      case VitalSignType.bloodPressure:
        if (isFirstValue) {
          // Systolic: 90-180 (normal: 90-140)
          return 90 + _random.nextDouble() * 90;
        } else {
          // Diastolic: 60-120 (normal: 60-90)
          return 60 + _random.nextDouble() * 60;
        }
      case VitalSignType.bloodSugar:
        // Blood sugar: 70-250 (normal: 70-180)
        return 70 + _random.nextDouble() * 180;
      case VitalSignType.weight:
        // Weight: 50-120 kg
        return 50 + _random.nextDouble() * 70;
      case VitalSignType.temperature:
        // Temperature: 36.0-38.5°C (normal: 36.5-37.5)
        return 36.0 + _random.nextDouble() * 2.5;
      case VitalSignType.oxygen:
        // Oxygen: 85-100% (normal: 95-100)
        return 85 + _random.nextDouble() * 15;
    }
  }

  static DateTime _randomDate(DateTime start, DateTime end) {
    final duration = end.difference(start);
    final randomDuration = Duration(
      days: _random.nextInt(duration.inDays),
      hours: _random.nextInt(24),
      minutes: _random.nextInt(60),
    );
    return start.add(randomDuration);
  }

  static String _randomContext() {
    final contexts = [
      'Morning reading',
      'After exercise',
      'Before meal',
      'After meal',
      'Before bedtime',
      'Feeling stressed',
      'Routine check',
      'During illness',
      'Post-medication',
      'Pre-appointment',
    ];
    return contexts[_random.nextInt(contexts.length)];
  }

  static String _randomNotes() {
    final notes = [
      'Feeling normal',
      'Slight headache',
      'Feeling tired',
      'Good energy levels',
      'Minor dizziness',
      'No symptoms',
      'Feeling great',
      'Slight discomfort',
      'Regular reading',
      'Follow-up check',
    ];
    return notes[_random.nextInt(notes.length)];
  }

  static String _randomDeviceSource() {
    final sources = [
      'Manual Entry',
      'Apple Watch',
      'Fitbit',
      'Garmin',
      'Withings',
      'Omron',
      'Other Device',
    ];
    return sources[_random.nextInt(sources.length)];
  }

  // Generate test data summary for display
  static Map<String, dynamic> generateTestDataSummary() {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    
    return {
      'generated_at': _dateFormat.format(now),
      'vital_sign_types': VitalSignType.values.length,
      'total_readings': VitalSignType.values.length * 10,
      'time_range': '${_dateFormat.format(weekAgo)} to ${_dateFormat.format(now)}',
      'description': 'Sample health data for demonstration purposes',
    };
  }

  // Check if vital sign is realistic (within plausible ranges)
  static bool isRealisticVitalSign(VitalSign vitalSign) {
    final value = vitalSign.value1;
    
    switch (vitalSign.type) {
      case VitalSignType.bloodPressure:
        if (value < 60 || value > 250) return false;
        if (vitalSign.value2 != null) {
          if (vitalSign.value2! < 40 || vitalSign.value2! > 150) return false;
          if (value <= vitalSign.value2!) return false; // Systolic must be > diastolic
        }
        return true;
      case VitalSignType.bloodSugar:
        return value >= 20 && value <= 600;
      case VitalSignType.weight:
        return value >= 20 && value <= 300;
      case VitalSignType.temperature:
        return value >= 35 && value <= 42;
      case VitalSignType.oxygen:
        return value >= 70 && value <= 100;
    }
  }
}
