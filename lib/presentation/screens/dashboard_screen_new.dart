import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/themes/app_theme.dart';
import '../../core/constants/spacing_constants.dart';
import '../../core/utils/date_time_utils.dart';
import '../../domain/entities/medicine.dart';
import '../../domain/entities/vital_sign.dart';
import '../providers/medicine_provider.dart';
import '../providers/reminder_provider.dart';
import '../providers/vital_sign_provider.dart';
import 'add_medicine_screen.dart';
import 'add_prescription_screen.dart';
import 'add_follow_up_screen_new.dart';
import 'add_vital_sign_screen.dart';
import 'timeline_screen.dart';
import 'vital_sign_list_screen.dart';

class DashboardScreenNew extends ConsumerWidget {
  const DashboardScreenNew({super.key});

@override
  Widget build(BuildContext context, WidgetRef ref) {
    final todaysMedicinesAsync = ref.watch(todaysMedicinesProvider);
    final medicineListState = ref.watch(medicineListProvider);
    final reminderStatisticsAsync = ref.watch(reminderStatisticsProvider);
    final todaysVitalSignsAsync = ref.watch(todaysVitalSignsProvider);
    final latestVitalSignsAsync = ref.watch(latestVitalSignsProvider);
    final abnormalVitalSignsAsync = ref.watch(abnormalVitalSignsProvider);

    return Scaffold(
      backgroundColor: AppTheme.secondaryColor,
      body: CustomScrollView(
        slivers: [
          // Modern App Bar
          SliverAppBar(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: AppTheme.onPrimaryColor,
            elevation: 0,
            expandedHeight: 140,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CareVault',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: AppTheme.onPrimaryColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Your Health Companion',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.onPrimaryColor.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Main Content
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Welcome Section
                _buildWelcomeSection(context),
                const SizedBox(height: AppSpacing.l),

                // Statistics Cards
                _buildStatisticsSection(context, reminderStatisticsAsync),
                const SizedBox(height: AppSpacing.l),

                // Today's Medicines
                _buildTodaysMedicinesSection(
                  context, 
                  ref, 
                  todaysMedicinesAsync, 
                  medicineListState,
                ),
                const SizedBox(height: AppSpacing.l),

                // Today's Vital Signs
                _buildTodaysVitalSignsSection(
                  context,
                  ref,
                  todaysVitalSignsAsync,
                  latestVitalSignsAsync,
                  abnormalVitalSignsAsync,
                ),
                const SizedBox(height: AppSpacing.l),

                // Quick Actions
                _buildQuickActionsSection(context),
                const SizedBox(height: AppSpacing.xxl),
              ]),
            ),
          ),
        ],
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
          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMedium),
        ),
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }

  Widget _buildWelcomeSection(BuildContext context) {
    final now = DateTime.now();
    final greeting = _getGreeting(now);
    final formattedDate = DateTimeUtils.formatDate(now);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMedium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$greeting,',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppTheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Welcome back!',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppTheme.onSurfaceColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.s),
          Text(
            formattedDate,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.onSurfaceVariant,
            ),
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

  Widget _buildStatisticsSection(BuildContext context, AsyncValue<Map<String, int>> statisticsAsync) {
    return statisticsAsync.when(
      data: (statistics) {
        final total = statistics['total'] ?? 0;
        final taken = statistics['taken'] ?? 0;
        final pending = statistics['pending'] ?? 0;
        final adherenceRate = total > 0 ? ((taken + (statistics['skipped'] ?? 0)) * 100 / total).round() : 0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Today\'s Overview',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppTheme.onSurfaceColor,
              ),
            ),
            const SizedBox(height: AppSpacing.m),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.8,
              mainAxisSpacing: AppSpacing.s,
              crossAxisSpacing: AppSpacing.s,
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
                  adherenceRate >= 80 ? AppTheme.primaryColor : AppTheme.tertiaryColor,
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

  Widget _buildStatCard(BuildContext context, String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMedium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: AppSpacing.xs),
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppTheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Today\'s Medicines',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppTheme.onSurfaceColor,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Navigate to medicine list
                  },
                  child: Text(
                    'View All',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.m),
            ...medicines.take(3).map((medicine) => _buildMedicineCard(context, medicine)).toList(),
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

  Widget _buildMedicineCard(BuildContext context, Medicine medicine) {
    final nextTime = medicine.times.isNotEmpty ? medicine.times.first : '';
    
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.s),
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMedium),
        border: Border.all(
          width: 1,
          color: AppTheme.outlineVariant,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSmall),
            ),
            child: Icon(
              Icons.medication,
              color: AppTheme.primaryColor,
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
                    fontWeight: FontWeight.w600,
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
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: AppSpacing.xs),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                width: 1,
                color: AppTheme.primaryColor,
              ),
            ),
            child: Text(
              'Pending',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Health Metrics',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppTheme.onSurfaceColor,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const VitalSignListScreen(),
                  ),
                );
              },
              child: Text(
                'View All',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.m),
        
        // Warning banner for abnormal readings
        if (hasAbnormalReadings)
          Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.m),
            padding: const EdgeInsets.all(AppSpacing.m),
            decoration: BoxDecoration(
              color: AppTheme.errorContainer,
              borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMedium),
              border: Border.all(
                width: 1,
                color: AppTheme.errorColor,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning,
                  color: AppTheme.errorColor,
                  size: 24,
                ),
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
                    // Show abnormal readings
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
                                  color: vs.isWithinTargetRange 
                                      ? Colors.green 
                                      : Colors.red,
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
        
        // Latest readings grid
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.8,
          mainAxisSpacing: AppSpacing.s,
          crossAxisSpacing: AppSpacing.s,
          children: VitalSignType.values.map((type) {
            final latestReading = latestVitalSigns[type];
            final todayReadings = todaysVitalSigns
                .where((vs) => vs.type == type)
                .toList();
            
            return _buildVitalSignCard(
              context,
              type: type,
              latestReading: latestReading,
              todayCount: todayReadings.length,
            );
          }).toList(),
        ),
        
        // Add vital sign button
        if (todaysVitalSigns.isEmpty)
          Container(
            margin: const EdgeInsets.only(top: AppSpacing.m),
            padding: const EdgeInsets.all(AppSpacing.m),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMedium),
              border: Border.all(
                width: 1,
                color: AppTheme.outlineVariant,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.monitor_heart_outlined,
                  size: 48,
                  color: AppTheme.onSurfaceVariant,
                ),
                const SizedBox(height: AppSpacing.m),
                Text(
                  'No vital signs recorded today',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.m),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddVitalSignScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: AppTheme.onPrimaryColor,
                    ),
                    child: const Text('Add First Reading'),
                  ),
                ),
              ],
            ),
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
        if (hasReading) {
          // Show details or navigate to add new reading
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddVitalSignScreen(),
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.m),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMedium),
          border: Border.all(
            width: 1,
            color: isAbnormal ? AppTheme.errorColor : AppTheme.outlineVariant,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  type.icon ?? '📊',
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    type.displayName,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppTheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isAbnormal)
                  Icon(
                    Icons.warning,
                    color: AppTheme.errorColor,
                    size: 16,
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.s),
            Text(
              hasReading 
                  ? latestReading!.displayValue
                  : 'No data',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: hasReading 
                    ? (isAbnormal ? AppTheme.errorColor : AppTheme.primaryColor)
                    : AppTheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 12,
                  color: AppTheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    hasReading 
                        ? 'Latest: ${_formatTimeAgo(latestReading!.readingTime)}'
                        : 'Not recorded',
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
                  Icon(
                    Icons.today,
                    size: 12,
                    color: AppTheme.primaryColor,
                  ),
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
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: AppTheme.onSurfaceColor,
          ),
        ),
        const SizedBox(height: AppSpacing.m),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.5,
          mainAxisSpacing: AppSpacing.s,
          crossAxisSpacing: AppSpacing.s,
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
                    builder: (context) => const AddMedicineScreen(),
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
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.m),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMedium),
          border: Border.all(
            width: 1,
            color: AppTheme.outlineVariant,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: color,
              size: 32,
            ),
            const SizedBox(height: AppSpacing.s),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.onSurfaceColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, String message, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMedium),
        border: Border.all(
          width: 1,
          color: AppTheme.outlineVariant,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 48,
            color: AppTheme.onSurfaceVariant,
          ),
          const SizedBox(height: AppSpacing.m),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.l),
      decoration: BoxDecoration(
        color: AppTheme.errorContainer,
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMedium),
        border: Border.all(
          width: 1,
          color: AppTheme.errorColor,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: AppTheme.errorColor,
          ),
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
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.errorColor,
            ),
          ),
        ],
      ),
    );
  }
}
