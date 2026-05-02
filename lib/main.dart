import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/services/notification_handler.dart';
import 'core/services/notification_service.dart';
import 'core/services/reminder_scheduler.dart';
import 'data/datasources/database_helper.dart';
import 'presentation/providers/medicine_provider.dart';
import 'presentation/screens/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize database
  final databaseHelper = DatabaseHelper();
  // Access the database to trigger initialization
  await databaseHelper.database;
  
  // Initialize notification service
  final notificationService = NotificationService();
  await notificationService.initialize();
  
  // Initialize reminder scheduler
  final reminderScheduler = ReminderScheduler(databaseHelper);
  await reminderScheduler.initialize();
  
  // Initialize notification handler
  final notificationHandler = NotificationHandler(notificationService, reminderScheduler);
  
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
}
