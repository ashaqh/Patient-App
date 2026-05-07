import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/timeline_repository_impl.dart';
import '../../domain/entities/timeline_item.dart';
import '../../domain/repositories/timeline_repository.dart';
import 'database_change_monitor_provider.dart';
import 'medicine_provider.dart'; // For databaseHelperProvider

// Timeline repository provider
final timelineRepositoryProvider = Provider<TimelineRepository>((ref) {
  final databaseHelper = ref.watch(databaseHelperProvider);
  return TimelineRepositoryImpl(databaseHelper);
});

// Timeline list state
class TimelineListState {
  final List<TimelineItem> items;
  final bool isLoading;
  final String? error;
  final DateTime? startDate;
  final DateTime? endDate;

  const TimelineListState({
    this.items = const [],
    this.isLoading = false,
    this.error,
    this.startDate,
    this.endDate,
  });

  TimelineListState copyWith({
    List<TimelineItem>? items,
    bool? isLoading,
    String? error,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return TimelineListState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is TimelineListState &&
        other.items.length == items.length &&
        other.items.every((item) => items.contains(item)) &&
        other.isLoading == isLoading &&
        other.error == error &&
        other.startDate == startDate &&
        other.endDate == endDate;
  }

  @override
  int get hashCode {
    return items.hashCode ^
        isLoading.hashCode ^
        error.hashCode ^
        startDate.hashCode ^
        endDate.hashCode;
  }

  @override
  String toString() {
    return 'TimelineListState(items: ${items.length}, isLoading: $isLoading, error: $error, startDate: $startDate, endDate: $endDate)';
  }
}

// Timeline list notifier
class TimelineListNotifier extends StateNotifier<TimelineListState> {
  final TimelineRepository _timelineRepository;

  TimelineListNotifier(this._timelineRepository)
      : super(const TimelineListState());

  // Load timeline items with optional date range
  Future<void> loadTimeline({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      final items = await _timelineRepository.getTimelineItems(
        startDate: startDate,
        endDate: endDate,
      );
      
      state = state.copyWith(
        items: items,
        isLoading: false,
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load timeline: $e',
      );
    }
  }

  // Load all timeline items (no date filter)
  Future<void> loadAllTimeline() async {
    await loadTimeline(startDate: null, endDate: null);
  }

  // Load today's timeline items
  Future<void> loadTodayTimeline() async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
    
    await loadTimeline(startDate: todayStart, endDate: todayEnd);
  }

  // Load this week's timeline items
  Future<void> loadThisWeekTimeline() async {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startDate = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    final endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
    
    await loadTimeline(startDate: startDate, endDate: endDate);
  }

  // Load this month's timeline items
  Future<void> loadThisMonthTimeline() async {
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, 1);
    final endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    
    await loadTimeline(startDate: startDate, endDate: endDate);
  }

  // Clear date filters
  Future<void> clearFilters() async {
    await loadAllTimeline();
  }

  // Refresh timeline
  Future<void> refresh() async {
    await loadTimeline(
      startDate: state.startDate,
      endDate: state.endDate,
    );
  }

  // Check if timeline is empty
  bool get isEmpty => state.items.isEmpty && !state.isLoading && state.error == null;

  // Get statistics
  Map<String, int> get statistics {
    final stats = <String, int>{
      'total': state.items.length,
      'medicines': state.items.where((item) => item.type == TimelineItemType.medicine).length,
      'prescriptions': state.items.where((item) => item.type == TimelineItemType.prescription).length,
      'followUps': state.items.where((item) => item.type == TimelineItemType.followUp).length,
      'reminderLogs': state.items.where((item) => item.type == TimelineItemType.reminderLog).length,
    };
    
    return stats;
  }

  // Group items by date
  Map<String, List<TimelineItem>> get groupedByDate {
    final groups = <String, List<TimelineItem>>{};
    
    for (final item in state.items) {
      final dateKey = _getDateKey(item.date);
      if (!groups.containsKey(dateKey)) {
        groups[dateKey] = [];
      }
      groups[dateKey]!.add(item);
    }
    
    // Sort groups by date (newest first)
    final sortedGroups = Map.fromEntries(
      groups.entries.toList()
        ..sort((a, b) => b.key.compareTo(a.key)),
    );
    
    return sortedGroups;
  }

  String _getDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // Get date display for a date key
  String getDateDisplay(String dateKey) {
    try {
      final parts = dateKey.split('-');
      if (parts.length != 3) return dateKey;
      
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final day = int.parse(parts[2]);
      
      final date = DateTime(year, month, day);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      if (date == today) {
        return 'Today';
      } else if (date == today.subtract(const Duration(days: 1))) {
        return 'Yesterday';
      } else if (date.isAfter(today.subtract(const Duration(days: 7)))) {
        final daysAgo = today.difference(date).inDays;
        return '$daysAgo days ago';
      } else {
        return '${day.toString().padLeft(2, '0')}/${month.toString().padLeft(2, '0')}/$year';
      }
    } catch (e) {
      return dateKey;
    }
  }
}

// Timeline list provider
final timelineListProvider = StateNotifierProvider<TimelineListNotifier, TimelineListState>((ref) {
  final timelineRepository = ref.watch(timelineRepositoryProvider);
  final notifier = TimelineListNotifier(timelineRepository);
  
  // Listen to database changes to refresh automatically
    ref.listen(
      databaseChangeMonitorProvider,
      (previous, next) {
        if (next != previous) {
          notifier.refresh();
        }
      },
    );
  
  return notifier;
});
