class AppConstants {
  // App information
  static const String appName = 'CareVault';
  static const String appVersion = '1.0.0';
  static const String privacyPolicyUrl =
      'https://sites.google.com/view/carevault/home';
  static const String termsOfServiceUrl =
      'https://sites.google.com/view/carevaulttos/home';
  static const String supportEmail = 'kamdarakansha@gmail.com';
  static const String complianceEmail = 'privacy@carevault.app';
  static const String appStoreReviewUrl = 'https://apps.apple.com/app/id0000000000';
  static const String playStoreReviewUrl =
      'https://play.google.com/store/apps/details?id=com.apprise.carevault';
  // Database constants
  static const String databaseName = 'carevault.db';
  static const int databaseVersion = 1;
  
  // Storage constants
  static const String prescriptionsDirectory = 'prescriptions';
  static const String reportsDirectory = 'reports';
  static const String imagesDirectory = 'images';
  
  // Notification constants
  static const String notificationChannelId = 'carevault_reminders';
  static const String notificationChannelName = 'Medicine Reminders';
  static const String notificationChannelDescription = 'Notifications for medicine reminders and follow-ups';
  
  // Time constants (in minutes)
  static const int reminderSnoozeDuration = 10;
  static const int followUpReminderDays = 1; // Remind 1 day before follow-up
  
  // UI constants
  static const double minimumTouchTargetSize = 48.0;
  static const double minimumFontSize = 16.0;
  static const double defaultBorderRadius = 12.0;
  static const double defaultPadding = 16.0;
  static const double largePadding = 24.0;
  
  // Validation constants
  static const int maxMedicineNameLength = 100;
  static const int maxDoctorNameLength = 100;
  static const int maxNotesLength = 500;
  
  // Date format constants
  static const String displayDateFormat = 'dd MMM yyyy';
  static const String displayTimeFormat = 'hh:mm a';
  static const String displayDateTimeFormat = 'dd MMM yyyy, hh:mm a';
  static const String databaseDateFormat = 'yyyy-MM-dd';
  static const String databaseTimeFormat = 'HH:mm:ss';
  static const String databaseDateTimeFormat = 'yyyy-MM-dd HH:mm:ss';
  
  // Error messages
  static const String networkError = 'No internet connection. Please check your network.';
  static const String genericError = 'Something went wrong. Please try again.';
  static const String validationError = 'Please check your input and try again.';
  static const String permissionError = 'Permission required to perform this action.';
  static const String fileError = 'Error accessing file. Please try again.';
  
  // Success messages
  static const String saveSuccess = 'Saved successfully.';
  static const String deleteSuccess = 'Deleted successfully.';
  static const String updateSuccess = 'Updated successfully.';
  
  // Medicine frequency options
  static const List<String> frequencyOptions = [
    'Once daily',
    'Twice daily',
    'Three times daily',
    'Four times daily',
    'Every 6 hours',
    'Every 8 hours',
    'Every 12 hours',
    'As needed',
    'Weekly',
    'Monthly',
  ];
  
  // Medicine status options
  static const List<String> medicineStatusOptions = [
    'Active',
    'Completed',
    'Skipped',
    'Missed',
  ];
  
  // Follow-up status options
  static const List<String> followUpStatusOptions = [
    'Scheduled',
    'Completed',
    'Cancelled',
    'Rescheduled',
  ];
  
  // File type options
  static const List<String> fileTypeOptions = [
    'Prescription',
    'Lab Report',
    'Doctor Note',
    'Medical Image',
    'Other',
  ];
}
