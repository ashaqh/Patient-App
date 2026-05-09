import '../../domain/entities/medicine.dart';
import '../../domain/entities/reminder_log.dart';

class MedicineDashboardStatusResult {
  final String label;
  final ReminderLog? reminder;

  const MedicineDashboardStatusResult({
    required this.label,
    required this.reminder,
  });
}

class MedicineDashboardStatus {
  static MedicineDashboardStatusResult forMedicine(
    Medicine medicine,
    List<ReminderLog> reminders, {
    DateTime? now,
  }) {
    final referenceTime = now ?? DateTime.now();
    final matchingReminders =
        reminders
            .where(
              (reminder) =>
                  reminder.medicineId == medicine.id &&
                  _isSameDate(reminder.scheduledTime, referenceTime),
            )
            .toList()
          ..sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));

    if (matchingReminders.isEmpty) {
      return const MedicineDashboardStatusResult(
        label: 'Pending',
        reminder: null,
      );
    }

    final latestTaken = matchingReminders
        .where((reminder) => reminder.status == ReminderStatus.taken)
        .lastOrNull;
    if (latestTaken != null) {
      return MedicineDashboardStatusResult(
        label: latestTaken.status.displayName,
        reminder: latestTaken,
      );
    }

    final nextPending = matchingReminders
        .where(
          (reminder) =>
              reminder.status == ReminderStatus.pending &&
              !reminder.scheduledTime.isBefore(referenceTime),
        )
        .firstOrNull;

    final reminder = nextPending ?? matchingReminders.last;
    return MedicineDashboardStatusResult(
      label: reminder.status.displayName,
      reminder: reminder,
    );
  }

  static bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
