import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/themes/app_theme.dart';
import '../../core/constants/spacing_constants.dart';
import '../../core/utils/date_time_utils.dart';
import '../../core/utils/medicine_dashboard_status.dart';
import '../../domain/entities/medicine.dart';
import '../../domain/entities/reminder_log.dart';
import '../../domain/entities/vital_sign.dart';
import '../providers/medicine_provider.dart';
import '../providers/reminder_provider.dart';
import '../providers/vital_sign_provider.dart';
import '../providers/profile_provider.dart';
import '../widgets/common/glass_widgets.dart';
import 'add_medicine_screen_new.dart';
import 'add_prescription_screen.dart';
import 'add_follow_up_screen_new.dart';
import 'add_vital_sign_screen.dart';
import 'settings_screen.dart';
import 'timeline_screen.dart';
import 'vital_sign_list_screen.dart';

class DashboardScreenNew extends ConsumerWidget {
  const DashboardScreenNew({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todaysMedicinesAsync = ref.watch(todaysMedicinesProvider);
    final medicineListState = ref.watch(medicineListProvider);
    final todaysRemindersAsync = ref.watch(todaysRemindersProvider);
    final reminderStatisticsAsync = ref.watch(reminderStatisticsProvider);
    final todaysVitalSignsAsync = ref.watch(todaysVitalSignsProvider);
    final latestVitalSignsAsync = ref.watch(latestVitalSignsProvider);
    final abnormalVitalSignsAsync = ref.watch(abnormalVitalSignsProvider);
    final profileState = ref.watch(profileProvider);
    final patientName = profileState.profile.fullName;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenHorizontal,
              AppSpacing.xl,
              AppSpacing.screenHorizontal,
              86 + AppSpacing.xxl,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildWelcomeHeader(context, patientName)
                    .animate()
                    .fadeIn(duration: 300.ms)
                    .slideY(begin: .06, end: 0),
                const SizedBox(height: AppSpacing.l),
                _buildStatisticsSection(context, reminderStatisticsAsync)
                    .animate()
                    .fadeIn(delay: 140.ms, duration: 300.ms)
                    .scale(begin: const Offset(.95, .95), end: const Offset(1, 1)),
                const SizedBox(height: AppSpacing.l),
                _buildTodaysMedicinesSection(
                  context,
                  ref,
                  todaysMedicinesAsync,
                  todaysRemindersAsync,
                  medicineListState,
                ).animate().fadeIn(delay: 200.ms, duration: 300.ms).slideY(begin: .08, end: 0),
                const SizedBox(height: AppSpacing.l),
                _buildTodaysVitalSignsSection(
                  context,
                  ref,
                  todaysVitalSignsAsync,
                  latestVitalSignsAsync,
                  abnormalVitalSignsAsync,
                ).animate().fadeIn(delay: 240.ms, duration: 300.ms).slideY(begin: .08, end: 0),
                const SizedBox(height: AppSpacing.l),
                _buildQuickActionsSection(context)
                    .animate()
                    .fadeIn(delay: 280.ms, duration: 300.ms)
                    .slideY(begin: .08, end: 0),
                const SizedBox(height: AppSpacing.xxl),
              ]),
            ),
          ),
        ],
      ),
      floatingActionButton: GradientFab(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddMedicineScreenNew()),
          );
        },
        icon: Icons.add,
      ),
    );
  }

  Widget _buildWelcomeHeader(BuildContext context, String patientName) {
    final now = DateTime.now();
    final greeting = _getGreeting(now);
    final formattedDate = DateTimeUtils.formatDate(now);

    final cleanName = patientName.trim();
    final greetingText = cleanName.isNotEmpty
        ? '$greeting, ${cleanName.split(' ').first}'
        : '$greeting,';

    return GlassCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Health companion',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppTheme.tertiaryFixed,
                        letterSpacing: 1.1,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'CareVault',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.m),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  shape: BoxShape.circle,
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x553B82F6),
                      blurRadius: 18,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(Icons.favorite_rounded, color: Colors.white),
              ),
              const SizedBox(width: AppSpacing.s),
              IconButton(
                tooltip: 'Settings',
                icon: const Icon(Icons.tune_rounded),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.m),
          const Divider(height: 1, color: AppTheme.outlineVariant),
          const SizedBox(height: AppSpacing.m),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.m,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: AppTheme.pendingBadgeDecoration,
                      child: Text(
                        greetingText,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppTheme.primaryFixed,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s),
                    Text(
                      'Welcome back!',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.m),
              Row(
                children: [
                  const Icon(Icons.calendar_month_rounded, size: 18, color: AppTheme.tertiaryFixed),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    formattedDate,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getGreeting(DateTime time) {
    final hour = time.hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  Widget _buildStatisticsSection(
    BuildContext context,
    AsyncValue<Map<String, int>> statisticsAsync,
  ) {
    return statisticsAsync.when(
      data: (statistics) {
        final total = statistics['total'] ?? 0;
        final taken = statistics['taken'] ?? 0;
        final pending = statistics['pending'] ?? 0;
        final adherenceRate = total > 0
            ? ((taken + (statistics['skipped'] ?? 0)) * 100 / total).round()
            : 0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(
              eyebrow: 'Today',
              title: 'Overview',
            ),
            const SizedBox(height: AppSpacing.m),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.28,
              mainAxisSpacing: AppSpacing.s,
              crossAxisSpacing: AppSpacing.s,
              padding: EdgeInsets.zero,
              children: [
                _buildStatCard(
                  context,
                  'Total Reminders',
                  total.toString(),
                  Icons.medication,
                  AppTheme.primaryColor,
                ),
                _buildStatCard(
                  context,
                  'Taken',
                  taken.toString(),
                  Icons.check_circle,
                  AppTheme.primaryColor,
                ),
                _buildStatCard(
                  context,
                  'Pending',
                  pending.toString(),
                  Icons.access_time,
                  AppTheme.neutralColor,
                ),
                _buildStatCard(
                  context,
                  'Adherence',
                  '$adherenceRate%',
                  Icons.trending_up,
                  adherenceRate >= 80
                      ? AppTheme.primaryColor
                      : AppTheme.tertiaryColor,
                ),
              ],
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => _buildErrorState(context, error.toString()),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.m),
      borderRadius: 24,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withValues(alpha: 0.85), color],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const Spacer(),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodaysMedicinesSection(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<Medicine>> todaysMedicinesAsync,
    AsyncValue<List<ReminderLog>> todaysRemindersAsync,
    MedicineListState medicineListState,
  ) {
    return todaysMedicinesAsync.when(
      data: (medicines) {
        if (medicines.isEmpty) {
          return _buildEmptyState(
            context,
            'No medicines scheduled for today',
            Icons.medication,
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(
              eyebrow: 'Schedule',
              title: 'Today\'s Medicines',
            ),
            const SizedBox(height: AppSpacing.m),
            ...medicines.take(3).map((medicine) {
              final reminders =
                  todaysRemindersAsync.value ?? const <ReminderLog>[];
              return _buildMedicineCard(context, ref, medicine, reminders);
            },),
            if (medicines.length > 3)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.m),
                child: Center(
                  child: Text(
                    '+ ${medicines.length - 3} more',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => _buildErrorState(context, error.toString()),
    );
  }

  Widget _buildMedicineCard(
    BuildContext context,
    WidgetRef ref,
    Medicine medicine,
    List<ReminderLog> reminders,
  ) {
    final nextTime = medicine.times.isNotEmpty ? medicine.times.first : '';
    final status = MedicineDashboardStatus.forMedicine(medicine, reminders);
    final reminder = status.reminder;
    final statusColor = _getReminderStatusColor(reminder?.status);
    final isPending = reminder?.status == ReminderStatus.pending;
    final isManualLoggingAvailable = reminder?.isManualLoggingAvailable() ?? false;
    final isManualLoggingExpired = reminder?.isManualLoggingExpired() ?? false;
    final actionLabel = isManualLoggingExpired
        ? 'Logging closed for today'
        : isManualLoggingAvailable
            ? 'Log status'
            : 'Available 30 min before dose';
    final manualLoggingHint = reminder != null ? _buildManualLoggingHint(reminder) : null;

    return GlassCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.s),
      padding: const EdgeInsets.all(AppSpacing.m),
      borderRadius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: AppTheme.accentGradient,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.medication_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      medicine.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.onSurfaceColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${medicine.dosage} • Next: $nextTime',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.m,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(width: 1, color: statusColor.withValues(alpha: 0.45)),
                ),
                child: Text(
                  status.label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (manualLoggingHint != null) ...[
            const SizedBox(height: AppSpacing.m),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.m),
              decoration: BoxDecoration(
                color: const Color(0x10FFFFFF),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                manualLoggingHint,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
          if (isPending && reminder != null) ...[
            const SizedBox(height: AppSpacing.m),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isManualLoggingAvailable
                        ? () => _confirmManualStatus(
                              context,
                              ref,
                              reminder,
                              ReminderStatus.taken,
                            )
                        : null,
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Taken'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.successColor,
                      side: BorderSide(
                        color: isManualLoggingAvailable
                            ? AppTheme.successColor.withValues(alpha: 0.55)
                            : AppTheme.outlineVariant,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.s),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isManualLoggingAvailable
                        ? () => _confirmManualStatus(
                              context,
                              ref,
                              reminder,
                              ReminderStatus.missed,
                            )
                        : null,
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text('Missed'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.errorColor,
                      side: BorderSide(
                        color: isManualLoggingAvailable
                            ? AppTheme.errorColor.withValues(alpha: 0.55)
                            : AppTheme.outlineVariant,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (!isManualLoggingAvailable) ...[
              const SizedBox(height: AppSpacing.s),
              Text(
                actionLabel,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppTheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ],
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
              Text(
                'Scheduled for ${DateTimeUtils.formatTime(reminder.scheduledTime)}',
              ),
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

  Widget _buildTodaysVitalSignsSection(
    BuildContext context,
    WidgetRef ref,
    List<VitalSign> todaysVitalSigns,
    Map<VitalSignType, VitalSign?> latestVitalSigns,
    List<VitalSign> abnormalVitalSigns,
  ) {
    final hasAbnormalReadings = abnormalVitalSigns.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          eyebrow: 'Vitals',
          title: 'Health Metrics',
        ),
        const SizedBox(height: AppSpacing.m),
        if (hasAbnormalReadings)
          GlassCard(
            margin: const EdgeInsets.only(bottom: AppSpacing.m),
            color: const Color(0x1AEF4444),
            padding: const EdgeInsets.all(AppSpacing.m),
            child: Row(
              children: [
                Icon(Icons.warning, color: AppTheme.errorColor, size: 24),
                const SizedBox(width: AppSpacing.m),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Abnormal readings detected',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.errorColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${abnormalVitalSigns.length} vital sign${abnormalVitalSigns.length == 1 ? '' : 's'} outside normal range',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.errorColor,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Abnormal Readings'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: abnormalVitalSigns.map((vs) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Text(
                                '• ${vs.type.displayName}: ${vs.displayValue}',
                                style: TextStyle(
                                  color: vs.isWithinTargetRange ? Colors.green : Colors.red,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: Text(
                    'View Details',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppTheme.errorColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        LayoutBuilder(
          builder: (context, constraints) {
            final textScale = MediaQuery.textScalerOf(context).scale(1);
            final isCompactWidth = constraints.maxWidth < 380;
            final childAspectRatio = textScale > 1.15
                ? 1.2
                : isCompactWidth
                ? 1.35
                : 1.45;

            return GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: childAspectRatio,
              mainAxisSpacing: AppSpacing.s,
              crossAxisSpacing: AppSpacing.s,
              padding: EdgeInsets.zero,
              children: VitalSignType.values.map((type) {
                final latestReading = latestVitalSigns[type];
                final todayReadings = todaysVitalSigns.where((vs) => vs.type == type).toList();
                return _buildVitalSignCard(
                  context,
                  type: type,
                  latestReading: latestReading,
                  todayCount: todayReadings.length,
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildVitalSignCard(
    BuildContext context, {
    required VitalSignType type,
    required VitalSign? latestReading,
    required int todayCount,
  }) {
    final hasReading = latestReading != null;
    final isAbnormal = hasReading && !latestReading!.isWithinTargetRange;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddVitalSignScreen(
              vitalSign: latestReading,
            ),
          ),
        );
      },
        child: GlassCard(
          padding: const EdgeInsets.all(AppSpacing.m),
          borderRadius: 24,
          color: isAbnormal ? const Color(0x14EF4444) : null,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(type.icon ?? '📊', style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      type.displayName,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppTheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isAbnormal)
                    Icon(Icons.warning, color: AppTheme.errorColor, size: 14),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                hasReading ? latestReading!.displayValue : 'No data',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: hasReading
                      ? (isAbnormal ? AppTheme.errorColor : AppTheme.primaryColor)
                      : AppTheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.access_time, size: 12, color: AppTheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      hasReading ? 'Latest: ${_formatTimeAgo(latestReading!.readingTime)}' : 'Not recorded',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppTheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (todayCount > 0) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.today, size: 12, color: AppTheme.primaryColor),
                    const SizedBox(width: 4),
                    Text(
                      '$todayCount today',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),

    );
  }

  Color _getReminderStatusColor(ReminderStatus? status) {
    switch (status) {
      case ReminderStatus.taken:
        return Colors.green;
      case ReminderStatus.skipped:
        return Colors.orange;
      case ReminderStatus.missed:
        return Colors.red;
      case ReminderStatus.snoozed:
        return Colors.amber;
      case ReminderStatus.pending:
      case null:
        return AppTheme.primaryColor;
    }
  }

  String _formatTimeAgo(DateTime dateTime) {

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${(difference.inDays / 7).floor()}w ago';
    }
  }

  Widget _buildQuickActionsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          eyebrow: 'Actions',
          title: 'Quick Actions',
        ),
        const SizedBox(height: AppSpacing.m),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.35,
          mainAxisSpacing: AppSpacing.s,
          crossAxisSpacing: AppSpacing.s,
          padding: EdgeInsets.zero,
          children: [
            _buildQuickActionCard(
              context,
              'Add Medicine',
              Icons.add_circle_outline,
              AppTheme.primaryColor,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddMedicineScreenNew(),
                  ),
                );
              },
            ),
            _buildQuickActionCard(
              context,
              'Upload Prescription',
              Icons.upload_file,
              AppTheme.primaryColor,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddPrescriptionScreen(),
                  ),
                );
              },
            ),
            _buildQuickActionCard(
              context,
              'Schedule Follow-up',
              Icons.calendar_today,
              AppTheme.primaryColor,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddFollowUpScreenNew(),
                  ),
                );
              },
            ),
            _buildQuickActionCard(
              context,
              'View Timeline',
              Icons.timeline,
              AppTheme.primaryColor,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TimelineScreen(),
                  ),
                );
              },
            ),
            _buildQuickActionCard(
              context,
              'Add Vital Sign',
              Icons.monitor_heart,
              AppTheme.primaryColor,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddVitalSignScreen(),
                  ),
                );
              },
            ),
            _buildQuickActionCard(
              context,
              'View Vitals',
              Icons.health_and_safety,
              AppTheme.primaryColor,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const VitalSignListScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        padding: const EdgeInsets.all(AppSpacing.m),
        borderRadius: 24,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.withValues(alpha: 0.92), color],
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(height: AppSpacing.m),
            Expanded(
              child: Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.onSurfaceColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, String message, IconData icon) {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.l),
      borderRadius: 24,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: AppTheme.onSurfaceVariant),
          const SizedBox(height: AppSpacing.m),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.l),
      borderRadius: 24,
      color: const Color(0x1AEF4444),
      child: Column(
        children: [
          Icon(Icons.error_outline, size: 48, color: AppTheme.errorColor),
          const SizedBox(height: AppSpacing.m),
          Text(
            'Error loading data',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.errorColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.s),
          Text(
            error,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppTheme.errorColor),
          ),
        ],
      ),
    );
  }
}
