import '../entities/follow_up.dart';

abstract class FollowUpRepository {
  // Create a new follow-up
  Future<String> createFollowUp(FollowUp followUp);
  
  // Get follow-up by ID
  Future<FollowUp?> getFollowUpById(String id);
  
  // Get all follow-ups
  Future<List<FollowUp>> getAllFollowUps({String? orderBy});
  
  // Get upcoming follow-ups (future dates, scheduled status)
  Future<List<FollowUp>> getUpcomingFollowUps({int? limit});
  
  // Get overdue follow-ups (past dates, scheduled status)
  Future<List<FollowUp>> getOverdueFollowUps();
  
  // Get follow-ups for today
  Future<List<FollowUp>> getFollowUpsForToday();
  
  // Get follow-ups by status
  Future<List<FollowUp>> getFollowUpsByStatus(FollowUpStatus status);
  
  // Get follow-ups by doctor name
  Future<List<FollowUp>> getFollowUpsByDoctor(String doctorName);
  
  // Get follow-ups by date range
  Future<List<FollowUp>> getFollowUpsByDateRange(DateTime startDate, DateTime endDate);
  
  // Get follow-ups for a specific month
  Future<List<FollowUp>> getFollowUpsForMonth(int year, int month);
  
  // Get follow-ups for current month
  Future<List<FollowUp>> getFollowUpsForCurrentMonth();
  
  // Update follow-up
  Future<int> updateFollowUp(FollowUp followUp);
  
  // Update follow-up status
  Future<int> updateFollowUpStatus(String id, FollowUpStatus status, {DateTime? completedAt});
  
  // Mark follow-up as completed
  Future<int> markFollowUpAsCompleted(String id);
  
  // Delete follow-up by ID
  Future<int> deleteFollowUpById(String id);
  
  // Delete all follow-ups
  Future<int> deleteAllFollowUps();
  
  // Search follow-ups
  Future<List<FollowUp>> searchFollowUps(String query);
  
  // Get follow-up count
  Future<int> getFollowUpCount({FollowUpStatus? status});
  
  // Get follow-ups due in next N days
  Future<List<FollowUp>> getFollowUpsDueInNextNDays(int days);
  
  // Get follow-ups for the last N days
  Future<List<FollowUp>> getFollowUpsForLastNDays(int days);
  
  // Get follow-ups grouped by month
  Future<Map<String, List<FollowUp>>> getFollowUpsGroupedByMonth();
  
  // Get follow-ups grouped by doctor
  Future<Map<String, List<FollowUp>>> getFollowUpsGroupedByDoctor();
  
  // Get follow-ups grouped by status
  Future<Map<String, List<FollowUp>>> getFollowUpsGroupedByStatus();
  
  // Batch insert follow-ups
  Future<void> batchInsertFollowUps(List<FollowUp> followUps);
  
  // Update multiple follow-ups
  Future<void> batchUpdateFollowUps(List<FollowUp> followUps);
  
  // Get follow-up statistics
  Future<Map<String, int>> getFollowUpStatistics();
  
  // Get next follow-up (closest upcoming scheduled follow-up)
  Future<FollowUp?> getNextFollowUp();
}