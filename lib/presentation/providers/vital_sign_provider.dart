import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/error_utils.dart';
import '../../data/datasources/database_helper.dart';
import '../../data/repositories/vital_sign_repository_impl.dart';
import '../../domain/entities/vital_sign.dart';
import '../../domain/repositories/vital_sign_repository.dart';
import '../../data/datasources/database_constants.dart';
import 'database_change_monitor_provider.dart';
import 'medicine_provider.dart'; // For databaseHelperProvider

// Vital sign filter enum
enum VitalSignFilter {
  all,
  bloodPressure,
  bloodSugar,
  weight,
  temperature,
  oxygen,
  abnormal,
}

// Vital sign repository provider
final vitalSignRepositoryProvider = Provider<VitalSignRepository>((ref) {
  final databaseHelper = ref.watch(databaseHelperProvider);
  return VitalSignRepositoryImpl(databaseHelper);
});

// Vital sign list state
class VitalSignListState {
  final List<VitalSign> vitalSigns;
  final bool isLoading;
  final String? error;
  final VitalSignFilter filter;
  final String searchQuery;
  final Map<VitalSignType, VitalSign?> latestReadings;

  const VitalSignListState({
    this.vitalSigns = const [],
    this.isLoading = false,
    this.error,
    this.filter = VitalSignFilter.all,
    this.searchQuery = '',
    this.latestReadings = const {},
  });

  VitalSignListState copyWith({
    List<VitalSign>? vitalSigns,
    bool? isLoading,
    String? error,
    VitalSignFilter? filter,
    String? searchQuery,
    Map<VitalSignType, VitalSign?>? latestReadings,
  }) {
    return VitalSignListState(
      vitalSigns: vitalSigns ?? this.vitalSigns,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      filter: filter ?? this.filter,
      searchQuery: searchQuery ?? this.searchQuery,
      latestReadings: latestReadings ?? this.latestReadings,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is VitalSignListState &&
        other.vitalSigns.length == vitalSigns.length &&
        other.vitalSigns.every((vs) => vitalSigns.contains(vs)) &&
        other.isLoading == isLoading &&
        other.error == error &&
        other.filter == filter &&
        other.searchQuery == searchQuery &&
        other.latestReadings.length == latestReadings.length;
  }

  @override
  int get hashCode {
    return vitalSigns.hashCode ^
        isLoading.hashCode ^
        error.hashCode ^
        filter.hashCode ^
        searchQuery.hashCode ^
        latestReadings.hashCode;
  }
}

// Vital sign list notifier
class VitalSignListNotifier extends StateNotifier<VitalSignListState> {
  final VitalSignRepository _vitalSignRepository;

  VitalSignListNotifier(this._vitalSignRepository)
    : super(const VitalSignListState()) {
    _loadVitalSigns();
  }

  // Load all vital signs
  Future<void> _loadVitalSigns() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final vitalSigns = await _vitalSignRepository.getAllVitalSigns();

      // Get latest readings for each type
      final latestReadings = <VitalSignType, VitalSign?>{};
      for (final type in VitalSignType.values) {
        final latest = await _vitalSignRepository.getLatestVitalSignByType(
          type,
        );
        latestReadings[type] = latest;
      }

      state = state.copyWith(
        vitalSigns: vitalSigns,
        isLoading: false,
        latestReadings: latestReadings,
      );
    } catch (e, stackTrace) {
      ErrorUtils.logError(
        'Failed to load vital signs',
        error: e,
        stackTrace: stackTrace,
      );
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load vital signs: ${e.toString()}',
      );
    }
  }

  // Create new vital sign
  Future<void> createVitalSign(VitalSign vitalSign) async {
    try {
      // Optimistic update
      state = state.copyWith(
        vitalSigns: [...state.vitalSigns, vitalSign],
        isLoading: true,
        error: null,
      );

      await _vitalSignRepository.createVitalSign(vitalSign);

      // Reload vital signs to get updated list and stats
      await _loadVitalSigns();
    } catch (e, stackTrace) {
      ErrorUtils.logError(
        'Failed to create vital sign',
        error: e,
        stackTrace: stackTrace,
      );
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to create vital sign: ${e.toString()}',
      );
      await _loadVitalSigns(); // Revert
      rethrow;
    }
  }

  // Update vital sign
  Future<void> updateVitalSign(VitalSign vitalSign) async {
    try {
      // Optimistic update
      state = state.copyWith(
        vitalSigns: state.vitalSigns.map((vs) => vs.id == vitalSign.id ? vitalSign : vs).toList(),
        isLoading: true,
        error: null,
      );

      await _vitalSignRepository.updateVitalSign(vitalSign);

      // Reload vital signs to get updated list
      await _loadVitalSigns();
    } catch (e, stackTrace) {
      ErrorUtils.logError(
        'Failed to update vital sign',
        error: e,
        stackTrace: stackTrace,
      );
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to update vital sign: ${e.toString()}',
      );
      await _loadVitalSigns(); // Revert
      rethrow;
    }
  }

  // Delete vital sign
  Future<void> deleteVitalSign(String id) async {
    try {
      // Optimistic update
      state = state.copyWith(
        vitalSigns: state.vitalSigns.where((vs) => vs.id != id).toList(),
        isLoading: true,
        error: null,
      );

      await _vitalSignRepository.deleteVitalSignById(id);
      await _loadVitalSigns();
    } catch (e, stackTrace) {
      ErrorUtils.logError(
        'Failed to delete vital sign',
        error: e,
        stackTrace: stackTrace,
      );
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to delete vital sign: ${e.toString()}',
      );
      await _loadVitalSigns(); // Revert
      rethrow;
    }
  }

  // Filter vital signs
  void setFilter(VitalSignFilter filter) {
    state = state.copyWith(filter: filter);
  }

  // Set search query
  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  // Refresh vital signs
  Future<void> refresh() async {
    await _loadVitalSigns();
  }

  // Get filtered vital signs
  List<VitalSign> get filteredVitalSigns {
    List<VitalSign> filtered = List.of(state.vitalSigns);

    // Apply type filter
    switch (state.filter) {
      case VitalSignFilter.bloodPressure:
        filtered = filtered
            .where((vs) => vs.type == VitalSignType.bloodPressure)
            .toList();
        break;
      case VitalSignFilter.bloodSugar:
        filtered = filtered
            .where((vs) => vs.type == VitalSignType.bloodSugar)
            .toList();
        break;
      case VitalSignFilter.weight:
        filtered = filtered
            .where((vs) => vs.type == VitalSignType.weight)
            .toList();
        break;
      case VitalSignFilter.temperature:
        filtered = filtered
            .where((vs) => vs.type == VitalSignType.temperature)
            .toList();
        break;
      case VitalSignFilter.oxygen:
        filtered = filtered
            .where((vs) => vs.type == VitalSignType.oxygen)
            .toList();
        break;
      case VitalSignFilter.abnormal:
        filtered = filtered.where((vs) => !vs.isWithinTargetRange).toList();
        break;
      case VitalSignFilter.all:
        // No type filtering
        break;
    }

    // Apply search query
    if (state.searchQuery.isNotEmpty) {
      final query = state.searchQuery.toLowerCase();
      filtered = filtered.where((vs) {
        return vs.type.displayName.toLowerCase().contains(query) ||
            vs.displayValue.toLowerCase().contains(query) ||
            (vs.notes?.toLowerCase().contains(query) ?? false) ||
            (vs.context?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    // Sort by reading time (newest first)
    filtered.sort((a, b) => b.readingTime.compareTo(a.readingTime));

    return filtered;
  }

  // Get vital signs for specific type
  List<VitalSign> getVitalSignsByType(VitalSignType type) {
    return state.vitalSigns.where((vs) => vs.type == type).toList()
      ..sort((a, b) => b.readingTime.compareTo(a.readingTime));
  }

  // Get today's vital signs
  List<VitalSign> get todaysVitalSigns {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    return state.vitalSigns
        .where((vs) => vs.readingTime.isAfter(startOfDay))
        .toList()
      ..sort((a, b) => b.readingTime.compareTo(a.readingTime));
  }

  // Get statistics for a specific type
  Map<String, dynamic> getVitalSignStatistics(VitalSignType type, int days) {
    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: days));

    final vitalSigns = getVitalSignsByType(
      type,
    ).where((vs) => vs.readingTime.isAfter(startDate)).toList();

    if (vitalSigns.isEmpty) {
      return {'count': 0, 'average': 0, 'min': 0, 'max': 0, 'trend': 'stable'};
    }

    final values = vitalSigns.map((vs) => vs.value1).toList();
    final average = values.reduce((a, b) => a + b) / values.length;
    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);

    // Calculate trend (compare first and last values)
    final firstValue = vitalSigns.last.value1; // Oldest
    final lastValue = vitalSigns.first.value1; // Latest
    final trend = lastValue > firstValue
        ? 'up'
        : lastValue < firstValue
        ? 'down'
        : 'stable';

    return {
      'count': vitalSigns.length,
      'average': average,
      'min': min,
      'max': max,
      'trend': trend,
    };
  }
}

// Vital sign list provider
final vitalSignListProvider =
    StateNotifierProvider<VitalSignListNotifier, VitalSignListState>((ref) {
      final repository = ref.watch(vitalSignRepositoryProvider);
      final notifier = VitalSignListNotifier(repository);
      
      // Listen for database changes for reactive updates
      ref.listen(databaseChangesStreamProvider, (previous, next) {
        if (next.hasValue) {
          final changes = next.value!;
          final hasVitalSignChanges = changes.any((c) => c.tableName == DatabaseConstants.tableVitalSigns);
          if (hasVitalSignChanges) {
            notifier.refresh();
          }
        }
      });
      
      return notifier;
    });

// Today's vital signs provider
final todaysVitalSignsProvider = Provider<List<VitalSign>>((ref) {
  ref.watch(vitalSignListProvider);
  final notifier = ref.read(vitalSignListProvider.notifier);
  return notifier.todaysVitalSigns;
});

// Latest vital signs provider
final latestVitalSignsProvider = Provider<Map<VitalSignType, VitalSign?>>((ref) {
  final state = ref.watch(vitalSignListProvider);
  return state.latestReadings;
});

// Vital sign statistics provider (7-day stats for all types)
final vitalSignStatisticsProvider =
    Provider<Map<VitalSignType, Map<String, dynamic>>>((ref) {
      ref.watch(vitalSignListProvider);
      final notifier = ref.read(vitalSignListProvider.notifier);

      final stats = <VitalSignType, Map<String, dynamic>>{};
      for (final type in VitalSignType.values) {
        stats[type] = notifier.getVitalSignStatistics(type, 7);
      }

      return stats;
    });

// Abnormal vital signs provider (vital signs outside target range)
final abnormalVitalSignsProvider = Provider<List<VitalSign>>((ref) {
  ref.watch(vitalSignListProvider);
  final notifier = ref.read(vitalSignListProvider.notifier);
  return notifier.filteredVitalSigns
      .where((vs) => !vs.isWithinTargetRange)
      .toList();
});

// Filtered vital signs provider
final filteredVitalSignsProvider = Provider<List<VitalSign>>((ref) {
  ref.watch(vitalSignListProvider);
  final notifier = ref.read(vitalSignListProvider.notifier);
  return notifier.filteredVitalSigns;
});