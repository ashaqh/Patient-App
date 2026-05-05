import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/reminder_scheduler.dart';
import '../../domain/entities/reminder_log.dart';
import 'medicine_provider.dart';

// Reminder scheduler provider is now defined in medicine_provider.dart
// to avoid circular dependency with medicine_provider

// Reminder scheduler initialization provider
final reminderSchedulerInitializerProvider = FutureProvider<void>((ref) async {
  final reminderScheduler = ref.watch(reminderSchedulerProvider);
  await reminderScheduler.initialize();
});

// Today's reminders provider
final todaysRemindersProvider = FutureProvider<List<ReminderLog>>((ref) async {
  final reminderScheduler = ref.watch(reminderSchedulerProvider);
  return await reminderScheduler.getTodaysReminders();
});

// Reminder statistics provider
final reminderStatisticsProvider = FutureProvider<Map<String, int>>((ref) async {
  final reminderScheduler = ref.watch(reminderSchedulerProvider);
  return await reminderScheduler.getReminderStatistics();
});

// Reminder status updater provider
class ReminderStatusUpdater {
  final ReminderScheduler _reminderScheduler;

  ReminderStatusUpdater(this._reminderScheduler);

  // Mark reminder as taken
  Future<void> markAsTaken({
    required String medicineId,
    required DateTime scheduledTime,
    String? notes,
  }) async {
    await _reminderScheduler.markReminderAsTaken(
      medicineId: medicineId,
      scheduledTime: scheduledTime,
      notes: notes,
    );
  }

  // Mark reminder as skipped
  Future<void> markAsSkipped({
    required String medicineId,
    required DateTime scheduledTime,
    String? notes,
  }) async {
    await _reminderScheduler.markReminderAsSkipped(
      medicineId: medicineId,
      scheduledTime: scheduledTime,
      notes: notes,
    );
  }

  // Snooze reminder
  Future<void> snoozeReminder({
    required String medicineId,
    required DateTime originalTime,
    Duration snoozeDuration = const Duration(minutes: 10),
  }) async {
    await _reminderScheduler.snoozeReminder(
      medicineId: medicineId,
      originalTime: originalTime,
      snoozeDuration: snoozeDuration,
    );
  }

  // Schedule reminders for a medicine
  Future<void> scheduleMedicineReminders(String medicineId) async {
    // This would need access to medicine repository
    // For now, we'll rely on the medicine provider to trigger this
  }

  // Cancel reminders for a medicine
  Future<void> cancelMedicineReminders(String medicineId) async {
    final notificationService = _reminderScheduler.notificationService;
    await notificationService.cancelMedicineReminders(medicineId);
  }

  // Show test notification
  Future<void> showTestNotification() async {
    await _reminderScheduler.showTestNotification();
  }
  
  // Schedule test notification for 1 minute from now
  Future<void> scheduleTestNotification() async {
    await _reminderScheduler.scheduleTestNotification();
  }
}

// Reminder status updater provider
final reminderStatusUpdaterProvider = Provider<ReminderStatusUpdater>((ref) {
  final reminderScheduler = ref.watch(reminderSchedulerProvider);
  return ReminderStatusUpdater(reminderScheduler);
});

// Helper function to format reminder time
String formatReminderTime(DateTime time) {
  final hour = time.hour.toString().padLeft(2, '0');
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

// Helper function to get status display text
String getReminderStatusText(ReminderStatus status) {
  switch (status) {
    case ReminderStatus.taken:
      return 'Taken';
    case ReminderStatus.skipped:
      return 'Skipped';
    case ReminderStatus.missed:
      return 'Missed';
    case ReminderStatus.snoozed:
      return 'Snoozed';
    case ReminderStatus.pending:
      return 'Pending';
  }
}

// Helper function to get status color (for UI)
String getReminderStatusColor(ReminderStatus status) {
  switch (status) {
    case ReminderStatus.taken:
      return 'green';
    case ReminderStatus.skipped:
      return 'orange';
    case ReminderStatus.missed:
      return 'red';
    case ReminderStatus.snoozed:
      return 'blue';
    case ReminderStatus.pending:
      return 'gray';
  }
}

// Helper function to check if reminder is overdue
bool isReminderOverdue(ReminderLog reminder) {
  if (reminder.status != ReminderStatus.pending) {
    return false;
  }
  
  final now = DateTime.now();
  return reminder.scheduledTime.isBefore(now);
}

// Helper function to get time until reminder
Duration getTimeUntilReminder(ReminderLog reminder) {
  final now = DateTime.now();
  return reminder.scheduledTime.difference(now);
}

// Helper function to format time until reminder
String formatTimeUntilReminder(ReminderLog reminder) {
  if (reminder.status != ReminderStatus.pending) {
    return getReminderStatusText(reminder.status);
  }
  
  final duration = getTimeUntilReminder(reminder);
  
  if (duration.isNegative) {
    return 'Overdue';
  }
  
  if (duration.inDays > 0) {
    return 'In ${duration.inDays} day${duration.inDays > 1 ? 's' : ''}';
  }
  
  if (duration.inHours > 0) {
    return 'In ${duration.inHours} hour${duration.inHours > 1 ? 's' : ''}';
  }
  
  if (duration.inMinutes > 0) {
    return 'In ${duration.inMinutes} minute${duration.inMinutes > 1 ? 's' : ''}';
  }
  
  return 'Now';
}
