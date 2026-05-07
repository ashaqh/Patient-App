import '../../domain/entities/test_report.dart';
import '../../domain/repositories/test_report_repository.dart';
import '../datasources/test_report_data_source.dart';
import '../datasources/database_helper.dart';

class TestReportRepositoryImpl implements TestReportRepository {
  final TestReportDataSource _testReportDataSource;

  TestReportRepositoryImpl(DatabaseHelper databaseHelper)
      : _testReportDataSource = TestReportDataSource(databaseHelper);

  @override
  Future<String> createTestReport(TestReport report) {
    return _testReportDataSource.createTestReport(report);
  }

  @override
  Future<TestReport?> getTestReportById(String id) {
    return _testReportDataSource.getTestReportById(id);
  }

  @override
  Future<List<TestReport>> getAllTestReports({String? orderBy}) {
    return _testReportDataSource.getAllTestReports(orderBy: orderBy);
  }

  @override
  Future<List<TestReport>> getTestReportsByDateRange(DateTime startDate, DateTime endDate) {
    return _testReportDataSource.getTestReportsByDateRange(startDate, endDate);
  }

  @override
  Future<List<TestReport>> getTestReportsByType(String reportType) {
    return _testReportDataSource.getTestReportsByType(reportType);
  }

  @override
  Future<List<TestReport>> getTestReportsByLab(String labName) {
    return _testReportDataSource.getTestReportsByLab(labName);
  }

  @override
  Future<List<TestReport>> getRecentTestReports({int limit = 10}) {
    return _testReportDataSource.getRecentTestReports(limit: limit);
  }

  @override
  Future<int> updateTestReport(TestReport report) {
    return _testReportDataSource.updateTestReport(report);
  }

  @override
  Future<int> deleteTestReportById(String id) {
    return _testReportDataSource.deleteTestReportById(id);
  }

  @override
  Future<int> deleteAllTestReports() {
    return _testReportDataSource.deleteAllTestReports();
  }

  @override
  Future<List<TestReport>> searchTestReports(String query) {
    return _testReportDataSource.searchTestReports(query);
  }

  @override
  Future<int> getTestReportCount() {
    return _testReportDataSource.getTestReportCount();
  }

  @override
  Future<List<TestReport>> getTestReportsForMonth(int year, int month) {
    return _testReportDataSource.getTestReportsForMonth(year, month);
  }

  @override
  Future<List<TestReport>> getTestReportsForCurrentMonth() {
    return _testReportDataSource.getTestReportsForCurrentMonth();
  }

  @override
  Future<void> batchInsertTestReports(List<TestReport> reports) {
    return _testReportDataSource.batchInsertTestReports(reports);
  }

  @override
  Future<void> batchUpdateTestReports(List<TestReport> reports) {
    return _testReportDataSource.batchUpdateTestReports(reports);
  }

  @override
  Future<Map<String, List<TestReport>>> getTestReportsGroupedByMonth() {
    return _testReportDataSource.getTestReportsGroupedByMonth();
  }

  @override
  Future<Map<String, List<TestReport>>> getTestReportsGroupedByLab() {
    return _testReportDataSource.getTestReportsGroupedByLab();
  }

  @override
  Future<Map<String, List<TestReport>>> getTestReportsGroupedByType() {
    return _testReportDataSource.getTestReportsGroupedByType();
  }
}
