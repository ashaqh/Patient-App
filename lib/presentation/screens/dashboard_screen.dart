import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/themes/app_theme.dart';
import '../../core/utils/date_time_utils.dart';
import '../../domain/entities/medicine.dart';
import '../../domain/entities/reminder_log.dart';
import '../providers/medicine_provider.dart';
import '../providers/reminder_provider.dart';
import 'add_medicine_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todaysMedicinesAsync = ref.watch(todaysMedicinesProvider);
    final medicineListState = ref.watch(medicineListProvider);
    final todaysRemindersAsync = ref.watch(todaysRemindersProvider);
    final reminderStatisticsAsync = ref.watch(reminderStatisticsProvider);

    return Scaffold(
      backgroundColor: AppTheme.surfaceContainer,
      body: SafeArea(
        child: Column(
          children: [
            // Modern App Bar
            _buildAppBar(context),
            // Main content with better spacing
            Expanded(
              child: _buildBody(
                context, 
                ref, 
                todaysMedicinesAsync, 
                medicineListState,
                todaysRemindersAsync,
                reminderStatisticsAsync,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddMedicineScreen(),
            ),
          );
        },
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: AppTheme.onPrimaryColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        border: Border(
          bottom: BorderSide(
            width: 1,
            color: AppTheme.outlineVariant,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CareVault',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Your Health Companion',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Icon(
              Icons.person,
              color: AppTheme.onPrimaryColor,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<Medicine>> todaysMedicinesAsync,
    MedicineListState medicineListState,
    AsyncValue<List<ReminderLog>> todaysRemindersAsync,
    AsyncValue<Map<String, int>> reminderStatisticsAsync,
  ) {
    // Show loading state
    if (medicineListState.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // Show error state
    if (medicineListState.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppTheme.errorColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading data',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.onSurfaceColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              medicineListState.error.toString(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.read(medicineListProvider.notifier).refresh(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome section
          _buildWelcomeSection(context),
          const SizedBox(height: 24),

          // Quick Stats
          _buildQuickStats(context, reminderStatisticsAsync),
          const SizedBox(height: 20),

          // Next Dose Card
          _buildNextDoseCard(context, ref, todaysRemindersAsync),
          const SizedBox(height: 20),

          // Today's Schedule
          _buildTodaysScheduleSection(context, ref, todaysRemindersAsync),
          const SizedBox(height: 20),

          // Health Tips Section
          _buildHealthTipsSection(context),
          const SizedBox(height: 20),

          // Emergency Support
          _buildEmergencySupportSection(context),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection(BuildContext context) {
    final now = DateTime.now();
    final hour = now.hour;
    String greeting = 'Good Morning';
    
    if (hour >= 12 && hour < 17) {
      greeting = 'Good Afternoon';
    } else if (hour >= 17) {
      greeting = 'Good Evening';
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greeting,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: AppTheme.onSurfaceColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Welcome back to your health journey',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildHealthTipsSection(BuildContext context) {
    final healthTips = [
      {
        'title': 'Stay Hydrated',
        'description': 'Drink at least 8 glasses of water daily',
        'icon': Icons.water_drop,
        'color': AppTheme.infoColor,
      },
      {
        'title': 'Regular Exercise',
        'description': '30 minutes of moderate activity daily',
        'icon': Icons.directions_run,
        'color': AppTheme.successColor,
      },
      {
        'title': 'Healthy Sleep',
        'description': 'Aim for 7-9 hours of quality sleep',
        'icon': Icons.night_shelter,
        'color': AppTheme.secondaryColor,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Health Tips',
              style: AppTheme.headlineLgStyle,
            ),
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.more_horiz),
              color: AppTheme.onSurfaceVariant,
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...healthTips.map((tip) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              width: 1,
              color: AppTheme.outlineVariant,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: tip['color'] as Color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  tip['icon'] as IconData,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tip['title'] as String,
                      style: AppTheme.headlineMdStyle,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tip['description'] as String,
                      style: AppTheme.bodyMdStyle.copyWith(
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        )).toList(),
      ],
    );
  }

  Widget _buildQuickStats(BuildContext context, AsyncValue<Map<String, int>> statisticsAsync) {
    return statisticsAsync.when(
      data: (stats) {
        final total = stats['total'] ?? 0;
        final taken = stats['taken'] ?? 0;
        final adherenceRate = total > 0 ? ((taken * 100) / total).round() : 0;

        return Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                'Adherence',
                '$adherenceRate%',
                Icons.analytics,
                AppTheme.successColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                context,
                'Today\'s Meds',
                total.toString(),
                Icons.medication,
                AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                context,
                'Taken',
                taken.toString(),
                Icons.check_circle,
                AppTheme.tertiaryColor,
              ),
            ),
          ],
        );
      },
      loading: () => Container(
        height: 100,
        alignment: Alignment.center,
        child: const CircularProgressIndicator(),
      ),
      error: (error, stackTrace) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.outlineVariant),
        ),
        child: Text(
          'Stats unavailable',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 24,
            color: color,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppTheme.onSurfaceColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildNextDoseCard(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<ReminderLog>> todaysRemindersAsync,
  ) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: AppTheme.primaryGradient,
      ),
      child: todaysRemindersAsync.when(
        data: (reminders) {
          if (reminders.isEmpty) {
            return _buildEmptyNextDose(context);
          }

          reminders.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
          final nextReminder = reminders.firstWhere(
            (reminder) => reminder.status == ReminderStatus.pending,
            orElse: () => reminders.first,
          );
          final isManualLoggingAvailable = nextReminder.isManualLoggingAvailable();
          final isManualLoggingExpired = nextReminder.isManualLoggingExpired();
          final actionLabel = isManualLoggingExpired
              ? 'Logging closed for today'
              : isManualLoggingAvailable
                  ? 'Log status'
                  : 'Available 30 min before dose';

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.notifications_active,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Next Dose',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nextReminder.medicineName,
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            nextReminder.dosage,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.white.withOpacity(0.9),
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _buildManualLoggingHint(nextReminder),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.white.withOpacity(0.86),
                                ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white.withOpacity(0.3)),
                      ),
                      child: Text(
                        DateTimeUtils.formatTime(nextReminder.scheduledTime),
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: isManualLoggingAvailable
                        ? () => _showManualStatusSheet(context, ref, nextReminder)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppTheme.primaryColor,
                      disabledBackgroundColor: Colors.white.withOpacity(0.55),
                      disabledForegroundColor: AppTheme.primaryColor.withOpacity(0.7),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isManualLoggingAvailable
                              ? Icons.fact_check_outlined
                              : Icons.schedule,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          actionLabel,
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => Container(
          height: 200,
          alignment: Alignment.center,
          child: const CircularProgressIndicator(color: Colors.white),
        ),
        error: (error, stackTrace) => Container(
          padding: const EdgeInsets.all(20),
          child: Text(
            'Unable to load next dose',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyNextDose(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: AppTheme.primaryGradient,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.medication_outlined,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'No Upcoming Doses',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Add your medicines to see upcoming doses',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddMedicineScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppTheme.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_circle_outline,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Add Medicine',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  

  Widget _buildImageIllustration(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          width: 2,
          color: AppTheme.outlineVariant,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset(
          'assets/images/medicine_illustration.png',
          width: double.infinity,
          height: 192,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              height: 192,
              width: double.infinity,
              color: AppTheme.surfaceContainer,
              child: Center(
                child: Icon(
                  Icons.medical_services,
                  size: 64,
                  color: AppTheme.primaryColor,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTodaysScheduleSection(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<ReminderLog>> todaysRemindersAsync,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Today's Schedule",
              style: AppTheme.headlineLgStyle.copyWith(
                color: AppTheme.primaryColor,
              ),
            ),
            todaysRemindersAsync.when(
              data: (reminders) {
                final pendingCount = reminders
                    .where((reminder) => reminder.status == ReminderStatus.pending)
                    .length;
                return Text(
                  '$pendingCount Dose${pendingCount == 1 ? '' : 's'} Remaining',
                  style: AppTheme.labelBoldStyle.copyWith(
                    color: AppTheme.secondaryColor,
                  ),
                );
              },
              loading: () => Text(
                'Loading...',
                style: AppTheme.labelBoldStyle.copyWith(
                  color: AppTheme.secondaryColor,
                ),
              ),
              error: (error, stackTrace) => Text(
                'Error',
                style: AppTheme.labelBoldStyle.copyWith(
                  color: AppTheme.errorColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        todaysRemindersAsync.when(
          data: (reminders) {
            if (reminders.isEmpty) {
              return _buildEmptySchedule();
            }

            final sortedReminders = [...reminders]
              ..sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));

            final List<Widget> reminderCards = sortedReminders.map((reminder) {
              final isTaken = reminder.status == ReminderStatus.taken;
              final isManualLoggingAvailable = reminder.isManualLoggingAvailable();
              final isManualLoggingExpired = reminder.isManualLoggingExpired();
              final isPending = reminder.status == ReminderStatus.pending;

              return _buildMedicineCard(
                context,
                ref,
                reminder,
                reminder.medicineName,
                reminder.dosage,
                Icons.medication,
                AppTheme.primaryColor,
                isTaken,
                DateTimeUtils.formatTime(
                  reminder.actualTime ?? reminder.scheduledTime,
                ),
                isActive: isPending && isManualLoggingAvailable,
                isAvailable: isPending && isManualLoggingAvailable,
                buttonLabel: isPending
                    ? isManualLoggingExpired
                        ? 'Logging closed for today'
                        : isManualLoggingAvailable
                            ? 'Log status'
                            : 'Available 30 min before dose'
                    : reminder.status.displayName,
                helperText: _buildManualLoggingHint(reminder),
                statusText: isPending ? null : reminder.status.displayName,
              );
            }).toList();

            return Column(children: reminderCards);
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Text(
            'Error loading schedule',
            style: TextStyle(color: AppTheme.errorColor),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptySchedule() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          width: 2,
          color: AppTheme.outlineVariant,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.medication_outlined,
            size: 64,
            color: AppTheme.secondaryColor,
          ),
          const SizedBox(height: 16),
          Text(
            'No medicines scheduled for today',
            style: AppTheme.bodyMdStyle.copyWith(
              color: AppTheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 64,
            child: ElevatedButton(
              onPressed: () {
                // Navigate to add medicine
              },
              style: AppTheme.primaryButtonStyle,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add),
                  const SizedBox(width: 12),
                  Text('Add Medicine'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicineCard(
    BuildContext context,
    WidgetRef ref,
    ReminderLog reminder,
    String name,
    String description,
    IconData icon,
    Color iconColor,
    bool isTaken,
    String time, {
    bool isActive = false,
    bool isAvailable = true,
    String? buttonLabel,
    String? helperText,
    String? statusText,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          width: 2,
          color: isActive ? AppTheme.primaryColor : AppTheme.outlineVariant,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            if (isTaken) // Taken medicine badge
              Align(
                alignment: Alignment.topRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      width: 2,
                      color: Colors.green.shade700,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check,
                        size: 18,
                        color: Colors.green.shade900,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'TAKEN',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: isTaken
                            ? AppTheme.surfaceContainer
                            : isActive
                                ? AppTheme.primaryFixed
                                : AppTheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          width: 2,
                          color: isTaken
                              ? AppTheme.primaryColor
                              : isActive
                                  ? AppTheme.primaryColor
                                  : AppTheme.outlineColor,
                        ),
                      ),
                      child: Icon(
                        icon,
                        size: 32,
                        color: isTaken
                            ? AppTheme.primaryColor
                            : isActive
                                ? AppTheme.primaryColor
                                : AppTheme.outlineColor,
                      ),
                    ),
                    const SizedBox(width: 24),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: AppTheme.headlineMdStyle.copyWith(
                            color: isTaken || isActive
                                ? AppTheme.primaryColor
                                : AppTheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          description,
                          style: AppTheme.bodyMdStyle.copyWith(
                            color: isTaken || isActive
                                ? AppTheme.secondaryColor
                                : AppTheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isTaken
                        ? AppTheme.tertiaryFixed
                        : isActive
                            ? AppTheme.tertiaryFixed
                            : Colors.transparent,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      width: 2,
                      color: isTaken
                          ? AppTheme.tertiaryColor
                          : isActive
                              ? AppTheme.tertiaryColor
                              : Colors.transparent,
                    ),
                  ),
                  child: Text(
                    time,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isTaken || isActive
                          ? AppTheme.onPrimaryColor
                          : AppTheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            if (isTaken) // Logged time for taken medicine
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 20,
                      color: AppTheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Logged at $time',
                      style: AppTheme.labelBoldStyle.copyWith(
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            if (!isTaken && statusText != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    statusText,
                    style: AppTheme.labelBoldStyle.copyWith(
                      color: _getReminderStatusColor(reminder.status),
                    ),
                  ),
                ),
              ),
            if (helperText != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    helperText,
                    style: AppTheme.bodyMdStyle.copyWith(
                      color: AppTheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            if (!isTaken && reminder.status == ReminderStatus.pending)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 64,
                  child: ElevatedButton(
                    onPressed: isAvailable
                        ? () => _showManualStatusSheet(context, ref, reminder)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isActive ? Colors.white : AppTheme.surfaceContainerHighest,
                      foregroundColor: isActive ? AppTheme.primaryColor : AppTheme.onSurfaceVariant.withOpacity(0.7),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      side: BorderSide(
                        width: isActive ? 4 : 2,
                        color: isActive ? AppTheme.primaryColor : AppTheme.outlineVariant,
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isAvailable ? Icons.fact_check_outlined : Icons.pending,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          buttonLabel ?? (isAvailable ? 'Log status' : 'Not Yet Available'),
                          style: AppTheme.headlineMdStyle,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String? _buildManualLoggingHint(ReminderLog reminder) {
    if (reminder.status != ReminderStatus.pending) {
      return 'Status recorded for this dose.';
    }

    if (reminder.isManualLoggingExpired()) {
      return 'Manual logging closed at midnight for this dose.';
    }

    if (reminder.isManualLoggingAvailable()) {
      return 'Confirm Taken or Missed. Both actions require confirmation.';
    }

    return null;
  }

  Future<void> _showManualStatusSheet(
    BuildContext context,
    WidgetRef ref,
    ReminderLog reminder,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reminder.medicineName,
                  style: Theme.of(sheetContext).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${reminder.dosage} at ${DateTimeUtils.formatTime(reminder.scheduledTime)}',
                  style: Theme.of(sheetContext).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 20),
                _buildManualStatusAction(
                  context: sheetContext,
                  icon: Icons.check_circle_outline,
                  label: 'Taken',
                  color: AppTheme.successColor,
                  onTap: () async {
                    Navigator.of(sheetContext).pop();
                    await _confirmManualStatus(
                      context,
                      ref,
                      reminder,
                      ReminderStatus.taken,
                    );
                  },
                ),
                const SizedBox(height: 12),
                _buildManualStatusAction(
                  context: sheetContext,
                  icon: Icons.cancel_outlined,
                  label: 'Missed',
                  color: AppTheme.errorColor,
                  onTap: () async {
                    Navigator.of(sheetContext).pop();
                    await _confirmManualStatus(
                      context,
                      ref,
                      reminder,
                      ReminderStatus.missed,
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildManualStatusAction({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, color: color),
        label: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Text(
            label,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: color.withOpacity(0.5), width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmManualStatus(
    BuildContext context,
    WidgetRef ref,
    ReminderLog reminder,
    ReminderStatus status,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Confirm ${status.displayName.toLowerCase()}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${reminder.medicineName} • ${reminder.dosage}'),
              const SizedBox(height: 8),
              Text('Scheduled for ${DateTimeUtils.formatTime(reminder.scheduledTime)}'),
              const SizedBox(height: 12),
              Text(
                status == ReminderStatus.taken
                    ? 'This will record the dose as taken.'
                    : 'This will record the dose as missed.',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: status == ReminderStatus.taken
                    ? AppTheme.successColor
                    : AppTheme.errorColor,
                foregroundColor: Colors.white,
              ),
              child: Text('Confirm ${status.displayName}'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      final updater = ref.read(reminderStatusUpdaterProvider);
      if (status == ReminderStatus.taken) {
        await updater.markAsTakenManually(
          medicineId: reminder.medicineId,
          scheduledTime: reminder.scheduledTime,
          notes: 'Confirmed manually from dashboard',
        );
      } else {
        await updater.markAsMissedManually(
          medicineId: reminder.medicineId,
          scheduledTime: reminder.scheduledTime,
          notes: 'Confirmed manually from dashboard',
        );
      }

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${reminder.medicineName} marked as ${status.displayName.toLowerCase()}.',
          ),
          backgroundColor: status == ReminderStatus.taken
              ? AppTheme.successColor
              : AppTheme.errorColor,
        ),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Bad state: ', '')),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Widget _buildEmergencySupportSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          width: 4,
          color: AppTheme.errorColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.medical_services,
                size: 32,
                color: AppTheme.errorColor,
              ),
              const SizedBox(width: 16),
              Text(
                'Need Assistance?',
                style: AppTheme.headlineMdStyle.copyWith(
color: AppTheme.errorColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Contact your primary caregiver or emergency services immediately if you feel unwell.',
            style: AppTheme.bodyMdStyle.copyWith(
              color: AppTheme.errorColor,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 64,
                  child: OutlinedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Calling nurse...'),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppTheme.errorColor,
                      side: BorderSide(
                        width: 2,
                        color: AppTheme.errorColor,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.call),
                        const SizedBox(width: 12),
                        Text(
                          'Call Nurse',
                          style: AppTheme.labelBoldStyle,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SizedBox(
                  height: 64,
                  child: ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Getting emergency help...'),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.errorColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 4,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.sos),
                        const SizedBox(width: 12),
                        Text(
                          'Get Help',
                          style: AppTheme.labelBoldStyle,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsSection(BuildContext context, AsyncValue<Map<String, int>> statisticsAsync) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.analytics,
                  size: 24,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  "Today's Statistics",
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 12),
            statisticsAsync.when(
              data: (statistics) {
                if (statistics['total'] == 0) {
                  return _buildEmptyState(
                    context,
                    'No reminders scheduled for today',
                    Icons.notifications_none,
                  );
                }
                return _buildStatisticsGrid(context, statistics);
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => _buildErrorState(context, error.toString()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsGrid(BuildContext context, Map<String, int> statistics) {
    final total = statistics['total'] ?? 0;
    final taken = statistics['taken'] ?? 0;
    final pending = statistics['pending'] ?? 0;
    final missed = statistics['missed'] ?? 0;
    final skipped = statistics['skipped'] ?? 0;
    final snoozed = statistics['snoozed'] ?? 0;

    final adherenceRate = total > 0 ? ((taken + skipped) * 100 / total).round() : 0;

    return Column(
      children: [
        // Adherence rate
        _buildStatItem(
          context,
          'Adherence Rate',
          '$adherenceRate%',
          Icons.check_circle,
          Colors.green,
        ),
        const SizedBox(height: 12),
        // Stats grid
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.8,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          children: [
            _buildStatItem(
              context,
              'Total Reminders',
              total.toString(),
              Icons.list_alt,
              Theme.of(context).colorScheme.primary,
            ),
            _buildStatItem(
              context,
              'Taken',
              taken.toString(),
              Icons.check,
              Colors.green,
            ),
            _buildStatItem(
              context,
              'Pending',
              pending.toString(),
              Icons.access_time,
              Colors.orange,
            ),
            _buildStatItem(
              context,
              'Missed',
              missed.toString(),
              Icons.close,
              Colors.red,
            ),
            _buildStatItem(
              context,
              'Skipped',
              skipped.toString(),
              Icons.next_plan,
              Colors.blue,
            ),
            _buildStatItem(
              context,
              'Snoozed',
              snoozed.toString(),
              Icons.snooze,
              Colors.purple,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodaysRemindersSection(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<ReminderLog>> todaysRemindersAsync,
  ) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.notifications_active,
                  size: 24,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  "Today's Reminders",
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 12),
            todaysRemindersAsync.when(
              data: (reminders) {
                if (reminders.isEmpty) {
                  return _buildEmptyState(
                    context,
                    'No reminders scheduled for today',
                    Icons.notifications_none,
                  );
                }
                return Column(
                  children: reminders.map((reminder) => _buildReminderCard(context, ref, reminder)).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => _buildErrorState(context, error.toString()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodaysMedicinesSection(
    BuildContext context,
    AsyncValue<List<Medicine>> todaysMedicinesAsync,
  ) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.today,
                  size: 24,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  "Today's Medicines",
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 12),
            todaysMedicinesAsync.when(
              data: (medicines) {
                if (medicines.isEmpty) {
                  return _buildEmptyState(
                    context,
                    'No medicines scheduled for today',
                    Icons.medication_outlined,
                  );
                }
                return Column(
                  children: medicines.map<Widget>((medicine) => _buildMedicineCardFromMedicine(context, medicine)).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => _buildErrorState(context, error.toString()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewAllMedicinesButton(
    BuildContext context,
    WidgetRef ref,
    MedicineListState medicineListState,
  ) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.medication,
                  size: 24,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'All Medicines',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                Text(
                  '${medicineListState.medicines.length} total',
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                // Navigate to medicine list screen via bottom navigation
                // Since we're using bottom navigation, we need to update the selected index
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Use bottom navigation to view all medicines'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              icon: const Icon(Icons.list),
              label: const Text('View All Medicines'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReminderCard(BuildContext context, WidgetRef ref, ReminderLog reminder) {
    final statusColor = _getReminderStatusColor(reminder.status);
    final statusText = reminder.status.displayName;
    final isOverdue = reminder.isOverdue;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      color: isOverdue ? Colors.red.shade50 : null,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        minVerticalPadding: 12,
        isThreeLine: true,
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.2),
          child: Icon(
            _getReminderStatusIcon(reminder.status),
            color: statusColor,
          ),
        ),
        title: Text(
          reminder.medicineName,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Dosage: ${reminder.dosage}'),
            Text('Time: ${reminder.displayTime}'),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    statusText,
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                if (isOverdue) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Text(
                      'OVERDUE',
                      style: Theme.of(context).textTheme.bodySmall!.copyWith(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                ],
              ],
            ),
            if (reminder.notes != null && reminder.notes!.isNotEmpty)
              Text(
                'Note: ${reminder.notes}',
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        trailing: reminder.status == ReminderStatus.pending
            ? IconButton(
                icon: const Icon(Icons.check_circle_outline),
                color: Theme.of(context).colorScheme.primary,
                onPressed: () {
                  _showManualStatusSheet(context, ref, reminder);
                },
              )
            : null,
        onTap: () {
          _showReminderDetails(context, reminder);
        },
      ),
    );
  }

  Widget _buildMedicineCardFromMedicine(BuildContext context, Medicine medicine) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        minVerticalPadding: 12,
        isThreeLine: true,
        leading: Icon(
          medicine.isActive ? Icons.medication : Icons.medication_outlined,
          color: medicine.isActive ? Theme.of(context).colorScheme.primary : Colors.grey,
        ),
        title: Text(
          medicine.name,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Dosage: ${medicine.dosage}'),
            Text('Frequency: ${medicine.frequency}'),
            if (medicine.times.isNotEmpty)
              Text(
                'Times: ${medicine.times.join(", ")}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            if (medicine.notes != null && medicine.notes!.isNotEmpty)
              Text(
                'Notes: ${medicine.notes}',
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        trailing: Switch(
          value: medicine.isActive,
          onChanged: (value) {
            // In a real app, this would update the medicine status
            // For now, we'll just show a snackbar
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Medicine ${value ? 'activated' : 'deactivated'}'),
              ),
            );
          },
        ),
        onTap: () {
          // Navigate to medicine details screen
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('View details for ${medicine.name}'),
            ),
          );
        },
      ),
    );
  }

  Color _getReminderStatusColor(ReminderStatus status) {
    switch (status) {
      case ReminderStatus.taken:
        return Colors.green;
      case ReminderStatus.skipped:
        return Colors.blue;
      case ReminderStatus.missed:
        return Colors.red;
      case ReminderStatus.snoozed:
        return Colors.purple;
      case ReminderStatus.pending:
        return Colors.orange;
    }
  }

  IconData _getReminderStatusIcon(ReminderStatus status) {
    switch (status) {
      case ReminderStatus.taken:
        return Icons.check_circle;
      case ReminderStatus.skipped:
        return Icons.next_plan;
      case ReminderStatus.missed:
        return Icons.close;
      case ReminderStatus.snoozed:
        return Icons.snooze;
      case ReminderStatus.pending:
        return Icons.access_time;
    }
  }

  Future<void> _handleReminderAction(
    BuildContext context,
    WidgetRef ref,
    ReminderLog reminder,
    ReminderStatus status,
  ) async {
    if (status == ReminderStatus.taken || status == ReminderStatus.missed) {
      await _confirmManualStatus(context, ref, reminder, status);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${status.displayName} is only available from the reminder notification.',
        ),
      ),
    );
  }

  void _showReminderDetails(BuildContext context, ReminderLog reminder) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(reminder.medicineName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Dosage: ${reminder.dosage}'),
            Text('Scheduled Time: ${reminder.displayTime}'),
            if (reminder.actualTime != null)
              Text('Actual Time: ${reminder.actualTime!.hour.toString().padLeft(2, '0')}:${reminder.actualTime!.minute.toString().padLeft(2, '0')}'),
            Text('Status: ${reminder.status.displayName}'),
            if (reminder.notes != null && reminder.notes!.isNotEmpty)
              Text('Notes: ${reminder.notes}'),
            if (reminder.timeDifference != null)
              Text('Time Difference: ${reminder.timeDifference!.inMinutes.abs()} minutes ${reminder.timeDifference!.isNegative ? 'late' : 'early'}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, String message, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Icon(
            icon,
            size: 48,
            color: Theme.of(context).colorScheme.secondary,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline,
            size: 48,
            color: Colors.red,
          ),
          const SizedBox(height: 12),
          Text(
            'Error: $error',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
