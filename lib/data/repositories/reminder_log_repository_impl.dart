import '../../domain/entities/reminder_log.dart';
import '../../domain/repositories/reminder_log_repository.dart';
import '../datasources/reminder_log_data_source.dart';
import '../datasources/database_helper.dart';

class ReminderLogRepositoryImpl implements ReminderLogRepository {
  final ReminderLogDataSource _reminderLogDataSource;

  ReminderLogRepositoryImpl(DatabaseHelper databaseHelper)
      : _reminderLogDataSource = ReminderLogDataSource(databaseHelper);

  @override
  Future<String> createReminderLog(ReminderLog reminderLog) {
    return _reminderLogDataSource.createReminderLog(reminderLog);
  }

  @override
  Future<ReminderLog?> getReminderLogById(String id) {
    return _reminderLogDataSource.getReminderLogById(id);
  }

  @override
  Future<List<ReminderLog>> getAllReminderLogs({String? orderBy}) {
    return _reminderLogDataSource.getAllReminderLogs(orderBy: orderBy);
  }

  @override
  Future<List<ReminderLog>> getReminderLogsByMedicineId(String medicineId) {
    return _reminderLogDataSource.getReminderLogsByMedicineId(medicineId);
  }

  @override
  Future<List<ReminderLog>> getReminderLogsByDate(DateTime date) {
    return _reminderLogDataSource.getReminderLogsByDate(date);
  }

  @override
  Future<List<ReminderLog>> getReminderLogsForToday() {
    return _reminderLogDataSource.getReminderLogsForToday();
  }

  @override
  Future<List<ReminderLog>> getReminderLogsByStatus(ReminderStatus status) {
    return _reminderLogDataSource.getReminderLogsByStatus(status);
  }

  @override
  Future<List<ReminderLog>> getOverdueReminderLogs() {
    return _reminderLogDataSource.getOverdueReminderLogs();
  }

  @override
  Future<List<ReminderLog>> getUpcomingReminderLogs() {
    return _reminderLogDataSource.getUpcomingReminderLogs();
  }

  @override
  Future<int> updateReminderLog(ReminderLog reminderLog) {
    return _reminderLogDataSource.updateReminderLog(reminderLog);
  }

  @override
  Future<int> updateReminderLogStatus(String id, ReminderStatus status, {String? notes}) {
    return _reminderLogDataSource.updateReminderLogStatus(id, status, notes: notes);
  }

  @override
  Future<int> deleteReminderLogById(String id) {
    return _reminderLogDataSource.deleteReminderLogById(id);
  }

  @override
  Future<int> deleteAllReminderLogs() {
    return _reminderLogDataSource.deleteAllReminderLogs();
  }

  @override
  Future<int> deleteReminderLogsByMedicineId(String medicineId) {
    return _reminderLogDataSource.deleteReminderLogsByMedicineId(medicineId);
  }

  @override
  Future<int> getReminderLogCount({ReminderStatus? status}) {
    return _reminderLogDataSource.getReminderLogCount(status: status);
  }

  @override
  Future<double> getAdherenceRateForMedicine(String medicineId) {
    return _reminderLogDataSource.getAdherenceRateForMedicine(medicineId);
  }

  @override
  Future<double> getOverallAdherenceRate() {
    return _reminderLogDataSource.getOverallAdherenceRate();
  }

  @override
  Future<List<ReminderLog>> getReminderLogsByDateRange(DateTime startDate, DateTime endDate) {
    return _reminderLogDataSource.getReminderLogsByDateRange(startDate, endDate);
  }

  @override
  Future<List<ReminderLog>> getReminderLogsForLastNDays(int days) {
    return _reminderLogDataSource.getReminderLogsForLastNDays(days);
  }

  @override
  Future<Map<String, List<ReminderLog>>> getReminderLogsGroupedByDate() {
    return _reminderLogDataSource.getReminderLogsGroupedByDate();
  }

  @override
  Future<Map<String, List<ReminderLog>>> getReminderLogsGroupedByMedicine() {
    return _reminderLogDataSource.getReminderLogsGroupedByMedicine();
  }

  @override
  Future<void> batchInsertReminderLogs(List<ReminderLog> reminderLogs) {
    return _reminderLogDataSource.batchInsertReminderLogs(reminderLogs);
  }

  @override
  Future<void> batchUpdateReminderLogs(List<ReminderLog> reminderLogs) {
    return _reminderLogDataSource.batchUpdateReminderLogs(reminderLogs);
  }

  @override
  Future<Map<String, int>> getReminderLogStatistics() {
    return _reminderLogDataSource.getReminderLogStatistics();
  }
}
