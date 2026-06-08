import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Delay used to allow the app-init step to complete before navigating away

import 'core/services/notification_handler.dart';
import 'core/services/notification_service.dart';
import 'core/services/backup/backup_scheduler_service.dart';
import 'core/services/reminder_scheduler.dart';
import 'core/utils/error_utils.dart';
import 'data/datasources/database_helper.dart';
import 'presentation/providers/medicine_provider.dart';
import 'presentation/screens/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize database with timeout
    final databaseHelper = DatabaseHelper();
    await Future.any([
      databaseHelper.database,
      Future.delayed(const Duration(seconds: 5), () => null),
    ]);

    // Initialize notification service with timeout
    final notificationService = NotificationService();
    await Future.any([
      notificationService.initialize(),
      Future.delayed(const Duration(seconds: 3), () => null),
    ]);

    // Request notification permissions (non-blocking)
    try {
      await notificationService.requestNotificationPermissions().timeout(
        const Duration(seconds: 2),
        onTimeout: () {
          ErrorUtils.logInfo('Notification permission request timed out');
          return Future.value(false);
        },
      );
    } catch (e) {
      ErrorUtils.logInfo('Failed to request notification permissions: $e');
    }

    // Initialize reminder scheduler (non-blocking)
    final reminderScheduler = ReminderScheduler(databaseHelper);
    try {
      await reminderScheduler.initialize().timeout(
        const Duration(seconds: 3),
        onTimeout: () =>
            ErrorUtils.logInfo('Reminder scheduler initialization timed out'),
      );
    } catch (e) {
      ErrorUtils.logInfo('Failed to initialize reminder scheduler: $e');
    }

    // Initialize backup scheduler (non-blocking)
    BackupSchedulerService().initialize().catchError((e) {
      ErrorUtils.logInfo('Backup scheduler initialization failed: $e');
    });

    // Initialize notification handler
    final notificationHandler = NotificationHandler(
      notificationService,
      reminderScheduler,
    );

    // Wire up notification response callback to handler
    NotificationService.onNotificationResponseCallback =
        notificationHandler.handleNotificationResponse;

    runApp(
      ProviderScope(
        overrides: [
          // Provide initialized instances
          databaseHelperProvider.overrideWithValue(databaseHelper),
          reminderSchedulerProvider.overrideWithValue(reminderScheduler),
        ],
        child: App(notificationHandler: notificationHandler),
      ),
    );
  } catch (e) {
    // If initialization fails, still run the app but without some features
    ErrorUtils.logError(
      'Critical initialization error - running app in degraded mode',
      error: e,
    );

    runApp(ProviderScope(child: App(notificationHandler: null)));
  }
}
