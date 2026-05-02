import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

import '../../domain/entities/medicine.dart';
import '../utils/error_utils.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  late FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;

  NotificationService._internal();

  // Initialize notification service
  Future<void> initialize() async {
    _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    // Initialize timezone database
    tz.initializeTimeZones();

    // Setup notification channels
    const AndroidInitializationSettings androidInitializationSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosInitializationSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: androidInitializationSettings,
      iOS: iosInitializationSettings,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    // Create notification channels
    await _createNotificationChannels();
  }

  // Create notification channels (Android 8.0+)
  Future<void> _createNotificationChannels() async {
    if (Platform.isAndroid) {
      const AndroidNotificationChannel medicineChannel =
          AndroidNotificationChannel(
        'medicine_reminders',
        'Medicine Reminders',
        description: 'Notifications for medicine reminders',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      );

      const AndroidNotificationChannel followUpChannel =
          AndroidNotificationChannel(
        'follow_up_reminders',
        'Follow-up Reminders',
        description: 'Notifications for follow-up appointments',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      );

      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(medicineChannel);

      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(followUpChannel);
    }
  }

  // Schedule a medicine reminder
  Future<void> scheduleMedicineReminder({
    required String id,
    required Medicine medicine,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    try {
      ErrorUtils.logInfo('=== scheduleMedicineReminder START ===');
      ErrorUtils.logInfo('Medicine: ${medicine.name} (ID: ${medicine.id})');
      ErrorUtils.logInfo('Requested scheduledTime (raw): ${scheduledTime.toIso8601String()}');
      ErrorUtils.logInfo('Requested scheduledTime (local): ${scheduledTime.toLocal().toIso8601String()}');
      ErrorUtils.logInfo('Requested scheduledTime (UTC): ${scheduledTime.toUtc().toIso8601String()}');
      
      final tz.TZDateTime scheduledTzTime =
          tz.TZDateTime.from(scheduledTime, tz.local);
      
      ErrorUtils.logInfo('Converted to TZDateTime: ${scheduledTzTime.toIso8601String()}');
      ErrorUtils.logInfo('Current time (DateTime.now()): ${DateTime.now().toIso8601String()}');
      ErrorUtils.logInfo('Current time (local): ${DateTime.now().toLocal().toIso8601String()}');
      ErrorUtils.logInfo('Current time (tz.local): ${tz.TZDateTime.now(tz.local).toIso8601String()}');
      ErrorUtils.logInfo('Time difference: ${scheduledTzTime.difference(tz.TZDateTime.now(tz.local)).inMinutes} minutes');
      ErrorUtils.logInfo('Will trigger in: ${scheduledTzTime.difference(tz.TZDateTime.now(tz.local))}');

      await _flutterLocalNotificationsPlugin.zonedSchedule(
        _generateNotificationId(id, scheduledTime),
        'Time for your medicine',
        '${medicine.name} - ${medicine.dosage}',
        scheduledTzTime,
        _getMedicineNotificationDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: payload ?? 'medicine|${medicine.id}|${scheduledTime.toIso8601String()}',
      );
      
      ErrorUtils.logInfo('Successfully scheduled notification for ${medicine.name}');
      ErrorUtils.logInfo('=== scheduleMedicineReminder END ===');
    } catch (e, stackTrace) {
      ErrorUtils.logError('Failed to schedule notification for ${medicine.name}', error: e, stackTrace: stackTrace, tag: 'NotificationService');
      rethrow;
    }
  }

  // Schedule multiple medicine reminders for a medicine
  Future<void> scheduleMedicineReminders(Medicine medicine) async {
    ErrorUtils.logInfo('scheduleMedicineReminders called for medicine: ${medicine.name}');
    ErrorUtils.logInfo('Medicine isActive: ${medicine.isActive}, shouldBeTakenToday: ${medicine.shouldBeTakenToday()}');
    ErrorUtils.logInfo('Medicine times: ${medicine.times}');
    
    if (!medicine.isActive || !medicine.shouldBeTakenToday()) {
      ErrorUtils.logInfo('Not scheduling reminders - medicine is not active or should not be taken today');
      return;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    ErrorUtils.logInfo('Current time: ${now.toIso8601String()}, Today: ${today.toIso8601String()}');
    
    bool hasScheduledToday = false;
    int scheduledCount = 0;

    for (final timeStr in medicine.times) {
      final parts = timeStr.split(':');
      if (parts.length != 2) {
        ErrorUtils.logInfo('Invalid time format: $timeStr');
        continue;
      }

      try {
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        final scheduledTime = DateTime(today.year, today.month, today.day, hour, minute);
        
        ErrorUtils.logInfo('Processing time $timeStr -> scheduledTime: ${scheduledTime.toIso8601String()}');
        ErrorUtils.logInfo('Is scheduledTime after now? ${scheduledTime.isAfter(now)}');

        // Only schedule future reminders for today
        if (scheduledTime.isAfter(now)) {
          ErrorUtils.logInfo('Scheduling notification for today at ${scheduledTime.toIso8601String()}');
          await scheduleMedicineReminder(
            id: medicine.id,
            medicine: medicine,
            scheduledTime: scheduledTime,
          );
          hasScheduledToday = true;
          scheduledCount++;
        } else {
          ErrorUtils.logInfo('Skipping time $timeStr - already passed today');
        }
      } catch (e) {
        ErrorUtils.logInfo('Error parsing time $timeStr: $e');
      }
    }
    
    ErrorUtils.logInfo('Scheduled $scheduledCount notifications for today');
    ErrorUtils.logInfo('hasScheduledToday: $hasScheduledToday, medicine.times.isNotEmpty: ${medicine.times.isNotEmpty}');
    
    // If no times were scheduled for today (all times have passed), schedule ALL times for tomorrow
    if (!hasScheduledToday && medicine.times.isNotEmpty) {
      ErrorUtils.logInfo('All times have passed today, scheduling ALL times for tomorrow');
      final tomorrow = today.add(const Duration(days: 1));
      int tomorrowScheduledCount = 0;
      
      for (final timeStr in medicine.times) {
        final parts = timeStr.split(':');
        if (parts.length != 2) continue;
        
        try {
          final hour = int.parse(parts[0]);
          final minute = int.parse(parts[1]);
          final scheduledTime = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, hour, minute);
          
          ErrorUtils.logInfo('Scheduling for tomorrow at ${scheduledTime.toIso8601String()}');
          
          await scheduleMedicineReminder(
            id: medicine.id,
            medicine: medicine,
            scheduledTime: scheduledTime,
          );
          
          tomorrowScheduledCount++;
        } catch (e) {
          ErrorUtils.logInfo('Error scheduling medicine time $timeStr for tomorrow: $e');
        }
      }
      
      ErrorUtils.logInfo('Scheduled $tomorrowScheduledCount notifications for tomorrow for medicine: ${medicine.name}');
    } else if (!hasScheduledToday) {
      ErrorUtils.logInfo('No times to schedule (medicine has no times or all times passed and no times available)');
    }
  }

  // Schedule follow-up reminder
  Future<void> scheduleFollowUpReminder({
    required String id,
    required String title,
    required DateTime scheduledTime,
    String? doctorName,
    String? location,
    String? payload,
  }) async {
    final tz.TZDateTime scheduledTzTime =
        tz.TZDateTime.from(scheduledTime, tz.local);

    String body = 'Appointment reminder';
    if (doctorName != null) {
      body += ' with Dr. $doctorName';
    }
    if (location != null) {
      body += ' at $location';
    }

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      _generateNotificationId(id, scheduledTime),
      'Follow-up Reminder: $title',
      body,
      scheduledTzTime,
      _getFollowUpNotificationDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
      payload: payload ?? 'followup|$id|${scheduledTime.toIso8601String()}',
    );
  }

  // Cancel a specific reminder
  Future<void> cancelReminder(String id, DateTime scheduledTime) async {
    await _flutterLocalNotificationsPlugin.cancel(
      _generateNotificationId(id, scheduledTime),
    );
  }

  // Cancel all reminders for a medicine
  Future<void> cancelMedicineReminders(String medicineId) async {
    final pendingNotifications =
        await _flutterLocalNotificationsPlugin.pendingNotificationRequests();

    for (final notification in pendingNotifications) {
      if (notification.payload != null &&
          notification.payload!.startsWith('medicine|$medicineId|')) {
        await _flutterLocalNotificationsPlugin.cancel(notification.id);
      }
    }
  }

  // Cancel all reminders for a follow-up
  Future<void> cancelFollowUpReminder(String followUpId) async {
    final pendingNotifications =
        await _flutterLocalNotificationsPlugin.pendingNotificationRequests();

    for (final notification in pendingNotifications) {
      if (notification.payload != null &&
          notification.payload!.startsWith('followup|$followUpId|')) {
        await _flutterLocalNotificationsPlugin.cancel(notification.id);
      }
    }
  }

  // Cancel all reminders
  Future<void> cancelAllReminders() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }

  // Get pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _flutterLocalNotificationsPlugin.pendingNotificationRequests();
  }
  
  // Log all pending notifications for debugging
  Future<void> logPendingNotifications() async {
    try {
      final pending = await getPendingNotifications();
      ErrorUtils.logInfo('=== PENDING NOTIFICATIONS (${pending.length}) ===');
      for (final notification in pending) {
        ErrorUtils.logInfo('ID: ${notification.id}, Title: ${notification.title}, Body: ${notification.body}');
        ErrorUtils.logInfo('Payload: ${notification.payload}, Scheduled for: ${notification.payload?.split('|').last ?? 'N/A'}');
      }
      ErrorUtils.logInfo('=== END PENDING NOTIFICATIONS ===');
    } catch (e) {
      ErrorUtils.logInfo('Error logging pending notifications: $e');
    }
  }
  
  // Test notification scheduled for 1 minute from now
  Future<void> scheduleTestNotification() async {
    try {
      ErrorUtils.logInfo('=== SCHEDULING TEST NOTIFICATION ===');
      final now = DateTime.now();
      final inOneMinute = now.add(const Duration(minutes: 1));
      
      ErrorUtils.logInfo('Current time: ${now.toIso8601String()}');
      ErrorUtils.logInfo('Scheduling test for: ${inOneMinute.toIso8601String()}');
      
      final tz.TZDateTime scheduledTzTime = tz.TZDateTime.from(inOneMinute, tz.local);
      ErrorUtils.logInfo('TZDateTime: ${scheduledTzTime.toIso8601String()}');
      
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        999999998, // Special ID for test notifications
        'Test Notification',
        'This is a test notification scheduled for 1 minute from now',
        scheduledTzTime,
        _getMedicineNotificationDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'test|notification|${now.toIso8601String()}',
      );
      
      ErrorUtils.logInfo('Test notification scheduled successfully!');
      ErrorUtils.logInfo('Check your device in 1 minute');
    } catch (e, stackTrace) {
      ErrorUtils.logError('Failed to schedule test notification', error: e, stackTrace: stackTrace);
    }
  }

  // Show immediate notification (for testing)
  Future<void> showTestNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    await _flutterLocalNotificationsPlugin.show(
      999999,
      title,
      body,
      _getMedicineNotificationDetails(),
      payload: payload,
    );
  }

  // Handle notification response (when user taps notification)
  void _onNotificationResponse(NotificationResponse response) {
    // This will be handled by the UI layer
    // The payload contains information about what was tapped
    ErrorUtils.logInfo('Notification tapped: ${response.payload}');
  }

  // Generate unique notification ID
  int _generateNotificationId(String id, DateTime time) {
    // Combine hash of ID and time to create unique ID
    final combined = '$id${time.millisecondsSinceEpoch}';
    return combined.hashCode.abs() % 2147483647; // Max Android notification ID
  }

  // Get notification details for medicine reminders
  NotificationDetails _getMedicineNotificationDetails() {
    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'medicine_reminders',
      'Medicine Reminders',
      channelDescription: 'Notifications for medicine reminders',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 500, 250, 500]),
      autoCancel: false,
      ongoing: true,
      showWhen: true,
      when: DateTime.now().millisecondsSinceEpoch,
      styleInformation: BigTextStyleInformation(''),
      actions: [
        AndroidNotificationAction(
          'taken_action',
          'Taken',
          showsUserInterface: false,
        ),
        AndroidNotificationAction(
          'snooze_action',
          'Snooze (10 min)',
          showsUserInterface: false,
        ),
        AndroidNotificationAction(
          'skip_action',
          'Skip',
          showsUserInterface: false,
        ),
      ],
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'default',
);

    return NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
  }

  // Get notification details for follow-up reminders
  NotificationDetails _getFollowUpNotificationDetails() {
    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'follow_up_reminders',
      'Follow-up Reminders',
      channelDescription: 'Notifications for follow-up appointments',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 500, 250, 500]),
      autoCancel: true,
      showWhen: true,
      when: DateTime.now().millisecondsSinceEpoch,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'default',
    );

    return NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
  }

  // Schedule daily reminder check
  Future<void> scheduleDailyReminderCheck() async {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final checkTime = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 0, 5); // 12:05 AM

    final tz.TZDateTime scheduledTzTime =
        tz.TZDateTime.from(checkTime, tz.local);

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      999999999,
      'Daily Reminder Check',
      'Checking for scheduled reminders...',
      scheduledTzTime,
      _getDailyCheckNotificationDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'daily_check',
    );
  }

  // Notification details for daily check
  NotificationDetails _getDailyCheckNotificationDetails() {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'medicine_reminders',
      'Medicine Reminders',
      channelDescription: 'Notifications for medicine reminders',
      importance: Importance.min,
      priority: Priority.min,
      playSound: false,
      enableVibration: false,
      autoCancel: true,
      showWhen: false,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: false,
      presentBadge: false,
      presentSound: false,
    );

    return const NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
  }

  // Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    if (Platform.isAndroid) {
      return true; // Android doesn't require permission for local notifications
    } else if (Platform.isIOS) {
      final result = await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
      return result ?? false;
    }
    return false;
  }

  // Get notification settings
  Future<Map<String, bool>> getNotificationSettings() async {
    // TODO: Implement this method when the plugin supports it
    // Currently getNotificationSettings() might not be available
    return {
      'alert': true,
      'badge': true,
      'sound': true,
    };
  }
}