import 'package:carevault/core/utils/medicine_dashboard_status.dart';
import 'package:carevault/domain/entities/medicine.dart';
import 'package:carevault/domain/entities/reminder_log.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MedicineDashboardStatus', () {
    test('shows pending when a medicine has a pending reminder today', () {
      final medicine = _medicine('medicine-1');
      final reminders = [
        _reminder(
          medicineId: medicine.id,
          status: ReminderStatus.pending,
          scheduledTime: DateTime(2026, 5, 8, 9),
        ),
      ];

      final status = MedicineDashboardStatus.forMedicine(
        medicine,
        reminders,
        now: DateTime(2026, 5, 8, 8),
      );

      expect(status.label, 'Pending');
      expect(status.reminder?.status, ReminderStatus.pending);
    });

    test('shows taken when the matching reminder was marked taken', () {
      final medicine = _medicine('medicine-1');
      final reminders = [
        _reminder(
          medicineId: medicine.id,
          status: ReminderStatus.taken,
          scheduledTime: DateTime(2026, 5, 8, 9),
        ),
      ];

      final status = MedicineDashboardStatus.forMedicine(
        medicine,
        reminders,
        now: DateTime(2026, 5, 8, 9, 5),
      );

      expect(status.label, 'Taken');
      expect(status.reminder?.status, ReminderStatus.taken);
    });

    test('shows taken even when the medicine has another pending dose later today', () {
      final medicine = _medicine('medicine-1');
      final reminders = [
        _reminder(
          medicineId: medicine.id,
          status: ReminderStatus.taken,
          scheduledTime: DateTime(2026, 5, 8, 9),
        ),
        _reminder(
          medicineId: medicine.id,
          status: ReminderStatus.pending,
          scheduledTime: DateTime(2026, 5, 8, 21),
        ),
      ];

      final status = MedicineDashboardStatus.forMedicine(
        medicine,
        reminders,
        now: DateTime(2026, 5, 8, 9, 5),
      );

      expect(status.label, 'Taken');
      expect(status.reminder?.status, ReminderStatus.taken);
    });
  });
}

Medicine _medicine(String id) {
  return Medicine(
    id: id,
    name: 'Metformin',
    dosage: '500mg',
    frequency: 'Once daily',
    times: const ['09:00'],
    startDate: DateTime(2026, 5, 8),
  );
}

ReminderLog _reminder({
  required String medicineId,
  required ReminderStatus status,
  required DateTime scheduledTime,
}) {
  return ReminderLog(
    medicineId: medicineId,
    medicineName: 'Metformin',
    dosage: '500mg',
    scheduledTime: scheduledTime,
    status: status,
  );
}
