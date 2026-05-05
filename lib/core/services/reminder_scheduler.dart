import 'dart:async';

import '../../data/datasources/database_helper.dart';
import '../../data/repositories/medicine_repository_impl.dart';
import '../../data/repositories/reminder_log_repository_impl.dart';
import '../../domain/entities/medicine.dart';
import '../../domain/entities/reminder_log.dart';
import 'notification_service.dart';
import '../utils/error_utils.dart';

class ReminderScheduler {
  final DatabaseHelper _databaseHelper;
  final NotificationService _notificationService;
  late MedicineRepositoryImpl _medicineRepository;
  late ReminderLogRepositoryImpl _reminderLogRepository;

  Timer? _dailyCheckTimer;
  bool _isInitialized = false;

  ReminderScheduler(this._databaseHelper)
      : _notificationService = NotificationService() {
    _medicineRepository = MedicineRepositoryImpl(_databaseHelper);
    _reminderLogRepository = ReminderLogRepositoryImpl(_databaseHelper);
  }

  // Initialize the reminder scheduler
  Future<void> initialize() async {
    if (_isInitialized) {
      ErrorUtils.logInfo('Reminder scheduler already initialized');
      return;
    }

    ErrorUtils.logInfo('Initializing reminder scheduler...');
    await _notificationService.initialize();
    ErrorUtils.logInfo('Notification service initialized');
    
    await _rescheduleAllReminders();
    ErrorUtils.logInfo('All reminders rescheduled');
    
    await _startDailyCheckTimer();
    ErrorUtils.logInfo('Daily check timer started');
    
    // Log pending notifications for debugging
    await _notificationService.logPendingNotifications();
    
    _isInitialized = true;
    ErrorUtils.logInfo('Reminder scheduler initialized successfully');
  }

  // Schedule reminders for all active medicines
  Future<void> scheduleAllReminders() async {
    try {
      final activeMedicines = await _medicineRepository.getActiveMedicines();
      
      for (final medicine in activeMedicines) {
        await scheduleMedicineReminders(medicine);
      }
      
      ErrorUtils.logInfo('Scheduled reminders for ${activeMedicines.length} medicines');
    } catch (e) {
      ErrorUtils.logInfo('Error scheduling reminders: $e');
    }
  }

  // Schedule reminders for a specific medicine
  Future<void> scheduleMedicineReminders(Medicine medicine) async {
    try {
      if (!medicine.isActive) {
        await _notificationService.cancelMedicineReminders(medicine.id);
        return;
      }

      // Cancel existing reminders for this medicine
      await _notificationService.cancelMedicineReminders(medicine.id);

      // Schedule new reminders
      await _notificationService.scheduleMedicineReminders(medicine);

      // Create reminder log entries for scheduled reminders
      await _createReminderLogs(medicine);
      
      ErrorUtils.logInfo('Scheduled reminders for medicine: ${medicine.name}');
    } catch (e) {
      ErrorUtils.logInfo('Error scheduling reminders for ${medicine.name}: $e');
    }
  }

  // Create reminder log entries for scheduled reminders
  Future<void> _createReminderLogs(Medicine medicine) async {
    if (!medicine.isActive || !medicine.shouldBeTakenToday()) {
      return;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final todayEnd = DateTime(today.year, today.month, today.day, 23, 59, 59);
    final tomorrowEnd = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 23, 59, 59);

    // Get existing reminder logs for this medicine
    final allExistingLogs = await _reminderLogRepository.getReminderLogsByMedicineId(medicine.id);

    // Filter to only include logs for today and tomorrow to avoid false matches from other dates
    final existingLogs = allExistingLogs.where((log) {
      return (log.scheduledTime.isAfter(today.subtract(const Duration(seconds: 1))) &&
              log.scheduledTime.isBefore(tomorrowEnd.add(const Duration(seconds: 1))));
    }).toList();

    bool hasScheduledToday = false;
    DateTime? nextScheduledTime;

    // First, check for today's times
    for (final timeStr in medicine.times) {
      final parts = timeStr.split(':');
      if (parts.length != 2) continue;

      try {
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        final scheduledTime = DateTime(today.year, today.month, today.day, hour, minute);

        // Check if a reminder log already exists for this specific scheduled time (date AND time)
        bool logExists = existingLogs.any((log) =>
            log.scheduledTime.year == scheduledTime.year &&
            log.scheduledTime.month == scheduledTime.month &&
            log.scheduledTime.day == scheduledTime.day &&
            _isSameTime(log.scheduledTime, scheduledTime));

        // Only create logs for future reminders if they don't already exist
        if (!logExists && scheduledTime.isAfter(now)) {
          final reminderLog = ReminderLog(
            medicineId: medicine.id,
            medicineName: medicine.name,
            dosage: medicine.dosage,
            scheduledTime: scheduledTime,
            status: ReminderStatus.pending,
          );

          await _reminderLogRepository.createReminderLog(reminderLog);
          hasScheduledToday = true;
          ErrorUtils.logInfo('Created reminder log for today: ${medicine.name} at ${scheduledTime.toIso8601String()}');
        } else if (logExists) {
          hasScheduledToday = true;
        }

        // Track the next scheduled time
        if (scheduledTime.isAfter(now) && (nextScheduledTime == null || scheduledTime.isBefore(nextScheduledTime))) {
          nextScheduledTime = scheduledTime;
        }
      } catch (e) {
        ErrorUtils.logInfo('Error creating reminder log for time $timeStr: $e');
      }
    }

    // If no times were scheduled for today (all times have passed), create logs for ALL times tomorrow
    if (!hasScheduledToday && medicine.times.isNotEmpty) {
      ErrorUtils.logInfo('Creating reminder logs for ALL times tomorrow');
      int tomorrowLogCount = 0;

      for (final timeStr in medicine.times) {
        final parts = timeStr.split(':');
        if (parts.length != 2) continue;

        try {
          final hour = int.parse(parts[0]);
          final minute = int.parse(parts[1]);
          final scheduledTime = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, hour, minute);

          // Check if log already exists for this specific scheduled time
          bool logExists = existingLogs.any((log) =>
              log.scheduledTime.year == scheduledTime.year &&
              log.scheduledTime.month == scheduledTime.month &&
              log.scheduledTime.day == scheduledTime.day &&
              _isSameTime(log.scheduledTime, scheduledTime));

          if (!logExists) {
            final reminderLog = ReminderLog(
              medicineId: medicine.id,
              medicineName: medicine.name,
              dosage: medicine.dosage,
              scheduledTime: scheduledTime,
              status: ReminderStatus.pending,
            );

            await _reminderLogRepository.createReminderLog(reminderLog);
            tomorrowLogCount++;
            ErrorUtils.logInfo('Created reminder log for tomorrow: ${medicine.name} at ${scheduledTime.toIso8601String()}');
          }
        } catch (e) {
          ErrorUtils.logInfo('Error creating reminder log for time $timeStr tomorrow: $e');
        }
      }

      ErrorUtils.logInfo('Created $tomorrowLogCount reminder logs for tomorrow for medicine: ${medicine.name}');
    }
  }

  // Update reminder status when user responds to notification
  Future<void> updateReminderStatus({
    required String medicineId,
    required DateTime scheduledTime,
    required ReminderStatus status,
    String? notes,
  }) async {
    try {
      // Find the reminder log for this medicine and time
      final reminderLogs = await _reminderLogRepository.getReminderLogsByMedicineId(medicineId);
      
      for (final log in reminderLogs) {
        if (_isSameTime(log.scheduledTime, scheduledTime)) {
          final updatedLog = log.copyWith(
            status: status,
            actualTime: DateTime.now(),
            notes: notes,
          );
          
          await _reminderLogRepository.updateReminderLog(updatedLog);
          ErrorUtils.logInfo('Updated reminder status to: ${status.displayName}');
          break;
        }
      }
    } catch (e) {
      ErrorUtils.logInfo('Error updating reminder status: $e');
    }
  }

  // Mark reminder as taken
  Future<void> markReminderAsTaken({
    required String medicineId,
    required DateTime scheduledTime,
    String? notes,
  }) async {
    await updateReminderStatus(
      medicineId: medicineId,
      scheduledTime: scheduledTime,
      status: ReminderStatus.taken,
      notes: notes,
    );
  }

  // Mark reminder as skipped
  Future<void> markReminderAsSkipped({
    required String medicineId,
    required DateTime scheduledTime,
    String? notes,
  }) async {
    await updateReminderStatus(
      medicineId: medicineId,
      scheduledTime: scheduledTime,
      status: ReminderStatus.skipped,
      notes: notes,
    );
  }

  // Snooze reminder (reschedule for later)
  Future<void> snoozeReminder({
    required String medicineId,
    required DateTime originalTime,
    Duration snoozeDuration = const Duration(minutes: 10),
  }) async {
    try {
      final medicine = await _medicineRepository.getMedicineById(medicineId);
      if (medicine == null) return;

      final newTime = DateTime.now().add(snoozeDuration);
      
      // Schedule new reminder
      await _notificationService.scheduleMedicineReminder(
        id: medicineId,
        medicine: medicine,
        scheduledTime: newTime,
        payload: 'medicine|$medicineId|${newTime.toIso8601String()}|snoozed',
      );

      // Update reminder log status
      await updateReminderStatus(
        medicineId: medicineId,
        scheduledTime: originalTime,
        status: ReminderStatus.snoozed,
        notes: 'Snoozed for ${snoozeDuration.inMinutes} minutes',
      );

      // Create new reminder log for snoozed time
      final snoozedLog = ReminderLog(
        medicineId: medicine.id,
        medicineName: medicine.name,
        dosage: medicine.dosage,
        scheduledTime: newTime,
        status: ReminderStatus.pending,
        notes: 'Snoozed from ${originalTime.toIso8601String()}',
      );

      await _reminderLogRepository.createReminderLog(snoozedLog);
      
      ErrorUtils.logInfo('Snoozed reminder for ${medicine.name} to ${newTime.toIso8601String()}');
    } catch (e) {
      ErrorUtils.logInfo('Error snoozing reminder: $e');
    }
  }

  // Check for missed reminders
  Future<void> checkForMissedReminders() async {
    try {
      final pendingReminders = await _reminderLogRepository.getReminderLogsByStatus(ReminderStatus.pending);
      final now = DateTime.now();

      for (final reminder in pendingReminders) {
        // If reminder was scheduled for more than 30 minutes ago, mark as missed
        if (reminder.scheduledTime.isBefore(now.subtract(const Duration(minutes: 30)))) {
          final updatedReminder = reminder.copyWith(
            status: ReminderStatus.missed,
            notes: 'Automatically marked as missed',
          );
          
          await _reminderLogRepository.updateReminderLog(updatedReminder);
          ErrorUtils.logInfo('Marked missed reminder: ${reminder.medicineName} at ${reminder.scheduledTime.toIso8601String()}');
        }
      }
    } catch (e) {
      ErrorUtils.logInfo('Error checking for missed reminders: $e');
    }
  }

  // Reschedule all reminders (e.g., after app update or time change)
  Future<void> _rescheduleAllReminders() async {
    try {
      await _notificationService.cancelAllReminders();
      await scheduleAllReminders();
      await _notificationService.scheduleDailyReminderCheck();
      
      ErrorUtils.logInfo('Rescheduled all reminders');
    } catch (e) {
      ErrorUtils.logInfo('Error rescheduling reminders: $e');
    }
  }

  // Start daily check timer
  Future<void> _startDailyCheckTimer() async {
    // Cancel existing timer
    _dailyCheckTimer?.cancel();

    // Calculate time until midnight
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final timeUntilMidnight = tomorrow.difference(now);

    // Schedule timer for midnight
    _dailyCheckTimer = Timer(timeUntilMidnight, () async {
      await _handleDailyCheck();
      _startDailyCheckTimer(); // Restart timer for next day
    });

    ErrorUtils.logInfo('Daily check timer started, will run in ${timeUntilMidnight.inHours} hours ${timeUntilMidnight.inMinutes % 60} minutes');
  }

  // Handle daily check (run at midnight)
  Future<void> _handleDailyCheck() async {
    ErrorUtils.logInfo('Running daily reminder check...');
    
    try {
      // Check for missed reminders from previous day
      await checkForMissedReminders();
      
      // Schedule reminders for today
      await scheduleAllReminders();
      
      ErrorUtils.logInfo('Daily check completed successfully');
    } catch (e) {
      ErrorUtils.logInfo('Error during daily check: $e');
    }
  }

  // Get today's reminders
  Future<List<ReminderLog>> getTodaysReminders() async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

      return await _reminderLogRepository.getReminderLogsByDateRange(startOfDay, endOfDay);
    } catch (e) {
      ErrorUtils.logError('Error getting today\'s reminders', error: e, tag: 'ReminderScheduler');
      return [];
    }
  }

  // Get reminder statistics
  Future<Map<String, int>> getReminderStatistics() async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

      final todaysReminders = await _reminderLogRepository.getReminderLogsByDateRange(startOfDay, endOfDay);

      final statistics = <String, int>{
        'total': todaysReminders.length,
        'taken': 0,
        'skipped': 0,
        'missed': 0,
        'pending': 0,
        'snoozed': 0,
      };

      for (final reminder in todaysReminders) {
        switch (reminder.status) {
          case ReminderStatus.taken:
            statistics['taken'] = statistics['taken']! + 1;
            break;
          case ReminderStatus.skipped:
            statistics['skipped'] = statistics['skipped']! + 1;
            break;
          case ReminderStatus.missed:
            statistics['missed'] = statistics['missed']! + 1;
            break;
          case ReminderStatus.pending:
            statistics['pending'] = statistics['pending']! + 1;
            break;
          case ReminderStatus.snoozed:
            statistics['snoozed'] = statistics['snoozed']! + 1;
            break;
        }
      }

      return statistics;
    } catch (e) {
      ErrorUtils.logInfo('Error getting reminder statistics: $e');
      return {
        'total': 0,
        'taken': 0,
        'skipped': 0,
        'missed': 0,
        'pending': 0,
        'snoozed': 0,
      };
    }
  }

  // Check if two times are the same (within 1 minute tolerance)
  bool _isSameTime(DateTime time1, DateTime time2) {
    return (time1.difference(time2).inMinutes.abs() <= 1);
  }

  // Dispose resources
  void dispose() {
    _dailyCheckTimer?.cancel();
    _dailyCheckTimer = null;
    _isInitialized = false;
  }

  // Schedule follow-up reminder
  Future<void> scheduleFollowUpReminder(
    String followUpId,
    String title,
    DateTime scheduledTime,
    {String? payload}
  ) async {
    try {
      await _notificationService.scheduleFollowUpReminder(
        id: followUpId,
        title: title,
        scheduledTime: scheduledTime,
        payload: payload,
      );
      ErrorUtils.logInfo('Scheduled follow-up reminder: $title at ${scheduledTime.toIso8601String()}');
    } catch (e) {
      ErrorUtils.logInfo('Error scheduling follow-up reminder: $e');
    }
  }

  // Cancel follow-up reminder
  Future<void> cancelFollowUpReminder(String followUpId) async {
    try {
      await _notificationService.cancelFollowUpReminder(followUpId);
      ErrorUtils.logInfo('Cancelled follow-up reminders for ID: $followUpId');
    } catch (e) {
      ErrorUtils.logInfo('Error cancelling follow-up reminders: $e');
    }
  }

  // Schedule follow-up reminders (1 day before and same day)
  Future<void> scheduleFollowUpReminders(
    String followUpId,
    String title,
    DateTime appointmentDate,
  ) async {
    try {
      // Schedule reminder for 1 day before
      final dayBefore = appointmentDate.subtract(const Duration(days: 1));
      await scheduleFollowUpReminder(
        followUpId,
        title,
        dayBefore,
        payload: 'followup|$followUpId|reminder|day_before',
      );

      // Schedule reminder for same day (morning)
      final sameDayMorning = DateTime(
        appointmentDate.year,
        appointmentDate.month,
        appointmentDate.day,
        9, // 9 AM
      );
      await scheduleFollowUpReminder(
        followUpId,
        title,
        sameDayMorning,
        payload: 'followup|$followUpId|reminder|same_day',
      );

      ErrorUtils.logInfo('Scheduled follow-up reminders for: $title');
    } catch (e) {
      ErrorUtils.logInfo('Error scheduling follow-up reminders: $e');
    }
  }

// Test method to show immediate notification
  Future<void> showTestNotification() async {
    await _notificationService.showTestNotification(
      title: 'CareVault Test',
      body: 'This is a test notification from CareVault',
      payload: 'test|notification',
    );
  }
  
  // Test method to schedule notification for 1 minute from now
  Future<void> scheduleTestNotification() async {
    ErrorUtils.logInfo('Scheduling test notification for 1 minute from now...');
    await _notificationService.scheduleTestNotification();
  }

  // Check if scheduler is initialized
  bool get isInitialized => _isInitialized;

  // Get notification service (for UI integration)
  NotificationService get notificationService => _notificationService;
}
