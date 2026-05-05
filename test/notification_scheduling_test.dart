import 'package:carevault/core/services/notification_service.dart';
import 'package:carevault/domain/entities/medicine.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NotificationService.buildMedicineReminderSchedule', () {
    test(
      'schedules remaining reminders across the configured future window',
      () {
        final medicine = Medicine(
          id: 'medicine-1',
          name: 'Test Medicine',
          dosage: '1 tablet',
          frequency: 'Daily',
          times: const ['08:00', '20:00'],
          startDate: DateTime(2026, 5, 1),
        );

        final schedule = NotificationService.buildMedicineReminderSchedule(
          medicine,
          now: DateTime(2026, 5, 4, 12),
          daysAhead: 3,
        );

        expect(schedule, [
          DateTime(2026, 5, 4, 20),
          DateTime(2026, 5, 5, 8),
          DateTime(2026, 5, 5, 20),
          DateTime(2026, 5, 6, 8),
          DateTime(2026, 5, 6, 20),
        ]);
      },
    );

    test('does not schedule outside medicine start and end dates', () {
      final medicine = Medicine(
        id: 'medicine-1',
        name: 'Test Medicine',
        dosage: '1 tablet',
        frequency: 'Daily',
        times: const ['09:00'],
        startDate: DateTime(2026, 5, 5),
        endDate: DateTime(2026, 5, 6),
      );

      final schedule = NotificationService.buildMedicineReminderSchedule(
        medicine,
        now: DateTime(2026, 5, 4, 12),
        daysAhead: 5,
      );

      expect(schedule, [DateTime(2026, 5, 5, 9), DateTime(2026, 5, 6, 9)]);
    });

    test('ignores invalid medicine times', () {
      final medicine = Medicine(
        id: 'medicine-1',
        name: 'Test Medicine',
        dosage: '1 tablet',
        frequency: 'Daily',
        times: const ['bad', '25:00', '10:61', '10:30'],
        startDate: DateTime(2026, 5, 1),
      );

      final schedule = NotificationService.buildMedicineReminderSchedule(
        medicine,
        now: DateTime(2026, 5, 4, 9),
        daysAhead: 1,
      );

      expect(schedule, [DateTime(2026, 5, 4, 10, 30)]);
    });
  });

  group('NotificationService alarm notification details', () {
    test('uses a max-importance Android alarm channel', () {
      final channel = NotificationService.buildAlarmReminderChannel();

      expect(channel.id, NotificationService.alarmReminderChannelId);
      expect(channel.importance, Importance.max);
      expect(channel.playSound, isTrue);
      expect(channel.enableVibration, isTrue);
      expect(channel.audioAttributesUsage, AudioAttributesUsage.alarm);
    });

    test('uses full-screen Android alarm presentation', () {
      final details = NotificationService.buildAndroidAlarmNotificationDetails(
        ongoing: true,
        actions: const [],
      );

      expect(details.channelId, NotificationService.alarmReminderChannelId);
      expect(details.importance, Importance.max);
      expect(details.priority, Priority.max);
      expect(details.category, AndroidNotificationCategory.alarm);
      expect(details.fullScreenIntent, isTrue);
      expect(details.visibility, NotificationVisibility.public);
      expect(details.audioAttributesUsage, AudioAttributesUsage.alarm);
      expect(details.ongoing, isTrue);
      expect(details.autoCancel, isFalse);
    });

    test('uses Time Sensitive iOS presentation', () {
      final details = NotificationService.buildIosAlarmNotificationDetails();

      expect(details.presentAlert, isTrue);
      expect(details.presentBanner, isTrue);
      expect(details.presentList, isTrue);
      expect(details.presentSound, isTrue);
      expect(details.presentBadge, isTrue);
      expect(details.interruptionLevel, InterruptionLevel.timeSensitive);
    });
  });
}
