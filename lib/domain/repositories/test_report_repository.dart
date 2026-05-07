import '../entities/test_report.dart';

abstract class TestReportRepository {
  Future<String> createTestReport(TestReport report);
  Future<TestReport?> getTestReportById(String id);
  Future<List<TestReport>> getAllTestReports({String? orderBy});
  Future<List<TestReport>> getTestReportsByDateRange(DateTime startDate, DateTime endDate);
  Future<List<TestReport>> getTestReportsByType(String reportType);
  Future<List<TestReport>> getTestReportsByLab(String labName);
  Future<List<TestReport>> getRecentTestReports({int limit = 10});
  Future<int> updateTestReport(TestReport report);
  Future<int> deleteTestReportById(String id);
  Future<int> deleteAllTestReports();
  Future<List<TestReport>> searchTestReports(String query);
  Future<int> getTestReportCount();
  Future<List<TestReport>> getTestReportsForMonth(int year, int month);
  Future<List<TestReport>> getTestReportsForCurrentMonth();
  Future<void> batchInsertTestReports(List<TestReport> reports);
  Future<void> batchUpdateTestReports(List<TestReport> reports);
  Future<Map<String, List<TestReport>>> getTestReportsGroupedByMonth();
  Future<Map<String, List<TestReport>>> getTestReportsGroupedByLab();
  Future<Map<String, List<TestReport>>> getTestReportsGroupedByType();
}
