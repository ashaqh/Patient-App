import '../../domain/entities/follow_up.dart';
import '../../domain/repositories/follow_up_repository.dart';
import '../datasources/follow_up_data_source.dart';
import '../datasources/database_helper.dart';

class FollowUpRepositoryImpl implements FollowUpRepository {
  final FollowUpDataSource _followUpDataSource;

  FollowUpRepositoryImpl(DatabaseHelper databaseHelper)
      : _followUpDataSource = FollowUpDataSource(databaseHelper);

  @override
  Future<String> createFollowUp(FollowUp followUp) {
    return _followUpDataSource.createFollowUp(followUp);
  }

  @override
  Future<FollowUp?> getFollowUpById(String id) {
    return _followUpDataSource.getFollowUpById(id);
  }

  @override
  Future<List<FollowUp>> getAllFollowUps({String? orderBy}) {
    return _followUpDataSource.getAllFollowUps(orderBy: orderBy);
  }

  @override
  Future<List<FollowUp>> getUpcomingFollowUps({int? limit}) {
    return _followUpDataSource.getUpcomingFollowUps(limit: limit);
  }

  @override
  Future<List<FollowUp>> getOverdueFollowUps() {
    return _followUpDataSource.getOverdueFollowUps();
  }

  @override
  Future<List<FollowUp>> getFollowUpsForToday() {
    return _followUpDataSource.getFollowUpsForToday();
  }

  @override
  Future<List<FollowUp>> getFollowUpsByStatus(FollowUpStatus status) {
    return _followUpDataSource.getFollowUpsByStatus(status);
  }

  @override
  Future<List<FollowUp>> getFollowUpsByDoctor(String doctorName) {
    return _followUpDataSource.getFollowUpsByDoctor(doctorName);
  }

  @override
  Future<List<FollowUp>> getFollowUpsByDateRange(DateTime startDate, DateTime endDate) {
    return _followUpDataSource.getFollowUpsByDateRange(startDate, endDate);
  }

  @override
  Future<List<FollowUp>> getFollowUpsForMonth(int year, int month) {
    return _followUpDataSource.getFollowUpsForMonth(year, month);
  }

  @override
  Future<List<FollowUp>> getFollowUpsForCurrentMonth() {
    return _followUpDataSource.getFollowUpsForCurrentMonth();
  }

  @override
  Future<int> updateFollowUp(FollowUp followUp) {
    return _followUpDataSource.updateFollowUp(followUp);
  }

  @override
  Future<int> updateFollowUpStatus(String id, FollowUpStatus status, {DateTime? completedAt}) {
    return _followUpDataSource.updateFollowUpStatus(id, status, completedAt: completedAt);
  }

  @override
  Future<int> markFollowUpAsCompleted(String id) {
    return _followUpDataSource.markFollowUpAsCompleted(id);
  }

  @override
  Future<int> deleteFollowUpById(String id) {
    return _followUpDataSource.deleteFollowUpById(id);
  }

  @override
  Future<int> deleteAllFollowUps() {
    return _followUpDataSource.deleteAllFollowUps();
  }

  @override
  Future<List<FollowUp>> searchFollowUps(String query) {
    return _followUpDataSource.searchFollowUps(query);
  }

  @override
  Future<int> getFollowUpCount({FollowUpStatus? status}) {
    return _followUpDataSource.getFollowUpCount(status: status);
  }

  @override
  Future<List<FollowUp>> getFollowUpsDueInNextNDays(int days) {
    return _followUpDataSource.getFollowUpsDueInNextNDays(days);
  }

  @override
  Future<List<FollowUp>> getFollowUpsForLastNDays(int days) {
    return _followUpDataSource.getFollowUpsForLastNDays(days);
  }

  @override
  Future<Map<String, List<FollowUp>>> getFollowUpsGroupedByMonth() {
    return _followUpDataSource.getFollowUpsGroupedByMonth();
  }

  @override
  Future<Map<String, List<FollowUp>>> getFollowUpsGroupedByDoctor() {
    return _followUpDataSource.getFollowUpsGroupedByDoctor();
  }

  @override
  Future<Map<String, List<FollowUp>>> getFollowUpsGroupedByStatus() {
    return _followUpDataSource.getFollowUpsGroupedByStatus();
  }

  @override
  Future<void> batchInsertFollowUps(List<FollowUp> followUps) {
    return _followUpDataSource.batchInsertFollowUps(followUps);
  }

  @override
  Future<void> batchUpdateFollowUps(List<FollowUp> followUps) {
    return _followUpDataSource.batchUpdateFollowUps(followUps);
  }

  @override
  Future<Map<String, int>> getFollowUpStatistics() {
    return _followUpDataSource.getFollowUpStatistics();
  }

  @override
  Future<FollowUp?> getNextFollowUp() {
    return _followUpDataSource.getNextFollowUp();
  }
}
