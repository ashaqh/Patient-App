import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/health_service.dart';
import '../../core/utils/error_utils.dart';

/// State for health service
class HealthServiceState {
  final bool isLoading;
  final bool hasPermissions;
  final bool isAvailable;
  final String? error;
  final Map<String, dynamic>? healthSummary;

  const HealthServiceState({
    this.isLoading = false,
    this.hasPermissions = false,
    this.isAvailable = false,
    this.error,
    this.healthSummary,
  });

  HealthServiceState copyWith({
    bool? isLoading,
    bool? hasPermissions,
    bool? isAvailable,
    String? error,
    Map<String, dynamic>? healthSummary,
  }) {
    return HealthServiceState(
      isLoading: isLoading ?? this.isLoading,
      hasPermissions: hasPermissions ?? this.hasPermissions,
      isAvailable: isAvailable ?? this.isAvailable,
      error: error,
      healthSummary: healthSummary ?? this.healthSummary,
    );
  }
}

/// Health service provider
final healthServiceProvider = Provider<HealthService>((ref) {
  return HealthService();
});

/// Health service state provider
final healthServiceStateProvider = StateNotifierProvider<HealthServiceNotifier, HealthServiceState>(
  (ref) => HealthServiceNotifier(ref),
);

/// Health service notifier
class HealthServiceNotifier extends StateNotifier<HealthServiceState> {
  final Ref ref;
  final HealthService _healthService;

  HealthServiceNotifier(this.ref)
      : _healthService = ref.read(healthServiceProvider),
        super(const HealthServiceState()) {
    // Initialize health service on startup
    _initialize();
  }

  /// Initialize health service
  Future<void> _initialize() async {
    try {
      state = state.copyWith(isLoading: true);

      // Check if health data is available
      final isAvailable = await _healthService.isHealthDataAvailable();
      
      // Check if we have permissions
      final hasPermissions = isAvailable ? await _healthService.hasPermissions() : false;

      state = state.copyWith(
        isLoading: false,
        isAvailable: isAvailable,
        hasPermissions: hasPermissions,
      );

      ErrorUtils.logInfo(
        'Health service initialized: available=$isAvailable, hasPermissions=$hasPermissions',
        tag: 'HealthServiceNotifier',
      );
    } catch (e, stackTrace) {
      ErrorUtils.logError(
        'Failed to initialize health service',
        error: e,
        stackTrace: stackTrace,
        tag: 'HealthServiceNotifier',
      );
      
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to initialize health service: ${e.toString()}',
      );
    }
  }

  /// Request health data permissions
  Future<bool> requestPermissions() async {
    try {
      if (!state.isAvailable) {
        state = state.copyWith(
          error: 'Health data is not available on this device',
        );
        return false;
      }

      state = state.copyWith(isLoading: true);

      final granted = await _healthService.requestPermissions();

      state = state.copyWith(
        isLoading: false,
        hasPermissions: granted,
        error: granted ? null : 'Permission request denied',
      );

      ErrorUtils.logInfo(
        'Health permissions requested: granted=$granted',
        tag: 'HealthServiceNotifier',
      );

      return granted;
    } catch (e, stackTrace) {
      ErrorUtils.logError(
        'Failed to request health permissions',
        error: e,
        stackTrace: stackTrace,
        tag: 'HealthServiceNotifier',
      );
      
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to request permissions: ${e.toString()}',
      );
      return false;
    }
  }

  /// Fetch health data summary for the last 7 days
  Future<void> fetchHealthSummary() async {
    try {
      if (!state.hasPermissions) {
        state = state.copyWith(
          error: 'No health data permissions. Please request permissions first.',
        );
        return;
      }

      state = state.copyWith(isLoading: true);

      final now = DateTime.now();
      final sevenDaysAgo = now.subtract(const Duration(days: 7));

      final summary = await _healthService.getHealthSummary(
        startDate: sevenDaysAgo,
        endDate: now,
      );

      state = state.copyWith(
        isLoading: false,
        healthSummary: summary,
      );

      ErrorUtils.logInfo(
        'Health summary fetched: $summary',
        tag: 'HealthServiceNotifier',
      );
    } catch (e, stackTrace) {
      ErrorUtils.logError(
        'Failed to fetch health summary',
        error: e,
        stackTrace: stackTrace,
        tag: 'HealthServiceNotifier',
      );
      
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to fetch health summary: ${e.toString()}',
      );
    }
  }

  /// Sync health data with app database
  Future<void> syncHealthData() async {
    try {
      if (!state.hasPermissions) {
        state = state.copyWith(
          error: 'No health data permissions. Please request permissions first.',
        );
        return;
      }

      state = state.copyWith(isLoading: true);

      final now = DateTime.now();
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));

      // Fetch all health data
      final allData = await _healthService.fetchAllHealthData(
        startDate: thirtyDaysAgo,
        endDate: now,
        limitPerType: 100,
      );

      // Process and sync data
      // This would typically involve:
      // 1. Converting health data points to app entities
      // 2. Saving to local database
      // 3. Handling duplicates and conflicts
      
      // For now, we'll just log the data
      int totalPoints = 0;
      for (final entry in allData.entries) {
        totalPoints += entry.value.length;
      }

      // Update health summary
      await fetchHealthSummary();

      state = state.copyWith(
        isLoading: false,
        error: null,
      );

      ErrorUtils.logInfo(
        'Health data synced: $totalPoints data points fetched',
        tag: 'HealthServiceNotifier',
      );
    } catch (e, stackTrace) {
      ErrorUtils.logError(
        'Failed to sync health data',
        error: e,
        stackTrace: stackTrace,
        tag: 'HealthServiceNotifier',
      );
      
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to sync health data: ${e.toString()}',
      );
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Reset health service
  Future<void> reset() async {
    state = const HealthServiceState();
    await _initialize();
  }
}

/// Health data sync status provider
final healthDataSyncProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final healthService = ref.watch(healthServiceProvider);
  final now = DateTime.now();
  final thirtyDaysAgo = now.subtract(const Duration(days: 30));

  try {
    final summary = await healthService.getHealthSummary(
      startDate: thirtyDaysAgo,
      endDate: now,
    );

    return {
      'lastSync': DateTime.now().toIso8601String(),
      'summary': summary,
      'status': 'success',
    };
  } catch (e) {
    return {
      'lastSync': null,
      'summary': {},
      'status': 'error',
      'error': e.toString(),
    };
  }
});