class DatabaseConstants {
  // Database info
  static const String databaseName = 'carevault.db';
  static const int databaseVersion = 1;
  
  // Table names
  static const String tableMedicines = 'medicines';
  static const String tablePrescriptions = 'prescriptions';
  static const String tableReminderLogs = 'reminder_logs';
  static const String tableFollowUps = 'follow_ups';
  
  // Common column names
  static const String columnId = 'id';
  static const String columnCreatedAt = 'created_at';
  static const String columnUpdatedAt = 'updated_at';
  
  // Medicines table columns
  static const String columnMedicineName = 'name';
  static const String columnMedicineDosage = 'dosage';
  static const String columnMedicineFrequency = 'frequency';
  static const String columnMedicineTimes = 'times';
  static const String columnMedicineStartDate = 'start_date';
  static const String columnMedicineEndDate = 'end_date';
  static const String columnMedicineNotes = 'notes';
  static const String columnMedicineInstructions = 'instructions';
  static const String columnMedicineIsActive = 'is_active';
  
  // Prescriptions table columns
  static const String columnPrescriptionFilePath = 'file_path';
  static const String columnPrescriptionFileName = 'file_name';
  static const String columnPrescriptionFileType = 'file_type';
  static const String columnPrescriptionDate = 'date';
  static const String columnPrescriptionNotes = 'notes';
  static const String columnPrescriptionDoctorName = 'doctor_name';
  static const String columnPrescriptionClinicName = 'clinic_name';
  static const String columnPrescriptionFileSize = 'file_size';
  
  // Reminder logs table columns
  static const String columnReminderMedicineId = 'medicine_id';
  static const String columnReminderMedicineName = 'medicine_name';
  static const String columnReminderDosage = 'dosage';
  static const String columnReminderScheduledTime = 'scheduled_time';
  static const String columnReminderActualTime = 'actual_time';
  static const String columnReminderStatus = 'status';
  static const String columnReminderNotes = 'notes';
  
  // Follow-ups table columns
  static const String columnFollowUpTitle = 'title';
  static const String columnFollowUpDate = 'date';
  static const String columnFollowUpNotes = 'notes';
  static const String columnFollowUpDoctorName = 'doctor_name';
  static const String columnFollowUpClinicName = 'clinic_name';
  static const String columnFollowUpLocation = 'location';
  static const String columnFollowUpStatus = 'status';
  static const String columnFollowUpCompletedAt = 'completed_at';
  
  // Create table statements
  static String get createMedicinesTable => '''
    CREATE TABLE $tableMedicines (
      $columnId TEXT PRIMARY KEY,
      $columnMedicineName TEXT NOT NULL,
      $columnMedicineDosage TEXT NOT NULL,
      $columnMedicineFrequency TEXT NOT NULL,
      $columnMedicineTimes TEXT NOT NULL,
      $columnMedicineStartDate TEXT NOT NULL,
      $columnMedicineEndDate TEXT,
      $columnMedicineNotes TEXT,
      $columnMedicineInstructions TEXT,
      $columnMedicineIsActive INTEGER NOT NULL DEFAULT 1,
      $columnCreatedAt TEXT NOT NULL,
      $columnUpdatedAt TEXT NOT NULL
    )
  ''';
  
  static String get createPrescriptionsTable => '''
    CREATE TABLE $tablePrescriptions (
      $columnId TEXT PRIMARY KEY,
      $columnPrescriptionFilePath TEXT NOT NULL,
      $columnPrescriptionFileName TEXT NOT NULL,
      $columnPrescriptionFileType TEXT NOT NULL,
      $columnPrescriptionDate TEXT NOT NULL,
      $columnPrescriptionNotes TEXT,
      $columnPrescriptionDoctorName TEXT,
      $columnPrescriptionClinicName TEXT,
      $columnPrescriptionFileSize REAL,
      $columnCreatedAt TEXT NOT NULL,
      $columnUpdatedAt TEXT NOT NULL
    )
  ''';
  
  static String get createReminderLogsTable => '''
    CREATE TABLE $tableReminderLogs (
      $columnId TEXT PRIMARY KEY,
      $columnReminderMedicineId TEXT NOT NULL,
      $columnReminderMedicineName TEXT NOT NULL,
      $columnReminderDosage TEXT NOT NULL,
      $columnReminderScheduledTime TEXT NOT NULL,
      $columnReminderActualTime TEXT,
      $columnReminderStatus INTEGER NOT NULL,
      $columnReminderNotes TEXT,
      $columnCreatedAt TEXT NOT NULL
    )
  ''';
  
  static String get createFollowUpsTable => '''
    CREATE TABLE $tableFollowUps (
      $columnId TEXT PRIMARY KEY,
      $columnFollowUpTitle TEXT NOT NULL,
      $columnFollowUpDate TEXT NOT NULL,
      $columnFollowUpNotes TEXT,
      $columnFollowUpDoctorName TEXT,
      $columnFollowUpClinicName TEXT,
      $columnFollowUpLocation TEXT,
      $columnFollowUpStatus INTEGER NOT NULL DEFAULT 0,
      $columnFollowUpCompletedAt TEXT,
      $columnCreatedAt TEXT NOT NULL,
      $columnUpdatedAt TEXT NOT NULL
    )
  ''';
  
  // Index statements
  static String get createMedicineTimesIndex => '''
    CREATE INDEX idx_medicine_times ON $tableMedicines($columnMedicineTimes)
  ''';
  
  static String get createMedicineActiveIndex => '''
    CREATE INDEX idx_medicine_active ON $tableMedicines($columnMedicineIsActive)
  ''';
  
  static String get createReminderMedicineIdIndex => '''
    CREATE INDEX idx_reminder_medicine_id ON $tableReminderLogs($columnReminderMedicineId)
  ''';
  
  static String get createReminderScheduledTimeIndex => '''
    CREATE INDEX idx_reminder_scheduled_time ON $tableReminderLogs($columnReminderScheduledTime)
  ''';
  
  static String get createReminderStatusIndex => '''
    CREATE INDEX idx_reminder_status ON $tableReminderLogs($columnReminderStatus)
  ''';
  
  static String get createFollowUpDateIndex => '''
    CREATE INDEX idx_follow_up_date ON $tableFollowUps($columnFollowUpDate)
  ''';
  
  static String get createFollowUpStatusIndex => '''
    CREATE INDEX idx_follow_up_status ON $tableFollowUps($columnFollowUpStatus)
  ''';
  
  // Drop table statements (for migrations)
  static String get dropMedicinesTable => 'DROP TABLE IF EXISTS $tableMedicines';
  static String get dropPrescriptionsTable => 'DROP TABLE IF EXISTS $tablePrescriptions';
  static String get dropReminderLogsTable => 'DROP TABLE IF EXISTS $tableReminderLogs';
  static String get dropFollowUpsTable => 'DROP TABLE IF EXISTS $tableFollowUps';
}