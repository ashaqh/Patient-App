import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/themes/app_theme.dart';
import '../../core/constants/spacing_constants.dart';
import '../../domain/entities/follow_up.dart';
import '../providers/follow_up_provider.dart';
import 'add_follow_up_screen_new.dart';

class FollowUpListScreenNew extends ConsumerWidget {
  const FollowUpListScreenNew({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final followUpListState = ref.watch(followUpListProvider);
    final followUpStatsAsync = ref.watch(followUpStatisticsProvider);

    return Scaffold(
      backgroundColor: AppTheme.secondaryColor,
      body: CustomScrollView(
        slivers: [
          // Modern App Bar
          SliverAppBar(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: AppTheme.onPrimaryColor,
            elevation: 0,
            floating: true,
            pinned: true,
            title: Text(
              'Follow-ups',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppTheme.onPrimaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () => _showSearchDialog(context, ref),
                tooltip: 'Search',
              ),
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: () => _showFilterDialog(context, ref),
                tooltip: 'Filter',
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  ref.read(followUpListProvider.notifier).refresh();
                },
                tooltip: 'Refresh',
              ),
            ],
          ),

          // Main Content
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Statistics Section
                _buildStatisticsSection(context, followUpStatsAsync),
                const SizedBox(height: AppSpacing.l),

                // Quick Filter Chips
                _buildQuickFilters(context, ref),
                const SizedBox(height: AppSpacing.l),

                // Follow-ups List
                _buildFollowUpsList(context, ref, followUpListState),
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
              builder: (context) => const AddFollowUpScreenNew(),
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

  Widget _buildStatisticsSection(BuildContext context, AsyncValue<Map<String, int>> statsAsync) {
    return statsAsync.when(
      data: (stats) {
        final total = stats['total'] ?? 0;
        final scheduled = stats['scheduled'] ?? 0;
        final completed = stats['completed'] ?? 0;
        final overdue = stats['overdue'] ?? 0;

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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Overview',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppTheme.onSurfaceColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Icon(Icons.insights, color: AppTheme.primaryColor, size: 24),
                ],
              ),
              const SizedBox(height: AppSpacing.m),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.6,
                mainAxisSpacing: AppSpacing.m,
                crossAxisSpacing: AppSpacing.m,
                children: [
                  _buildStatCard(
                    context,
                    'Total',
                    total.toString(),
                    Icons.calendar_today,
                    AppTheme.primaryColor,
                    AppTheme.primaryColor.withOpacity(0.1),
                  ),
                  _buildStatCard(
                    context,
                    'Scheduled',
                    scheduled.toString(),
                    Icons.schedule,
                    Colors.white,
                    Colors.blue.shade600,
                  ),
                  _buildStatCard(
                    context,
                    'Completed',
                    completed.toString(),
                    Icons.check_circle,
                    Colors.white,
                    Colors.green.shade600,
                  ),
                  _buildStatCard(
                    context,
                    'Overdue',
                    overdue.toString(),
                    Icons.warning,
                    Colors.white,
                    Colors.orange.shade600,
                  ),
                ],
              ),
            ],
          ),
        );
      },
      loading: () => Container(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMedium),
        ),
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => Container(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMedium),
        ),
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: AppSpacing.m),
            Text(
              'Error loading statistics',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.errorColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value, IconData icon, Color iconColor, Color backgroundColor) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSmall),
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
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 20, color: iconColor),
              ),
              const Spacer(),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickFilters(BuildContext context, WidgetRef ref) {
    final currentFilter = ref.watch(_followUpFilterProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Quick Filters',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppTheme.onSurfaceColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.filter_list,
                color: AppTheme.primaryColor,
                size: 20,
              ),
              onPressed: () => _showFilterDialog(context, ref),
              tooltip: 'More filters',
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.m),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip(context, 'All', 'All', currentFilter, ref, Icons.all_inclusive),
              const SizedBox(width: AppSpacing.s),
              _buildFilterChip(context, 'Today', 'Today', currentFilter, ref, Icons.today),
              const SizedBox(width: AppSpacing.s),
              _buildFilterChip(context, 'Upcoming', 'Upcoming', currentFilter, ref, Icons.upcoming),
              const SizedBox(width: AppSpacing.s),
              _buildFilterChip(context, 'Overdue', 'Overdue', currentFilter, ref, Icons.warning),
              const SizedBox(width: AppSpacing.s),
              _buildFilterChip(context, 'Completed', 'Completed', currentFilter, ref, Icons.check_circle),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(BuildContext context, String label, String value, String currentFilter, WidgetRef ref, IconData icon) {
    final isSelected = currentFilter == value;
    Color chipColor;
    Color textColor;
    
    if (isSelected) {
      switch (value) {
        case 'Today':
          chipColor = Colors.blue.shade600;
          textColor = Colors.white;
          break;
        case 'Upcoming':
          chipColor = Colors.blue.shade400;
          textColor = Colors.white;
          break;
        case 'Overdue':
          chipColor = Colors.orange.shade600;
          textColor = Colors.white;
          break;
        case 'Completed':
          chipColor = Colors.green.shade600;
          textColor = Colors.white;
          break;
        default:
          chipColor = AppTheme.primaryColor;
          textColor = AppTheme.onPrimaryColor;
      }
    } else {
      chipColor = AppTheme.surfaceContainer;
      textColor = AppTheme.onSurfaceColor;
    }
    
    return Container(
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: chipColor.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: InkWell(
        onTap: () {
          ref.read(_followUpFilterProvider.notifier).state = value;
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: textColor.withOpacity(0.9),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: textColor,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFollowUpsList(BuildContext context, WidgetRef ref, FollowUpListState followUpListState) {
    if (followUpListState.isLoading) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (followUpListState.error != null) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMedium),
        ),
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 64),
            const SizedBox(height: AppSpacing.m),
            Text(
              'Error loading follow-ups',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.errorColor,
              ),
            ),
            const SizedBox(height: AppSpacing.m),
            ElevatedButton(
              onPressed: () => ref.read(followUpListProvider.notifier).refresh(),
              style: AppTheme.primaryButtonStyle,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final currentFilter = ref.watch(_followUpFilterProvider);
    List<FollowUp> filteredFollowUps = [];

    switch (currentFilter) {
      case 'Today':
        filteredFollowUps = followUpListState.followUps.where((f) => f.isToday).toList();
        break;
      case 'Upcoming':
        filteredFollowUps = followUpListState.followUps.where((f) => f.isUpcoming).toList();
        break;
      case 'Overdue':
        filteredFollowUps = followUpListState.followUps.where((f) => f.isOverdue).toList();
        break;
      case 'Completed':
        filteredFollowUps = followUpListState.followUps.where((f) => f.isCompleted).toList();
        break;
      default: // 'All'
        filteredFollowUps = followUpListState.followUps;
    }

    filteredFollowUps.sort((a, b) => a.date.compareTo(b.date));

    if (filteredFollowUps.isEmpty) {
      return _buildEmptyState(context, currentFilter);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Follow-ups (${filteredFollowUps.length})',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: AppTheme.onSurfaceColor,
          ),
        ),
        const SizedBox(height: AppSpacing.m),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: filteredFollowUps.length,
          separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.s),
          itemBuilder: (context, index) {
            final followUp = filteredFollowUps[index];
            return _buildFollowUpCard(context, ref, followUp);
          },
        ),
      ],
    );
  }

  Widget _buildFollowUpCard(BuildContext context, WidgetRef ref, FollowUp followUp) {
    final statusColor = _getStatusColor(followUp.status);
    final urgencyColor = _getUrgencyColor(followUp.urgencyLevel);
    final isUrgent = followUp.urgencyLevel >= 2;
    final isOverdue = followUp.isOverdue;

    return GestureDetector(
      onTap: () => _showFollowUpDetails(context, ref, followUp),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.m),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMedium),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: isUrgent 
                ? urgencyColor.withOpacity(0.4) 
                : isOverdue 
                  ? Colors.orange.withOpacity(0.3)
                  : AppTheme.outlineVariant,
            width: isUrgent || isOverdue ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with status indicator
            Container(
              height: 4,
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppSpacing.borderRadiusMedium),
                  topRight: Radius.circular(AppSpacing.borderRadiusMedium),
                ),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(AppSpacing.cardPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title row with status badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              followUp.title,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppTheme.onSurfaceColor,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            // Date and time in a single line
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: 14,
                                  color: AppTheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  DateFormat('MMM d').format(followUp.date),
                                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                    color: AppTheme.onSurfaceColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.access_time,
                                  size: 14,
                                  color: AppTheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  DateFormat('h:mm a').format(followUp.date),
                                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                    color: AppTheme.onSurfaceColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: statusColor.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              followUp.status.emoji,
                              style: const TextStyle(fontSize: 12),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              followUp.status.displayName,
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: statusColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: AppSpacing.m),
                  
                  // Details section
                  if (followUp.doctorName != null || followUp.clinicName != null)
                    _buildCardDetailRow(
                      context,
                      Icons.person_outline,
                      '${followUp.doctorName ?? ''}${followUp.clinicName != null ? ' • ${followUp.clinicName}' : ''}',
                    ),
                  
                  if (followUp.location != null)
                    _buildCardDetailRow(
                      context,
                      Icons.location_on_outlined,
                      followUp.location!,
                    ),
                  
                  if (followUp.notes != null && followUp.notes!.isNotEmpty)
                    _buildCardDetailRow(
                      context,
                      Icons.note_outlined,
                      followUp.notes!,
                      maxLines: 2,
                    ),
                  
                  const SizedBox(height: AppSpacing.m),
                  
                  // Footer with actions and urgency indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Urgency indicator
                      if (followUp.urgencyLevel > 0 && followUp.status == FollowUpStatus.scheduled)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: urgencyColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: urgencyColor.withOpacity(0.4)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getUrgencyIcon(followUp.urgencyLevel),
                                size: 12,
                                color: urgencyColor,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _getUrgencyText(followUp),
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: urgencyColor,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      
                      // Action buttons
                      Row(
                        children: [
                          if (followUp.status == FollowUpStatus.scheduled)
                            IconButton(
                              icon: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.green.shade100),
                                ),
                                child: Icon(
                                  Icons.check_circle,
                                  size: 20,
                                  color: Colors.green.shade700,
                                ),
                              ),
                              onPressed: () => _confirmCompleteFollowUp(context, ref, followUp),
                              tooltip: 'Mark as Completed',
                            ),
                          IconButton(
                            icon: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
                              ),
                              child: Icon(
                                Icons.more_horiz,
                                size: 20,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            onPressed: () => _showActionMenu(context, ref, followUp),
                            tooltip: 'More Actions',
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardDetailRow(BuildContext context, IconData icon, String text, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 16,
            color: AppTheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.onSurfaceColor.withOpacity(0.9),
              ),
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, String filter) {
    String message;
    String subtitle;
    IconData icon;
    Color iconColor;
    Color backgroundColor;

    switch (filter) {
      case 'Today':
        message = 'No follow-ups for today';
        subtitle = 'Enjoy your day! You can schedule new appointments anytime.';
        icon = Icons.emoji_emotions_outlined;
        iconColor = Colors.blue.shade600;
        backgroundColor = Colors.blue.shade50;
        break;
      case 'Upcoming':
        message = 'No upcoming appointments';
        subtitle = 'Your schedule is clear for now. Add new follow-ups to stay on track.';
        icon = Icons.schedule_outlined;
        iconColor = Colors.blue.shade500;
        backgroundColor = Colors.blue.shade50;
        break;
      case 'Overdue':
        message = 'No overdue follow-ups';
        subtitle = 'Great job staying on schedule! All your appointments are up to date.';
        icon = Icons.check_circle_outline;
        iconColor = Colors.green.shade600;
        backgroundColor = Colors.green.shade50;
        break;
      case 'Completed':
        message = 'No completed follow-ups';
        subtitle = 'Start tracking your appointments to see completed ones here.';
        icon = Icons.assignment_turned_in_outlined;
        iconColor = Colors.green.shade500;
        backgroundColor = Colors.green.shade50;
        break;
      default:
        message = 'No follow-ups yet';
        subtitle = 'Start managing your health appointments by adding your first follow-up.';
        icon = Icons.calendar_month_outlined;
        iconColor = AppTheme.primaryColor;
        backgroundColor = AppTheme.primaryColor.withOpacity(0.08);
    }

    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.xl),
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMedium),
        border: Border.all(color: iconColor.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: iconColor.withOpacity(0.2), width: 2),
              boxShadow: [
                BoxShadow(
                  color: iconColor.withOpacity(0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, size: 48, color: iconColor),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            message,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: iconColor,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.m),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppTheme.onSurfaceVariant,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
builder: (context) => const AddFollowUpScreenNew(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: iconColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.add, size: 20),
                SizedBox(width: 8),
                Text('Add Follow-up'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(FollowUpStatus status) {
    switch (status) {
      case FollowUpStatus.scheduled:
        return Colors.blue;
      case FollowUpStatus.completed:
        return Colors.green;
      case FollowUpStatus.cancelled:
        return Colors.red;
      case FollowUpStatus.rescheduled:
        return Colors.orange;
    }
  }

  Color _getUrgencyColor(int urgencyLevel) {
    switch (urgencyLevel) {
      case 3:
        return Colors.red;
      case 2:
        return Colors.orange;
      case 1:
        return Colors.yellow.shade700;
      default:
        return Colors.grey;
    }
  }

  IconData _getUrgencyIcon(int urgencyLevel) {
    switch (urgencyLevel) {
      case 3:
        return Icons.warning;
      case 2:
        return Icons.warning_amber;
      case 1:
        return Icons.info;
      default:
        return Icons.circle;
    }
  }

  String _getUrgencyText(FollowUp followUp) {
    if (followUp.isOverdue) {
      return 'Overdue by ${followUp.daysUntil.abs()} day${followUp.daysUntil.abs() == 1 ? '' : 's'}';
    } else if (followUp.isToday) {
      return 'Today at ${followUp.displayTime}';
    } else if (followUp.daysUntil == 1) {
      return 'Tomorrow';
    } else if (followUp.daysUntil <= 3) {
      return 'In ${followUp.daysUntil} days';
    }
    return 'Scheduled';
  }

  Future<void> _showSearchDialog(BuildContext context, WidgetRef ref) async {
    final searchController = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.cardPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.l),
                  decoration: BoxDecoration(
                    color: AppTheme.outlineColor.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'Search Follow-ups',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppTheme.onSurfaceColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.m),
              TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: 'Search by title, doctor, clinic, or notes...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.outlineColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.primaryColor),
                  ),
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: AppTheme.secondaryColor,
                ),
                autofocus: true,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: AppSpacing.l),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.onSurfaceColor,
                        side: const BorderSide(color: AppTheme.outlineColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.m),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        if (searchController.text.isNotEmpty) {
                          final results = await ref.read(followUpListProvider.notifier).searchFollowUps(searchController.text);
                          _showSearchResults(context, results, searchController.text, ref);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Search'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.s),
            ],
          ),
        ),
      ),
    );
  }

  void _showSearchResults(BuildContext context, List<FollowUp> results, String query, WidgetRef ref) {
    if (results.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.search_off, color: AppTheme.onSurfaceVariant),
              const SizedBox(width: 8),
              const Text('No Results'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('No follow-ups found for "$query"'),
              const SizedBox(height: 16),
              Icon(
                Icons.search_off,
                size: 64,
                color: AppTheme.onSurfaceVariant.withOpacity(0.3),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.cardPadding),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Search Results (${results.length})',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.cardPadding),
                itemCount: results.length,
                itemBuilder: (context, index) {
                  final followUp = results[index];
                  final statusColor = _getStatusColor(followUp.status);
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: AppSpacing.m),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMedium),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.m,
                        vertical: AppSpacing.s,
                      ),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          followUp.status.emoji,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      title: Text(
                        followUp.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat('MMM d, yyyy • h:mm a').format(followUp.date),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          if (followUp.doctorName != null)
                            Text(
                              followUp.doctorName!,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        _showFollowUpDetails(context, ref, followUp);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterDialog(BuildContext context, WidgetRef ref) {
    final currentFilter = ref.watch(_followUpFilterProvider);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Follow-ups'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildFilterDialogOption(context, 'All', currentFilter, ref),
            _buildFilterDialogOption(context, 'Today', currentFilter, ref),
            _buildFilterDialogOption(context, 'Upcoming', currentFilter, ref),
            _buildFilterDialogOption(context, 'Overdue', currentFilter, ref),
            _buildFilterDialogOption(context, 'Completed', currentFilter, ref),
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

  Widget _buildFilterDialogOption(BuildContext context, String filter, String currentFilter, WidgetRef ref) {
    final isSelected = currentFilter == filter;
    
    return ListTile(
      title: Text(filter),
      trailing: isSelected ? const Icon(Icons.check) : null,
      onTap: () {
        ref.read(_followUpFilterProvider.notifier).state = filter;
        Navigator.pop(context);
      },
    );
  }

  void _showFollowUpDetails(BuildContext context, WidgetRef ref, FollowUp followUp) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.outlineColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.m),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  followUp.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(followUp.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _getStatusColor(followUp.status).withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(followUp.status.emoji),
                      const SizedBox(width: 4),
                      Text(
                        followUp.status.displayName,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: _getStatusColor(followUp.status),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.l),
            _buildDetailRow(context, Icons.calendar_today, 'Date', DateFormat('EEEE, MMMM d, yyyy').format(followUp.date)),
            _buildDetailRow(context, Icons.access_time, 'Time', DateFormat('h:mm a').format(followUp.date)),
            if (followUp.doctorName != null)
              _buildDetailRow(context, Icons.person, 'Doctor', followUp.doctorName!),
            if (followUp.clinicName != null)
              _buildDetailRow(context, Icons.local_hospital, 'Clinic', followUp.clinicName!),
            if (followUp.location != null)
              _buildDetailRow(context, Icons.location_on, 'Location', followUp.location!),
            if (followUp.notes != null && followUp.notes!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.m),
              Text('Notes:', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.xs),
              Text(followUp.notes!),
            ],
            const SizedBox(height: AppSpacing.l),
            if (followUp.status == FollowUpStatus.scheduled)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _confirmCompleteFollowUp(context, ref, followUp);
                  },
                  style: AppTheme.primaryButtonStyle,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle),
                      SizedBox(width: 8),
                      Text('Mark as Completed'),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: AppSpacing.s),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryColor,
                  side: BorderSide(color: AppTheme.primaryColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppTheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.onSurfaceColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showActionMenu(BuildContext context, WidgetRef ref, FollowUp followUp) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.cardPadding),
              child: Text(
                followUp.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Divider(height: 1),
            if (followUp.status == FollowUpStatus.scheduled) ...[
              ListTile(
                leading: const Icon(Icons.check_circle, color: Colors.green),
                title: const Text('Mark as Completed'),
                onTap: () => Navigator.pop(context, 'complete'),
              ),
              ListTile(
                leading: const Icon(Icons.cancel, color: Colors.orange),
                title: const Text('Cancel'),
                onTap: () => Navigator.pop(context, 'cancel'),
              ),
            ],
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit'),
              onTap: () => Navigator.pop(context, 'edit'),
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () => Navigator.pop(context, 'delete'),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('Cancel'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );

    if (action != null) {
      switch (action) {
        case 'complete':
          await _confirmCompleteFollowUp(context, ref, followUp);
          break;
        case 'cancel':
          await _confirmCancelFollowUp(context, ref, followUp);
          break;
        case 'edit':
          _navigateToEditFollowUp(context, followUp);
          break;
        case 'delete':
          await _confirmDeleteFollowUp(context, ref, followUp);
          break;
      }
    }
  }

  Future<void> _confirmCompleteFollowUp(BuildContext context, WidgetRef ref, FollowUp followUp) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark as Completed'),
        content: Text('Are you sure you want to mark "${followUp.title}" as completed?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Complete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(followUpListProvider.notifier).markAsCompleted(followUp.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"${followUp.title}" marked as completed'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _confirmCancelFollowUp(BuildContext context, WidgetRef ref, FollowUp followUp) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Follow-up'),
        content: Text('Are you sure you want to cancel "${followUp.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(followUpListProvider.notifier).updateStatus(followUp.id, FollowUpStatus.cancelled);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${followUp.title}" cancelled'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _confirmDeleteFollowUp(BuildContext context, WidgetRef ref, FollowUp followUp) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Follow-up'),
        content: Text('Are you sure you want to delete "${followUp.title}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(followUpListProvider.notifier).deleteFollowUp(followUp.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${followUp.title}" deleted'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _navigateToEditFollowUp(BuildContext context, FollowUp followUp) {
    // TODO: Implement edit follow-up screen navigation
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Follow-up'),
        content: const Text('Edit functionality will be implemented in the next phase.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

// Filter provider for follow-ups
final _followUpFilterProvider = StateProvider<String>((ref) => 'All');
