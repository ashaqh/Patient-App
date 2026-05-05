import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

import '../../domain/entities/medicine.dart';
import '../utils/error_utils.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  static const int medicineReminderScheduleDays = 7;
  static const String alarmReminderChannelId = 'alarm_reminders_v1';
  static const String _alarmReminderChannelName = 'Alarm Reminders';
  static const String _alarmReminderChannelDescription =
      'Urgent reminders that can appear full screen and use alarm audio';
  static const String _takenActionId = 'taken_action';
  static const String _snoozeActionId = 'snooze_action';
  static const String _skipActionId = 'skip_action';
  static List<AndroidNotificationAction> _medicineReminderActions = [
    AndroidNotificationAction(
      _takenActionId,
      'Taken',
      showsUserInterface: false,
    ),
    AndroidNotificationAction(
      _snoozeActionId,
      'Snooze (10 min)',
      showsUserInterface: false,
    ),
    AndroidNotificationAction(_skipActionId, 'Skip', showsUserInterface: false),
  ];

  static void Function(NotificationResponse)? onNotificationResponseCallback;

  factory NotificationService() => _instance;

  late FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;
  bool _isInitialized = false;

  NotificationService._internal();

  static List<DateTime> buildMedicineReminderSchedule(
    Medicine medicine, {
    required DateTime now,
    int daysAhead = medicineReminderScheduleDays,
  }) {
    if (!medicine.isActive || medicine.times.isEmpty || daysAhead < 1) {
      return const [];
    }

    final startDay = DateTime(now.year, now.month, now.day);
    final scheduledTimes = <DateTime>[];

    for (var dayOffset = 0; dayOffset < daysAhead; dayOffset++) {
      final day = startDay.add(Duration(days: dayOffset));
      if (_isBeforeDateOnly(day, medicine.startDate)) {
        continue;
      }
      if (medicine.endDate != null &&
          _isAfterDateOnly(day, medicine.endDate!)) {
        continue;
      }

      for (final timeStr in medicine.times) {
        final time = _parseReminderTime(timeStr);
        if (time == null) {
          ErrorUtils.logInfo('Invalid medicine reminder time: $timeStr');
          continue;
        }

        final scheduledTime = DateTime(
          day.year,
          day.month,
          day.day,
          time.$1,
          time.$2,
        );

        if (scheduledTime.isAfter(now)) {
          scheduledTimes.add(scheduledTime);
        }
      }
    }

    scheduledTimes.sort();
    return scheduledTimes;
  }

  static (int, int)? _parseReminderTime(String timeStr) {
    final parts = timeStr.split(':');
    if (parts.length != 2) return null;

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;

    return (hour, minute);
  }

  static bool _isBeforeDateOnly(DateTime day, DateTime compareTo) {
    final compareDay = DateTime(compareTo.year, compareTo.month, compareTo.day);
    return day.isBefore(compareDay);
  }

  static bool _isAfterDateOnly(DateTime day, DateTime compareTo) {
    final compareDay = DateTime(compareTo.year, compareTo.month, compareTo.day);
    return day.isAfter(compareDay);
  }

  static AndroidNotificationChannel buildAlarmReminderChannel() {
    return AndroidNotificationChannel(
      alarmReminderChannelId,
      _alarmReminderChannelName,
      description: _alarmReminderChannelDescription,
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 750, 250, 750, 250, 750]),
      showBadge: true,
      audioAttributesUsage: AudioAttributesUsage.alarm,
    );
  }

  static AndroidNotificationDetails buildAndroidAlarmNotificationDetails({
    required bool ongoing,
    List<AndroidNotificationAction>? actions,
  }) {
    return AndroidNotificationDetails(
      alarmReminderChannelId,
      _alarmReminderChannelName,
      channelDescription: _alarmReminderChannelDescription,
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 750, 250, 750, 250, 750]),
      autoCancel: !ongoing,
      ongoing: ongoing,
      showWhen: true,
      category: AndroidNotificationCategory.alarm,
      fullScreenIntent: true,
      visibility: NotificationVisibility.public,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      styleInformation: const BigTextStyleInformation(''),
      actions: actions,
    );
  }

  static DarwinNotificationDetails buildIosAlarmNotificationDetails() {
    return const DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      presentBanner: true,
      presentList: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );
  }

  static NotificationDetails buildAlarmNotificationDetails({
    required bool ongoing,
    List<AndroidNotificationAction>? androidActions,
  }) {
    return NotificationDetails(
      android: buildAndroidAlarmNotificationDetails(
        ongoing: ongoing,
        actions: androidActions,
      ),
      iOS: buildIosAlarmNotificationDetails(),
    );
  }

  // Initialize notification service
  Future<void> initialize() async {
    if (_isInitialized) {
      ErrorUtils.logInfo('NotificationService already initialized, skipping');
      return;
    }

    _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    await _configureLocalTimeZone();

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

    _isInitialized = true;
    ErrorUtils.logInfo('NotificationService initialized successfully');
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

      final alarmChannel = buildAlarmReminderChannel();

      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(medicineChannel);

      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(followUpChannel);

      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(alarmChannel);
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
      ErrorUtils.logInfo(
        'Requested scheduledTime (raw): ${scheduledTime.toIso8601String()}',
      );
      ErrorUtils.logInfo(
        'Requested scheduledTime (local): ${scheduledTime.toLocal().toIso8601String()}',
      );
      ErrorUtils.logInfo(
        'Requested scheduledTime (UTC): ${scheduledTime.toUtc().toIso8601String()}',
      );

      if (scheduledTime.isBefore(DateTime.now())) {
        ErrorUtils.logInfo(
          'Skipping past medicine reminder for ${medicine.name}: ${scheduledTime.toIso8601String()}',
        );
        return;
      }

      final tz.TZDateTime scheduledTzTime = tz.TZDateTime.from(
        scheduledTime,
        tz.local,
      );

      ErrorUtils.logInfo(
        'Converted to TZDateTime: ${scheduledTzTime.toIso8601String()}',
      );
      ErrorUtils.logInfo(
        'Current time (DateTime.now()): ${DateTime.now().toIso8601String()}',
      );
      ErrorUtils.logInfo(
        'Current time (local): ${DateTime.now().toLocal().toIso8601String()}',
      );
      ErrorUtils.logInfo(
        'Current time (tz.local): ${tz.TZDateTime.now(tz.local).toIso8601String()}',
      );
      ErrorUtils.logInfo(
        'Time difference: ${scheduledTzTime.difference(tz.TZDateTime.now(tz.local)).inMinutes} minutes',
      );
      ErrorUtils.logInfo(
        'Will trigger in: ${scheduledTzTime.difference(tz.TZDateTime.now(tz.local))}',
      );

      await _flutterLocalNotificationsPlugin.zonedSchedule(
        _generateNotificationId(id, scheduledTime),
        'Time for your medicine',
        '${medicine.name} - ${medicine.dosage}',
        scheduledTzTime,
        _getMedicineNotificationDetails(),
        androidScheduleMode: await _getAndroidScheduleMode(),
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload:
            payload ??
            'medicine|${medicine.id}|${scheduledTime.toIso8601String()}',
      );

      ErrorUtils.logInfo(
        'Successfully scheduled notification for ${medicine.name}',
      );
      ErrorUtils.logInfo('=== scheduleMedicineReminder END ===');
    } catch (e, stackTrace) {
      ErrorUtils.logError(
        'Failed to schedule notification for ${medicine.name}',
        error: e,
        stackTrace: stackTrace,
        tag: 'NotificationService',
      );
      rethrow;
    }
  }

  // Schedule multiple medicine reminders for a medicine
  Future<void> scheduleMedicineReminders(Medicine medicine) async {
    ErrorUtils.logInfo(
      'scheduleMedicineReminders called for medicine: ${medicine.name}',
    );
    ErrorUtils.logInfo('Medicine isActive: ${medicine.isActive}');
    ErrorUtils.logInfo('Medicine times: ${medicine.times}');

    if (!medicine.isActive) {
      ErrorUtils.logInfo('Not scheduling reminders - medicine is not active');
      return;
    }

    final now = DateTime.now();
    final schedule = buildMedicineReminderSchedule(medicine, now: now);

    ErrorUtils.logInfo(
      'Scheduling ${schedule.length} notifications across $medicineReminderScheduleDays days',
    );

    for (final scheduledTime in schedule) {
      await scheduleMedicineReminder(
        id: medicine.id,
        medicine: medicine,
        scheduledTime: scheduledTime,
      );
    }
  }

  Future<void> _configureLocalTimeZone() async {
    tz.initializeTimeZones();

    if (!Platform.isAndroid && !Platform.isIOS && !Platform.isMacOS) {
      ErrorUtils.logInfo(
        'Using default timezone database location: ${tz.local.name}',
      );
      return;
    }

    try {
      final timeZoneInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneInfo.identifier));
      ErrorUtils.logInfo('Configured notification timezone: ${tz.local.name}');
    } catch (e, stackTrace) {
      ErrorUtils.logError(
        'Failed to configure local notification timezone; using ${tz.local.name}',
        error: e,
        stackTrace: stackTrace,
        tag: 'NotificationService',
      );
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
    if (scheduledTime.isBefore(DateTime.now())) {
      ErrorUtils.logInfo(
        'Skipping past follow-up reminder $id at ${scheduledTime.toIso8601String()}',
      );
      return;
    }

    final tz.TZDateTime scheduledTzTime = tz.TZDateTime.from(
      scheduledTime,
      tz.local,
    );

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
      androidScheduleMode: await _getAndroidScheduleMode(),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload ?? 'followup|$id|${scheduledTime.toIso8601String()}',
    );
  }

  Future<AndroidScheduleMode> _getAndroidScheduleMode() async {
    if (!Platform.isAndroid) {
      return AndroidScheduleMode.exactAllowWhileIdle;
    }

    final androidPlugin = _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final canScheduleExact =
        await androidPlugin?.canScheduleExactNotifications() ?? true;

    if (canScheduleExact) {
      return AndroidScheduleMode.exactAllowWhileIdle;
    }

    ErrorUtils.logInfo(
      'Exact alarms are not permitted; scheduling inexact allow-while-idle notification',
    );
    return AndroidScheduleMode.inexactAllowWhileIdle;
  }

  // Cancel a specific reminder
  Future<void> cancelReminder(String id, DateTime scheduledTime) async {
    await _flutterLocalNotificationsPlugin.cancel(
      _generateNotificationId(id, scheduledTime),
    );
  }

  // Cancel all reminders for a medicine
  Future<void> cancelMedicineReminders(String medicineId) async {
    final pendingNotifications = await _flutterLocalNotificationsPlugin
        .pendingNotificationRequests();

    for (final notification in pendingNotifications) {
      if (notification.payload != null &&
          notification.payload!.startsWith('medicine|$medicineId|')) {
        await _flutterLocalNotificationsPlugin.cancel(notification.id);
      }
    }
  }

  // Cancel all reminders for a follow-up
  Future<void> cancelFollowUpReminder(String followUpId) async {
    final pendingNotifications = await _flutterLocalNotificationsPlugin
        .pendingNotificationRequests();

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
        ErrorUtils.logInfo(
          'ID: ${notification.id}, Title: ${notification.title}, Body: ${notification.body}',
        );
        ErrorUtils.logInfo(
          'Payload: ${notification.payload}, Scheduled for: ${notification.payload?.split('|').last ?? 'N/A'}',
        );
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
      ErrorUtils.logInfo(
        'Scheduling test for: ${inOneMinute.toIso8601String()}',
      );

      final tz.TZDateTime scheduledTzTime = tz.TZDateTime.from(
        inOneMinute,
        tz.local,
      );
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
      ErrorUtils.logError(
        'Failed to schedule test notification',
        error: e,
        stackTrace: stackTrace,
      );
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
    ErrorUtils.logInfo('Notification tapped: ${response.payload}');
    onNotificationResponseCallback?.call(response);
  }

  // Generate unique notification ID
  int _generateNotificationId(String id, DateTime time) {
    // Combine hash of ID and time to create unique ID
    final combined = '$id${time.millisecondsSinceEpoch}';
    return combined.hashCode.abs() % 2147483647; // Max Android notification ID
  }

  // Get notification details for medicine reminders
  NotificationDetails _getMedicineNotificationDetails() {
    return buildAlarmNotificationDetails(
      ongoing: true,
      androidActions: _medicineReminderActions,
    );
  }

  // Get notification details for follow-up reminders
  NotificationDetails _getFollowUpNotificationDetails() {
    return buildAlarmNotificationDetails(ongoing: false);
  }

  // Schedule daily reminder check
  Future<void> scheduleDailyReminderCheck() async {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final checkTime = DateTime(
      tomorrow.year,
      tomorrow.month,
      tomorrow.day,
      0,
      5,
    ); // 12:05 AM

    final tz.TZDateTime scheduledTzTime = tz.TZDateTime.from(
      checkTime,
      tz.local,
    );

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

    return const NotificationDetails(android: androidDetails, iOS: iosDetails);
  }

  // Request notification permissions (MUST be called on Android 13+ and iOS)
  Future<bool> requestNotificationPermissions() async {
    if (Platform.isAndroid) {
      final androidPlugin = _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (androidPlugin == null) return false;

      // Request POST_NOTIFICATIONS permission (Android 13+)
      final notificationGranted = await androidPlugin
          .requestNotificationsPermission();
      ErrorUtils.logInfo(
        'Android notification permission granted: $notificationGranted',
      );

      // Check if exact alarms are allowed (Android 12+)
      final exactAlarmGranted = await androidPlugin
          .canScheduleExactNotifications();
      ErrorUtils.logInfo(
        'Android exact alarm permission granted: $exactAlarmGranted',
      );

      if (exactAlarmGranted != true) {
        // Request exact alarm permission
        await androidPlugin.requestExactAlarmsPermission();
        ErrorUtils.logInfo('Requested exact alarm permission from user');
      }

      final fullScreenIntentGranted = await androidPlugin
          .requestFullScreenIntentPermission();
      ErrorUtils.logInfo(
        'Android full-screen intent permission granted: $fullScreenIntentGranted',
      );

      return notificationGranted ?? false;
    } else if (Platform.isIOS) {
      final result = await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      return result ?? false;
    }
    return false;
  }

  // Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    if (Platform.isAndroid) {
      final androidPlugin = _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (androidPlugin == null) return false;

      final granted = await androidPlugin.areNotificationsEnabled();
      return granted ?? false;
    } else if (Platform.isIOS) {
      // On iOS, we can't check without requesting — return true as a safe default
      return true;
    }
    return false;
  }

  // Get notification settings
  Future<Map<String, bool>> getNotificationSettings() async {
    final enabled = await areNotificationsEnabled();
    bool exactAlarms = false;

    if (Platform.isAndroid) {
      final androidPlugin = _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      exactAlarms =
          await androidPlugin?.canScheduleExactNotifications() ?? false;
    }

    return {'notifications_enabled': enabled, 'exact_alarms': exactAlarms};
  }
}
