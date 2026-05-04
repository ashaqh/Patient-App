import '../../domain/entities/vital_sign.dart';

class VitalSignValidation {
  // Validate vital sign value based on type
  static String? validateVitalSignValue(
    String? value, 
    VitalSignType type, 
    {bool isFirstValue = true}
  ) {
    if (value == null || value.trim().isEmpty) {
      return 'Value is required';
    }
    
    final numericValue = double.tryParse(value);
    if (numericValue == null) {
      return 'Please enter a valid number';
    }
    
    // Check min/max ranges
    final min = type.minValue;
    final max = type.maxValue;
    
    if (numericValue < min) {
      return 'Value must be at least $min';
    }
    
    if (numericValue > max) {
      return 'Value must not exceed $max';
    }
    
    // Additional type-specific validations
    switch (type) {
      case VitalSignType.bloodPressure:
        if (isFirstValue) {
          // Systolic validation
          if (numericValue > 180) {
            return 'Warning: Very high systolic pressure. Consider medical attention.';
          }
          if (numericValue < 90) {
            return 'Warning: Very low systolic pressure. Consider medical attention.';
          }
        } else {
          // Diastolic validation
          if (numericValue > 120) {
            return 'Warning: Very high diastolic pressure. Consider medical attention.';
          }
          if (numericValue < 60) {
            return 'Warning: Very low diastolic pressure. Consider medical attention.';
          }
        }
        break;
        
      case VitalSignType.bloodSugar:
        if (numericValue > 250) {
          return 'Warning: Very high blood sugar. Consider medical attention.';
        }
        if (numericValue < 70) {
          return 'Warning: Very low blood sugar. Consider medical attention.';
        }
        break;
        
      case VitalSignType.temperature:
        if (numericValue > 38) {
          return 'Warning: Fever detected. Consider medical attention.';
        }
        if (numericValue < 36) {
          return 'Warning: Low body temperature. Consider medical attention.';
        }
        break;
        
      case VitalSignType.oxygen:
        if (numericValue < 90) {
          return 'Warning: Low oxygen saturation. Seek medical attention immediately.';
        }
        if (numericValue < 95) {
          return 'Warning: Below optimal oxygen saturation.';
        }
        break;
        
      case VitalSignType.weight:
        // Weight typically doesn't have dangerous ranges
        break;
    }
    
    return null;
  }
  
  // Validate blood pressure values together
  static String? validateBloodPressure(String? systolic, String? diastolic) {
    final systolicValue = double.tryParse(systolic ?? '');
    final diastolicValue = double.tryParse(diastolic ?? '');
    
    if (systolicValue == null || diastolicValue == null) {
      return null; // Individual validations will catch this
    }
    
    if (systolicValue <= diastolicValue) {
      return 'Systolic must be greater than diastolic';
    }
    
    // Check for dangerous combinations
    if (systolicValue > 180 && diastolicValue > 120) {
      return 'Dangerously high blood pressure. Seek emergency care.';
    }
    
    return null;
  }
  
  // Get target range description for a vital sign type
  static String getTargetRangeDescription(VitalSignType type) {
    final min = type.targetMin;
    final max = type.targetMax;
    
    if (min == null || max == null) {
      return 'No specific target range';
    }
    
    if (type == VitalSignType.bloodPressure) {
      return 'Target: $min-${max}/${type.targetMin != null ? 60 : ''}-${type.targetMax != null ? 80 : ''} ${type.unit}';
    }
    
    return 'Target: $min-${max} ${type.unit}';
  }
  
  // Check if value is within target range
  static bool isWithinTargetRange(double value, VitalSignType type, {double? secondValue}) {
    final min = type.targetMin;
    final max = type.targetMax;
    
    if (min == null || max == null) return true;
    
    if (type == VitalSignType.bloodPressure && secondValue != null) {
      final diastolicMin = 60;
      final diastolicMax = 80;
      return value >= min && value <= max && 
             secondValue >= diastolicMin && secondValue <= diastolicMax;
    }
    
    return value >= min && value <= max;
  }
  
  // Get status description
  static String getStatusDescription(VitalSignType type, double value, {double? secondValue}) {
    if (isWithinTargetRange(value, type, secondValue: secondValue)) {
      return 'Within normal range';
    }
    
    switch (type) {
      case VitalSignType.bloodPressure:
        if (value > 180 || (secondValue != null && secondValue > 120)) {
          return 'Hypertensive Crisis';
        }
        if (value > 140 || (secondValue != null && secondValue > 90)) {
          return 'High Blood Pressure';
        }
        if (value < 90 || (secondValue != null && secondValue < 60)) {
          return 'Low Blood Pressure';
        }
        break;
        
      case VitalSignType.bloodSugar:
        if (value > 250) {
          return 'Very High';
        }
        if (value > 180) {
          return 'High';
        }
        if (value < 70) {
          return 'Low';
        }
        break;
        
      case VitalSignType.temperature:
        if (value > 38) {
          return 'Fever';
        }
        if (value > 37.5) {
          return 'Elevated';
        }
        if (value < 36) {
          return 'Low';
        }
        break;
        
      case VitalSignType.oxygen:
        if (value < 90) {
          return 'Critical';
        }
        if (value < 95) {
          return 'Low';
        }
        break;
        
      case VitalSignType.weight:
        return 'Normal';
    }
    
    return 'Outside normal range';
  }
}