import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/test_report_repository_impl.dart';
import '../../domain/entities/test_report.dart';
import '../../domain/repositories/test_report_repository.dart';
import 'medicine_provider.dart';

// Test report repository provider
final testReportRepositoryProvider = Provider<TestReportRepository>((ref) {
  final databaseHelper = ref.watch(databaseHelperProvider);
  return TestReportRepositoryImpl(databaseHelper);
});

// Test report list state
class TestReportListState {
  final List<TestReport> reports;
  final bool isLoading;
  final String? error;

  const TestReportListState({
    this.reports = const [],
    this.isLoading = false,
    this.error,
  });

  TestReportListState copyWith({
    List<TestReport>? reports,
    bool? isLoading,
    String? error,
  }) {
    return TestReportListState(
      reports: reports ?? this.reports,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

// Test report list notifier
class TestReportListNotifier extends StateNotifier<TestReportListState> {
  final TestReportRepository _testReportRepository;

  TestReportListNotifier(this._testReportRepository) : super(const TestReportListState()) {
    _loadReports();
  }

  Future<void> _loadReports() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final reports = await _testReportRepository.getAllTestReports();
      state = state.copyWith(reports: reports, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> addReport(TestReport report) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await _testReportRepository.createTestReport(report);
      await _loadReports();
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      rethrow;
    }
  }

  Future<void> updateReport(TestReport report) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await _testReportRepository.updateTestReport(report);
      await _loadReports();
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      rethrow;
    }
  }

  Future<void> deleteReport(String id) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await _testReportRepository.deleteTestReportById(id);
      await _loadReports();
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      rethrow;
    }
  }

  Future<void> refresh() async {
    await _loadReports();
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Test report list provider
final testReportListProvider = StateNotifierProvider<TestReportListNotifier, TestReportListState>((ref) {
  final testReportRepository = ref.watch(testReportRepositoryProvider);
  return TestReportListNotifier(testReportRepository);
});

// Recent test reports provider
final recentTestReportsProvider = FutureProvider<List<TestReport>>((ref) async {
  final testReportRepository = ref.watch(testReportRepositoryProvider);
  return await testReportRepository.getRecentTestReports(limit: 5);
});

// Test report count provider
final testReportCountProvider = FutureProvider<int>((ref) async {
  final testReportRepository = ref.watch(testReportRepositoryProvider);
  return await testReportRepository.getTestReportCount();
});
