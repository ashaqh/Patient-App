import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/follow_up.dart';
import '../providers/follow_up_provider.dart';
import 'add_follow_up_screen.dart';

class FollowUpListScreen extends ConsumerWidget {
  const FollowUpListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final followUpListState = ref.watch(followUpListProvider);
    final todaysFollowUpsAsync = ref.watch(todaysFollowUpsProvider);
    final upcomingFollowUpsAsync = ref.watch(upcomingFollowUpsProvider);
    final overdueFollowUpsAsync = ref.watch(overdueFollowUpsProvider);
    final followUpStatsAsync = ref.watch(followUpStatisticsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Follow-up Appointments'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(followUpListProvider.notifier).refresh();
            },
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              _showSearchDialog(context, ref);
            },
          ),
        ],
      ),
      body: _buildBody(
        context,
        ref,
        followUpListState,
        todaysFollowUpsAsync,
        upcomingFollowUpsAsync,
        overdueFollowUpsAsync,
        followUpStatsAsync,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddFollowUpScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    FollowUpListState followUpListState,
    AsyncValue<List<FollowUp>> todaysFollowUpsAsync,
    AsyncValue<List<FollowUp>> upcomingFollowUpsAsync,
    AsyncValue<List<FollowUp>> overdueFollowUpsAsync,
    AsyncValue<Map<String, int>> followUpStatsAsync,
  ) {
    // Show loading state
    if (followUpListState.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // Show error state
    if (followUpListState.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Error: ${followUpListState.error}',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.read(followUpListProvider.notifier).refresh(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Statistics bar
        _buildStatisticsBar(context, followUpStatsAsync),
        const SizedBox(height: 8),
        
        // Filter tabs
        _buildFilterTabs(context, ref),
        const SizedBox(height: 8),
        
        // List of follow-ups
        Expanded(
          child: _buildFollowUpList(context, ref, followUpListState),
        ),
      ],
    );
  }

  Widget _buildStatisticsBar(BuildContext context, AsyncValue<Map<String, int>> statsAsync) {
    return statsAsync.when(
      data: (stats) {
        final total = stats['total'] ?? 0;
        final scheduled = stats['scheduled'] ?? 0;
        final completed = stats['completed'] ?? 0;
        final overdue = stats['scheduled'] ?? 0; // We'll calculate overdue separately

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(context, 'Total', total.toString(), Icons.calendar_today),
              _buildStatItem(context, 'Scheduled', scheduled.toString(), Icons.schedule),
              _buildStatItem(context, 'Completed', completed.toString(), Icons.check_circle),
              _buildStatItem(context, 'Overdue', overdue.toString(), Icons.warning),
            ],
          ),
        );
      },
      loading: () => Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.all(8),
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.all(8),
        child: Text('Error loading stats: $error'),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 24, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildFilterTabs(BuildContext context, WidgetRef ref) {
    final currentFilter = ref.watch(_followUpFilterProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Expanded(
            child: ChoiceChips(
              options: const ['All', 'Today', 'Upcoming', 'Overdue', 'Completed'],
              selectedOption: currentFilter,
              onSelected: (option) {
                ref.read(_followUpFilterProvider.notifier).state = option;
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFollowUpList(
    BuildContext context,
    WidgetRef ref,
    FollowUpListState followUpListState,
  ) {
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

    // Sort by date (closest first)
    filteredFollowUps.sort((a, b) => a.date.compareTo(b.date));

    if (filteredFollowUps.isEmpty) {
      return _buildEmptyState(context, currentFilter);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: filteredFollowUps.length,
      itemBuilder: (context, index) {
        final followUp = filteredFollowUps[index];
        return _buildFollowUpCard(context, ref, followUp);
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, String filter) {
    String message;
    IconData icon;

    switch (filter) {
      case 'Today':
        message = 'No follow-ups scheduled for today';
        icon = Icons.calendar_today;
        break;
      case 'Upcoming':
        message = 'No upcoming follow-ups';
        icon = Icons.schedule;
        break;
      case 'Overdue':
        message = 'No overdue follow-ups';
        icon = Icons.warning;
        break;
      case 'Completed':
        message = 'No completed follow-ups';
        icon = Icons.check_circle;
        break;
      default:
        message = 'No follow-ups yet';
        icon = Icons.calendar_month;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to add a follow-up',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFollowUpCard(BuildContext context, WidgetRef ref, FollowUp followUp) {
    final statusColor = _getStatusColor(followUp.status);
    final urgencyColor = _getUrgencyColor(followUp.urgencyLevel);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: () {
          _showFollowUpDetails(context, ref, followUp);
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status indicator
              Container(
                width: 8,
                height: 60,
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              
              // Follow-up details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          followUp.title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              followUp.status.emoji,
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              followUp.status.displayName,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    
                    // Date and time
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('EEE, MMM d, yyyy').format(followUp.date),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.access_time,
                          size: 16,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('h:mm a').format(followUp.date),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                    
                    // Doctor and clinic
                    if (followUp.doctorName != null || followUp.clinicName != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            Icon(
                              Icons.person,
                              size: 16,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '${followUp.doctorName ?? ''}${followUp.clinicName != null ? ' • ${followUp.clinicName}' : ''}',
                                style: Theme.of(context).textTheme.bodySmall,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    // Location
                    if (followUp.location != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 16,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                followUp.location!,
                                style: Theme.of(context).textTheme.bodySmall,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    // Notes preview
                    if (followUp.notes != null && followUp.notes!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            Icon(
                              Icons.note,
                              size: 16,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                followUp.notes!,
                                style: Theme.of(context).textTheme.bodySmall,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    // Urgency indicator
                    if (followUp.urgencyLevel > 0 && followUp.status == FollowUpStatus.scheduled)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: urgencyColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: urgencyColor.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getUrgencyIcon(followUp.urgencyLevel),
                                size: 12,
                                color: urgencyColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _getUrgencyText(followUp),
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: urgencyColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              
              // Action menu
              PopupMenuButton<String>(
                onSelected: (value) => _handleMenuAction(context, ref, followUp, value),
                itemBuilder: (context) => [
                  if (followUp.status == FollowUpStatus.scheduled)
                    const PopupMenuItem<String>(
                      value: 'complete',
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, size: 20),
                          SizedBox(width: 8),
                          Text('Mark as Completed'),
                        ],
                      ),
                    ),
                  if (followUp.status == FollowUpStatus.scheduled)
                    const PopupMenuItem<String>(
                      value: 'cancel',
                      child: Row(
                        children: [
                          Icon(Icons.cancel, size: 20),
                          SizedBox(width: 8),
                          Text('Cancel'),
                        ],
                      ),
                    ),
                  const PopupMenuItem<String>(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 20),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 20, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Follow-ups'),
        content: TextField(
          controller: searchController,
          decoration: const InputDecoration(
            hintText: 'Search by title, doctor, clinic, or notes...',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              if (searchController.text.isNotEmpty) {
                final results = await ref.read(followUpListProvider.notifier).searchFollowUps(searchController.text);
                _showSearchResults(context, results, searchController.text);
              }
            },
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }

  void _showSearchResults(BuildContext context, List<FollowUp> results, String query) {
    if (results.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('No Results'),
          content: Text('No follow-ups found for "$query"'),
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

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Search Results (${results.length})'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: results.length,
            itemBuilder: (context, index) {
              final followUp = results[index];
              return ListTile(
                leading: Text(followUp.status.emoji),
                title: Text(followUp.title),
                subtitle: Text('${DateFormat('MMM d, yyyy').format(followUp.date)} • ${followUp.doctorName ?? 'No doctor'}'),
                onTap: () {
                  Navigator.pop(context);
                  _showFollowUpDetails(context, null, followUp);
                },
              );
            },
          ),
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

  void _showFollowUpDetails(BuildContext context, WidgetRef? ref, FollowUp followUp) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(followUp.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow(context, 'Status', '${followUp.status.emoji} ${followUp.status.displayName}'),
              _buildDetailRow(context, 'Date', DateFormat('EEEE, MMMM d, yyyy').format(followUp.date)),
              _buildDetailRow(context, 'Time', DateFormat('h:mm a').format(followUp.date)),
              if (followUp.doctorName != null)
                _buildDetailRow(context, 'Doctor', followUp.doctorName!),
              if (followUp.clinicName != null)
                _buildDetailRow(context, 'Clinic', followUp.clinicName!),
              if (followUp.location != null)
                _buildDetailRow(context, 'Location', followUp.location!),
              if (followUp.notes != null && followUp.notes!.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Text('Notes:', style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 4),
                    Text(followUp.notes!),
                  ],
                ),
              if (followUp.completedAt != null)
                _buildDetailRow(context, 'Completed on', DateFormat('MMM d, yyyy').format(followUp.completedAt!)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (ref != null && followUp.status == FollowUpStatus.scheduled)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _handleMenuAction(context, ref, followUp, 'complete');
              },
              child: const Text('Mark as Completed'),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Future<void> _handleMenuAction(BuildContext context, WidgetRef ref, FollowUp followUp, String action) async {
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
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
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
    // For now, show a dialog with edit form
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

// Custom choice chips widget
class ChoiceChips extends StatelessWidget {
  final List<String> options;
  final String selectedOption;
  final Function(String) onSelected;

  const ChoiceChips({
    super.key,
    required this.options,
    required this.selectedOption,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: options.map((option) {
        final isSelected = option == selectedOption;
        return ChoiceChip(
          label: Text(option),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) {
              onSelected(option);
            }
          },
          selectedColor: Theme.of(context).colorScheme.primary,
          labelStyle: TextStyle(
            color: isSelected
                ? Theme.of(context).colorScheme.onPrimary
                : Theme.of(context).colorScheme.onSurface,
          ),
        );
      }).toList(),
    );
  }
}