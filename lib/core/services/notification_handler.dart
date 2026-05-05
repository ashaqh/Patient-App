import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../utils/error_utils.dart';
import 'notification_service.dart';
import 'reminder_scheduler.dart';

class NotificationHandler {
  final NotificationService _notificationService;
  final ReminderScheduler _reminderScheduler;

  NotificationHandler(this._notificationService, this._reminderScheduler);

  // Handle notification response
  Future<void> handleNotificationResponse(NotificationResponse response) async {
    final payload = response.payload;
    if (payload == null) return;

    ErrorUtils.logInfo('Notification tapped: $payload', tag: 'Notification');

    // Parse payload
    final parts = payload.split('|');
    if (parts.length < 3) return;

    final type = parts[0];
    final id = parts[1];
    final timeString = parts[2];

    try {
      final scheduledTime = DateTime.parse(timeString);

      if (type == 'medicine') {
        // Check if this was an action (taken/skip/snooze)
        if (response.actionId != null) {
          await _handleMedicineAction(
            actionId: response.actionId!,
            medicineId: id,
            scheduledTime: scheduledTime,
            payload: payload,
          );
        } else {
          // User tapped the notification body
          await _handleMedicineNotificationTap(
            medicineId: id,
            scheduledTime: scheduledTime,
          );
        }
      } else if (type == 'followup') {
        await _handleFollowUpNotificationTap(
          followUpId: id,
          scheduledTime: scheduledTime,
        );
      } else if (type == 'test') {
        await _handleTestNotificationTap();
      }
    } catch (e) {
      ErrorUtils.logError('Error handling notification response', error: e, tag: 'Notification');
    }
  }

  // Handle medicine notification actions
  Future<void> _handleMedicineAction({
    required String actionId,
    required String medicineId,
    required DateTime scheduledTime,
    required String payload,
  }) async {
    switch (actionId) {
      case 'taken_action':
        await _reminderScheduler.markReminderAsTaken(
          medicineId: medicineId,
          scheduledTime: scheduledTime,
          notes: 'Marked as taken via notification',
        );
        break;
      case 'skip_action':
        await _reminderScheduler.markReminderAsSkipped(
          medicineId: medicineId,
          scheduledTime: scheduledTime,
          notes: 'Skipped via notification',
        );
        break;
      case 'snooze_action':
        await _reminderScheduler.snoozeReminder(
          medicineId: medicineId,
          originalTime: scheduledTime,
          snoozeDuration: const Duration(minutes: 10),
        );
        break;
      default:
        ErrorUtils.logInfo('Unknown action: $actionId');
    }

    // Cancel the original notification
    await _notificationService.cancelReminder(medicineId, scheduledTime);
  }

  // Handle medicine notification tap (user tapped notification body)
  Future<void> _handleMedicineNotificationTap({
    required String medicineId,
    required DateTime scheduledTime,
  }) async {
    // In a real app, this would navigate to the medicine details screen
    // or show a dialog to mark the reminder
    ErrorUtils.logInfo('Medicine notification tapped: $medicineId at $scheduledTime');
    
    // For now, we'll just mark it as taken
    await _reminderScheduler.markReminderAsTaken(
      medicineId: medicineId,
      scheduledTime: scheduledTime,
      notes: 'Marked as taken via notification tap',
    );
    
    // Cancel the notification
    await _notificationService.cancelReminder(medicineId, scheduledTime);
  }

  // Handle follow-up notification tap
  Future<void> _handleFollowUpNotificationTap({
    required String followUpId,
    required DateTime scheduledTime,
  }) async {
    // In a real app, this would navigate to the follow-up details screen
    ErrorUtils.logInfo('Follow-up notification tapped: $followUpId at $scheduledTime');
    
    // Cancel the notification
    await _notificationService.cancelReminder(followUpId, scheduledTime);
  }

  // Handle test notification tap
  Future<void> _handleTestNotificationTap() async {
    ErrorUtils.logInfo('Test notification tapped');
  }

  // Initialize notification handling
  Future<void> initialize() async {
    // The notification service already has the onDidReceiveNotificationResponse callback
    // We need to make sure it's connected to this handler
    // This would typically be set up in main.dart
  }

  // Show test notification with actions
  Future<void> showTestNotificationWithActions() async {
    await _notificationService.showTestNotification(
      title: 'Test Reminder with Actions',
      body: 'Tap an action below to test',
      payload: 'test|notification|${DateTime.now().toIso8601String()}',
    );
  }
}
