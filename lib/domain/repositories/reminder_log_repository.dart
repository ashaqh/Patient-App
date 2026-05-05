import '../entities/reminder_log.dart';

abstract class ReminderLogRepository {
  // Create a new reminder log
  Future<String> createReminderLog(ReminderLog reminderLog);
  
  // Get reminder log by ID
  Future<ReminderLog?> getReminderLogById(String id);
  
  // Get all reminder logs
  Future<List<ReminderLog>> getAllReminderLogs({String? orderBy});
  
  // Get reminder logs by medicine ID
  Future<List<ReminderLog>> getReminderLogsByMedicineId(String medicineId);
  
  // Get reminder logs by date
  Future<List<ReminderLog>> getReminderLogsByDate(DateTime date);
  
  // Get reminder logs for today
  Future<List<ReminderLog>> getReminderLogsForToday();
  
  // Get reminder logs by status
  Future<List<ReminderLog>> getReminderLogsByStatus(ReminderStatus status);
  
  // Get overdue reminder logs (pending and scheduled time has passed)
  Future<List<ReminderLog>> getOverdueReminderLogs();
  
  // Get upcoming reminder logs (pending and scheduled time is in future)
  Future<List<ReminderLog>> getUpcomingReminderLogs();
  
  // Update reminder log
  Future<int> updateReminderLog(ReminderLog reminderLog);
  
  // Update reminder log status
  Future<int> updateReminderLogStatus(String id, ReminderStatus status, {String? notes});
  
  // Delete reminder log by ID
  Future<int> deleteReminderLogById(String id);
  
  // Delete all reminder logs
  Future<int> deleteAllReminderLogs();
  
  // Delete reminder logs by medicine ID
  Future<int> deleteReminderLogsByMedicineId(String medicineId);
  
  // Get reminder log count
  Future<int> getReminderLogCount({ReminderStatus? status});
  
  // Get adherence rate for a medicine (percentage of taken reminders)
  Future<double> getAdherenceRateForMedicine(String medicineId);
  
  // Get adherence rate overall (percentage of taken reminders)
  Future<double> getOverallAdherenceRate();
  
  // Get reminder logs by date range
  Future<List<ReminderLog>> getReminderLogsByDateRange(DateTime startDate, DateTime endDate);
  
  // Get reminder logs for the last N days
  Future<List<ReminderLog>> getReminderLogsForLastNDays(int days);
  
  // Get reminder logs grouped by date
  Future<Map<String, List<ReminderLog>>> getReminderLogsGroupedByDate();
  
  // Get reminder logs grouped by medicine
  Future<Map<String, List<ReminderLog>>> getReminderLogsGroupedByMedicine();
  
  // Batch insert reminder logs
  Future<void> batchInsertReminderLogs(List<ReminderLog> reminderLogs);
  
  // Update multiple reminder logs
  Future<void> batchUpdateReminderLogs(List<ReminderLog> reminderLogs);
  
  // Get reminder log statistics
  Future<Map<String, int>> getReminderLogStatistics();
}
