class DatabaseConstants {
// Database info
static const String databaseName = 'carevault.db';
static const int databaseVersion = 7;

  // Table names
  static const String tableMedicines = 'medicines';
  static const String tablePrescriptions = 'prescriptions';
  static const String tableTestReports = 'test_reports';
  static const String tableReminderLogs = 'reminder_logs';
  static const String tableFollowUps = 'follow_ups';
  static const String tableVitalSigns = 'vital_signs';
  static const String tableAuditLogs = 'audit_logs';
  static const String tableDatabaseChanges = 'database_changes';
  
  // Common column names
  static const String columnId = 'id';
  static const String columnCreatedAt = 'created_at';
  static const String columnUpdatedAt = 'updated_at';
  static const String columnLastModified = 'last_modified';
  static const String columnVersion = 'version';
  
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
  // Note: Medicine createdAt and updatedAt use the common columnCreatedAt and columnUpdatedAt
  
  // Prescriptions table columns
  static const String columnPrescriptionFilePath = 'file_path';
  static const String columnPrescriptionFileName = 'file_name';
  static const String columnPrescriptionFileType = 'file_type';
  static const String columnPrescriptionDocumentType = 'document_type';
  static const String columnPrescriptionDate = 'date';
  static const String columnPrescriptionNotes = 'notes';
  static const String columnPrescriptionDoctorName = 'doctor_name';
  static const String columnPrescriptionClinicName = 'clinic_name';
  static const String columnPrescriptionFileSize = 'file_size';

  // Test reports table columns
  static const String columnTestReportFilePath = 'file_path';
  static const String columnTestReportFileName = 'file_name';
  static const String columnTestReportFileType = 'file_type';
  static const String columnTestReportType = 'report_type';
  static const String columnTestReportTestName = 'test_name';
  static const String columnTestReportLabName = 'lab_name';
  static const String columnTestReportDoctorName = 'doctor_name';
  static const String columnTestReportNotes = 'notes';
  static const String columnTestReportFileSize = 'file_size';
  
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
  
  // Vital signs table columns
  static const String columnVitalSignType = 'type';
  static const String columnVitalSignValue1 = 'value1';
  static const String columnVitalSignValue2 = 'value2';
  static const String columnVitalSignUnit = 'unit';
  static const String columnVitalSignReadingTime = 'reading_time';
  static const String columnVitalSignMealMarker = 'meal_marker';
  static const String columnVitalSignContext = 'context';
  static const String columnVitalSignNotes = 'notes';
  static const String columnVitalSignDeviceSource = 'device_source';
  static const String columnVitalSignIsManualEntry = 'is_manual_entry';
  
  // Audit logs table columns
  static const String columnAuditLogAction = 'action';
  static const String columnAuditLogResourceType = 'resource_type';
  static const String columnAuditLogResourceId = 'resource_id';
  static const String columnAuditLogUserId = 'user_id';
  static const String columnAuditLogUserRole = 'user_role';
  static const String columnAuditLogIpAddress = 'ip_address';
  static const String columnAuditLogDeviceId = 'device_id';
  static const String columnAuditLogDeviceName = 'device_name';
  static const String columnAuditLogLocation = 'location';
  static const String columnAuditLogTimestamp = 'timestamp';
  static const String columnAuditLogSuccess = 'success';
  static const String columnAuditLogErrorMessage = 'error_message';
  static const String columnAuditLogBeforeState = 'before_state';
  static const String columnAuditLogAfterState = 'after_state';
  static const String columnAuditLogDetails = 'details';
  static const String columnAuditLogSeverity = 'severity';
  static const String columnAuditLogSessionId = 'session_id';
  
  // Database changes table columns
  static const String columnChangeTableName = 'table_name';
  static const String columnChangeRowId = 'row_id';
  static const String columnChangeOperation = 'operation';
  static const String columnChangeTimestamp = 'timestamp';
  
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
      $columnUpdatedAt TEXT NOT NULL,
      $columnLastModified TEXT NOT NULL DEFAULT '',
      $columnVersion INTEGER NOT NULL DEFAULT 1
    )
  ''';
  
static String get createPrescriptionsTable => '''
CREATE TABLE $tablePrescriptions (
$columnId TEXT PRIMARY KEY,
$columnPrescriptionFilePath TEXT NOT NULL,
$columnPrescriptionFileName TEXT NOT NULL,
$columnPrescriptionFileType TEXT NOT NULL,
$columnPrescriptionDocumentType TEXT NOT NULL DEFAULT 'prescription',
$columnPrescriptionDate TEXT NOT NULL,
$columnPrescriptionNotes TEXT,
$columnPrescriptionDoctorName TEXT,
$columnPrescriptionClinicName TEXT,
$columnPrescriptionFileSize REAL,
$columnCreatedAt TEXT NOT NULL,
$columnUpdatedAt TEXT NOT NULL,
$columnLastModified TEXT NOT NULL DEFAULT '',
$columnVersion INTEGER NOT NULL DEFAULT 1
)
''';

static String get createTestReportsTable => '''
CREATE TABLE $tableTestReports (
$columnId TEXT PRIMARY KEY,
$columnTestReportFilePath TEXT NOT NULL,
$columnTestReportFileName TEXT NOT NULL,
$columnTestReportFileType TEXT NOT NULL,
$columnTestReportType TEXT NOT NULL,
$columnTestReportTestName TEXT,
$columnTestReportLabName TEXT,
$columnTestReportDoctorName TEXT,
$columnTestReportNotes TEXT,
$columnTestReportFileSize REAL,
$columnCreatedAt TEXT NOT NULL,
$columnUpdatedAt TEXT NOT NULL,
$columnLastModified TEXT NOT NULL DEFAULT '',
$columnVersion INTEGER NOT NULL DEFAULT 1
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
      $columnCreatedAt TEXT NOT NULL,
      $columnLastModified TEXT NOT NULL DEFAULT '',
      $columnVersion INTEGER NOT NULL DEFAULT 1
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
      $columnUpdatedAt TEXT NOT NULL,
      $columnLastModified TEXT NOT NULL DEFAULT '',
      $columnVersion INTEGER NOT NULL DEFAULT 1
    )
  ''';
  
  static String get createVitalSignsTable => '''
    CREATE TABLE $tableVitalSigns (
      $columnId TEXT PRIMARY KEY,
      $columnVitalSignType TEXT NOT NULL,
      $columnVitalSignValue1 REAL NOT NULL,
      $columnVitalSignValue2 REAL,
      $columnVitalSignUnit TEXT NOT NULL,
      $columnVitalSignReadingTime TEXT NOT NULL,
      $columnVitalSignMealMarker TEXT,
      $columnVitalSignContext TEXT,
      $columnVitalSignNotes TEXT,
      $columnVitalSignDeviceSource TEXT,
      $columnVitalSignIsManualEntry INTEGER NOT NULL DEFAULT 1,
      $columnCreatedAt TEXT NOT NULL,
      $columnUpdatedAt TEXT NOT NULL,
      $columnLastModified TEXT NOT NULL DEFAULT '',
      $columnVersion INTEGER NOT NULL DEFAULT 1
    )
  ''';
  
  static String get createAuditLogsTable => '''
    CREATE TABLE $tableAuditLogs (
      $columnId TEXT PRIMARY KEY,
      $columnAuditLogAction TEXT NOT NULL,
      $columnAuditLogResourceType TEXT NOT NULL,
      $columnAuditLogResourceId TEXT,
      $columnAuditLogUserId TEXT NOT NULL,
      $columnAuditLogUserRole TEXT NOT NULL,
      $columnAuditLogIpAddress TEXT,
      $columnAuditLogDeviceId TEXT,
      $columnAuditLogDeviceName TEXT,
      $columnAuditLogLocation TEXT,
      $columnAuditLogTimestamp TEXT NOT NULL,
      $columnAuditLogSuccess INTEGER NOT NULL,
      $columnAuditLogErrorMessage TEXT,
      $columnAuditLogBeforeState TEXT,
      $columnAuditLogAfterState TEXT,
      $columnAuditLogDetails TEXT,
      $columnAuditLogSeverity TEXT NOT NULL,
      $columnAuditLogSessionId TEXT NOT NULL
    )
  ''';
  
  static String get createDatabaseChangesTable => '''
    CREATE TABLE $tableDatabaseChanges (
      $columnId TEXT PRIMARY KEY,
      $columnChangeTableName TEXT NOT NULL,
      $columnChangeRowId TEXT NOT NULL,
      $columnChangeOperation TEXT NOT NULL,
      $columnChangeTimestamp TEXT NOT NULL
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
  
  static String get createVitalSignTypeIndex => '''
    CREATE INDEX idx_vital_sign_type ON $tableVitalSigns($columnVitalSignType)
  ''';
  
  static String get createVitalSignReadingTimeIndex => '''
    CREATE INDEX idx_vital_sign_reading_time ON $tableVitalSigns($columnVitalSignReadingTime)
  ''';
  
  static String get createAuditLogTimestampIndex => '''
    CREATE INDEX idx_audit_log_timestamp ON $tableAuditLogs($columnAuditLogTimestamp)
  ''';
  
  static String get createAuditLogUserIdIndex => '''
    CREATE INDEX idx_audit_log_user_id ON $tableAuditLogs($columnAuditLogUserId)
  ''';
  
  static String get createAuditLogResourceTypeIndex => '''
    CREATE INDEX idx_audit_log_resource_type ON $tableAuditLogs($columnAuditLogResourceType)
  ''';
  
  static String get createAuditLogActionIndex => '''
    CREATE INDEX idx_audit_log_action ON $tableAuditLogs($columnAuditLogAction)
  ''';
  
  static String get createAuditLogSeverityIndex => '''
    CREATE INDEX idx_audit_log_severity ON $tableAuditLogs($columnAuditLogSeverity)
  ''';
  
static String get createChangeTimestampIndex => '''
CREATE INDEX idx_change_timestamp ON $tableDatabaseChanges($columnChangeTimestamp)
''';

  static String get createTestReportDateIndex => '''
CREATE INDEX idx_test_report_date ON $tableTestReports($columnCreatedAt)
''';

static String get createTestReportTypeIndex => '''
CREATE INDEX idx_test_report_type ON $tableTestReports(report_type)
''';
  
  // Drop table statements (for migrations)
  static String get dropMedicinesTable => 'DROP TABLE IF EXISTS $tableMedicines';
  static String get dropPrescriptionsTable => 'DROP TABLE IF EXISTS $tablePrescriptions';
  static String get dropReminderLogsTable => 'DROP TABLE IF EXISTS $tableReminderLogs';
  static String get dropFollowUpsTable => 'DROP TABLE IF EXISTS $tableFollowUps';
  static String get dropVitalSignsTable => 'DROP TABLE IF EXISTS $tableVitalSigns';
  static String get dropAuditLogsTable => 'DROP TABLE IF EXISTS $tableAuditLogs';
  static String get dropDatabaseChangesTable => 'DROP TABLE IF EXISTS $tableDatabaseChanges';
}
