class ValidationUtils {
  // Validate required field
  static String? validateRequired(String? value, {String fieldName = 'This field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }
  
  // Validate email
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9.!#$%&*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$',
    );
    
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    
    return null;
  }
  
  // Validate phone number (simple validation)
  static String? validatePhoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    
    // Remove all non-digit characters
    final digitsOnly = value.replaceAll(RegExp(r'[^\d]'), '');
    
    if (digitsOnly.length < 10) {
      return 'Phone number must be at least 10 digits';
    }
    
    return null;
  }
  
  // Validate password
  static String? validatePassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Password is required';
    }
    
    if (value.length < 6) {
      return 'Password must be at least 6 characters long';
    }
    
    // Check for at least one uppercase letter
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }
    
    // Check for at least one lowercase letter
    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain at least one lowercase letter';
    }
    
    // Check for at least one digit
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }
    
    return null;
  }
  
  // Validate date (not in future for birth date, not in past for appointment, etc.)
  static String? validateDate(DateTime? date, {bool allowFuture = false, bool allowPast = true}) {
    if (date == null) {
      return 'Date is required';
    }
    
    final now = DateTime.now();
    
    if (!allowFuture && date.isAfter(now)) {
      return 'Date cannot be in the future';
    }
    
    if (!allowPast && date.isBefore(now)) {
      return 'Date cannot be in the past';
    }
    
    return null;
  }
  
  // Validate time
  static String? validateTime(DateTime? time) {
    if (time == null) {
      return 'Time is required';
    }
    
    return null;
  }
  
  // Validate medicine name
  static String? validateMedicineName(String? value) {
    final requiredError = validateRequired(value, fieldName: 'Medicine name');
    if (requiredError != null) return requiredError;
    
    if (value!.length > 100) {
      return 'Medicine name must be less than 100 characters';
    }
    
    return null;
  }
  
  // Validate dosage
  static String? validateDosage(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Dosage is required';
    }
    
    // Check if dosage contains numbers
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Dosage must contain a number';
    }
    
    return null;
  }
  
  // Validate doctor name
  static String? validateDoctorName(String? value) {
    final requiredError = validateRequired(value, fieldName: 'Doctor name');
    if (requiredError != null) return requiredError;
    
    if (value!.length > 100) {
      return 'Doctor name must be less than 100 characters';
    }
    
    return null;
  }
  
  // Validate notes
  static String? validateNotes(String? value) {
    if (value != null && value.length > 500) {
      return 'Notes must be less than 500 characters';
    }
    
    return null;
  }
  
  // Validate numeric value
  static String? validateNumeric(String? value, {String fieldName = 'Value'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    
    final numericValue = double.tryParse(value);
    if (numericValue == null) {
      return '$fieldName must be a number';
    }
    
    if (numericValue <= 0) {
      return '$fieldName must be greater than 0';
    }
    
    return null;
  }
  
  // Validate integer value
  static String? validateInteger(String? value, {String fieldName = 'Value'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    
    final intValue = int.tryParse(value);
    if (intValue == null) {
      return '$fieldName must be a whole number';
    }
    
    if (intValue <= 0) {
      return '$fieldName must be greater than 0';
    }
    
    return null;
  }
  
  // Validate positive number
  static String? validatePositiveNumber(String? value, {String fieldName = 'Value'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    
    final numericValue = double.tryParse(value);
    if (numericValue == null) {
      return '$fieldName must be a number';
    }
    
    if (numericValue < 0) {
      return '$fieldName cannot be negative';
    }
    
    return null;
  }
  
  // Validate that end date is after start date
  static String? validateDateRange(DateTime? startDate, DateTime? endDate) {
    if (startDate == null || endDate == null) {
      return null; // Let individual field validations handle null values
    }
    
    if (endDate.isBefore(startDate)) {
      return 'End date must be after start date';
    }
    
    return null;
  }
  
  // Validate that end time is after start time (on same day)
  static String? validateTimeRange(DateTime? startTime, DateTime? endTime) {
    if (startTime == null || endTime == null) {
      return null; // Let individual field validations handle null values
    }
    
    if (endTime.isBefore(startTime)) {
      return 'End time must be after start time';
    }
    
    return null;
  }
  
  // Combine multiple validators
  static String? combineValidators(List<String? Function()> validators) {
    for (final validator in validators) {
      final error = validator();
      if (error != null) {
        return error;
      }
    }
    return null;
  }
}