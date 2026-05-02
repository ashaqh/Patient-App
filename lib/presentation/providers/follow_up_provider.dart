import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/reminder_scheduler.dart';
import '../../core/utils/error_utils.dart';
import '../../data/repositories/follow_up_repository_impl.dart';
import '../../domain/entities/follow_up.dart';
import '../../domain/repositories/follow_up_repository.dart';
import 'medicine_provider.dart'; // For databaseHelperProvider and reminderSchedulerProvider

// Follow-up repository provider
final followUpRepositoryProvider = Provider<FollowUpRepository>((ref) {
  final databaseHelper = ref.watch(databaseHelperProvider);
  return FollowUpRepositoryImpl(databaseHelper);
});

// Follow-up list state
class FollowUpListState {
  final List<FollowUp> followUps;
  final bool isLoading;
  final String? error;

  const FollowUpListState({
    this.followUps = const [],
    this.isLoading = false,
    this.error,
  });

  FollowUpListState copyWith({
    List<FollowUp>? followUps,
    bool? isLoading,
    String? error,
  }) {
    return FollowUpListState(
      followUps: followUps ?? this.followUps,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is FollowUpListState &&
        other.followUps.length == followUps.length &&
        other.followUps.every((followUp) => followUps.contains(followUp)) &&
        other.isLoading == isLoading &&
        other.error == error;
  }

  @override
  int get hashCode {
    return followUps.hashCode ^ isLoading.hashCode ^ error.hashCode;
  }
}

// Follow-up list notifier
class FollowUpListNotifier extends StateNotifier<FollowUpListState> {
  final FollowUpRepository _followUpRepository;
  final ReminderScheduler _reminderScheduler;

  FollowUpListNotifier(this._followUpRepository, this._reminderScheduler) : super(const FollowUpListState()) {
    _loadFollowUps();
  }

  // Load all follow-ups
  Future<void> _loadFollowUps() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final followUps = await _followUpRepository.getAllFollowUps();
      state = state.copyWith(followUps: followUps, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  // Add new follow-up
  Future<void> addFollowUp(FollowUp followUp) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await _followUpRepository.createFollowUp(followUp);
      
      // Schedule reminder for the new follow-up
      if (followUp.status == FollowUpStatus.scheduled) {
        await _scheduleFollowUpReminder(followUp);
      }
      
      await _loadFollowUps(); // Reload the list
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      rethrow;
    }
  }

  // Update follow-up
  Future<void> updateFollowUp(FollowUp followUp) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      // Get current follow-up to check if status changed
      final currentFollowUp = await _followUpRepository.getFollowUpById(followUp.id);
      
      await _followUpRepository.updateFollowUp(followUp);
      
      // Update reminders based on status changes
      if (currentFollowUp != null) {
        if (currentFollowUp.status == FollowUpStatus.scheduled && followUp.status != FollowUpStatus.scheduled) {
          // Follow-up was completed/cancelled/rescheduled, cancel reminders
          await _reminderScheduler.notificationService.cancelFollowUpReminder(followUp.id);
        } else if (currentFollowUp.status != FollowUpStatus.scheduled && followUp.status == FollowUpStatus.scheduled) {
          // Follow-up was rescheduled to scheduled, schedule reminders
          await _scheduleFollowUpReminder(followUp);
        } else if (followUp.status == FollowUpStatus.scheduled) {
          // Follow-up is still scheduled, reschedule reminders (in case date/time changed)
          await _reminderScheduler.notificationService.cancelFollowUpReminder(followUp.id);
          await _scheduleFollowUpReminder(followUp);
        }
      }
      
      await _loadFollowUps(); // Reload the list
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      rethrow;
    }
  }

  // Delete follow-up
  Future<void> deleteFollowUp(String id) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      // Cancel reminders before deleting follow-up
      await _reminderScheduler.notificationService.cancelFollowUpReminder(id);
      
      await _followUpRepository.deleteFollowUpById(id);
      await _loadFollowUps(); // Reload the list
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      rethrow;
    }
  }

  // Mark follow-up as completed
  Future<void> markAsCompleted(String id) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      await _followUpRepository.markFollowUpAsCompleted(id);
      
      // Cancel reminders since follow-up is completed
      await _reminderScheduler.notificationService.cancelFollowUpReminder(id);
      
      await _loadFollowUps(); // Reload the list
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      rethrow;
    }
  }

  // Update follow-up status
  Future<void> updateStatus(String id, FollowUpStatus status, {DateTime? completedAt}) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      await _followUpRepository.updateFollowUpStatus(id, status, completedAt: completedAt);
      
      // Update reminders based on new status
      if (status == FollowUpStatus.scheduled) {
        // Get the follow-up to schedule reminders
        final followUp = await _followUpRepository.getFollowUpById(id);
        if (followUp != null) {
          await _scheduleFollowUpReminder(followUp);
        }
      } else {
        // Cancel reminders for non-scheduled statuses
        await _reminderScheduler.notificationService.cancelFollowUpReminder(id);
      }
      
      await _loadFollowUps(); // Reload the list
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      rethrow;
    }
  }

  // Get upcoming follow-ups
  Future<List<FollowUp>> getUpcomingFollowUps({int? limit}) async {
    try {
      return await _followUpRepository.getUpcomingFollowUps(limit: limit);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return [];
    }
  }

  // Get overdue follow-ups
  Future<List<FollowUp>> getOverdueFollowUps() async {
    try {
      return await _followUpRepository.getOverdueFollowUps();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return [];
    }
  }

  // Get follow-ups for today
  Future<List<FollowUp>> getFollowUpsForToday() async {
    try {
      return await _followUpRepository.getFollowUpsForToday();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return [];
    }
  }

  // Search follow-ups
  Future<List<FollowUp>> searchFollowUps(String query) async {
    try {
      return await _followUpRepository.searchFollowUps(query);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return [];
    }
  }

  // Get follow-up statistics
  Future<Map<String, int>> getStatistics() async {
    try {
      return await _followUpRepository.getFollowUpStatistics();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return {};
    }
  }

  // Get next follow-up
  Future<FollowUp?> getNextFollowUp() async {
    try {
      return await _followUpRepository.getNextFollowUp();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  // Get follow-ups due in next N days
  Future<List<FollowUp>> getFollowUpsDueInNextNDays(int days) async {
    try {
      return await _followUpRepository.getFollowUpsDueInNextNDays(days);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return [];
    }
  }

  // Schedule follow-up reminder
  Future<void> _scheduleFollowUpReminder(FollowUp followUp) async {
    try {
      // Schedule reminder for 1 day before
      final dayBefore = followUp.date.subtract(const Duration(days: 1));
      await _reminderScheduler.scheduleFollowUpReminder(
        followUp.id,
        followUp.title,
        dayBefore,
      );

      // Schedule reminder for same day (morning)
      final sameDayMorning = DateTime(
        followUp.date.year,
        followUp.date.month,
        followUp.date.day,
        9, // 9 AM
      );
      await _reminderScheduler.scheduleFollowUpReminder(
        followUp.id,
        followUp.title,
        sameDayMorning,
      );
    } catch (e, stackTrace) {
      ErrorUtils.logError(
        'Error scheduling follow-up reminder',
        error: e,
        stackTrace: stackTrace,
        tag: 'FollowUp',
      );
    }
  }

  // Refresh follow-up list
  Future<void> refresh() async {
    await _loadFollowUps();
  }

  // Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Follow-up list provider
final followUpListProvider = StateNotifierProvider<FollowUpListNotifier, FollowUpListState>((ref) {
  final followUpRepository = ref.watch(followUpRepositoryProvider);
  final reminderScheduler = ref.watch(reminderSchedulerProvider);
  return FollowUpListNotifier(followUpRepository, reminderScheduler);
});

// Today's follow-ups provider
final todaysFollowUpsProvider = FutureProvider<List<FollowUp>>((ref) async {
  final followUpRepository = ref.watch(followUpRepositoryProvider);
  return await followUpRepository.getFollowUpsForToday();
});

// Upcoming follow-ups provider
final upcomingFollowUpsProvider = FutureProvider<List<FollowUp>>((ref) async {
  final followUpRepository = ref.watch(followUpRepositoryProvider);
  return await followUpRepository.getUpcomingFollowUps(limit: 5);
});

// Overdue follow-ups provider
final overdueFollowUpsProvider = FutureProvider<List<FollowUp>>((ref) async {
  final followUpRepository = ref.watch(followUpRepositoryProvider);
  return await followUpRepository.getOverdueFollowUps();
});

// Follow-up statistics provider
final followUpStatisticsProvider = FutureProvider<Map<String, int>>((ref) async {
  final followUpRepository = ref.watch(followUpRepositoryProvider);
  return await followUpRepository.getFollowUpStatistics();
});

// Next follow-up provider
final nextFollowUpProvider = FutureProvider<FollowUp?>((ref) async {
  final followUpRepository = ref.watch(followUpRepositoryProvider);
  return await followUpRepository.getNextFollowUp();
});

// Helper function to create a new follow-up
FollowUp createNewFollowUp({
  String? id,
  required String title,
  required DateTime date,
  String? notes,
  String? doctorName,
  String? clinicName,
  String? location,
  FollowUpStatus status = FollowUpStatus.scheduled,
  DateTime? completedAt,
}) {
  return FollowUp(
    id: id,
    title: title,
    date: date,
    notes: notes,
    doctorName: doctorName,
    clinicName: clinicName,
    location: location,
    status: status,
    completedAt: completedAt,
  );
}