import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../providers/timeline_provider.dart';
import '../../domain/entities/timeline_item.dart';

class TimelineScreen extends ConsumerStatefulWidget {
  const TimelineScreen({super.key});

  @override
  ConsumerState<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends ConsumerState<TimelineScreen> {
  String _selectedFilter = 'all'; // all, today, week, month
  String? _searchQuery;

  @override
  void initState() {
    super.initState();
    // Load initial timeline data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(timelineListProvider.notifier).loadAllTimeline();
    });
  }

@override
  Widget build(BuildContext context) {
    final timelineState = ref.watch(timelineListProvider);

    try {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Health Timeline'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                ref.read(timelineListProvider.notifier).refresh();
              },
            ),
          ],
        ),
        body: _buildBody(context, timelineState),
      );
    } catch (e) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Health Timeline'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red,
                ),
                SizedBox(height: 16),
                Text(
                  'Error loading timeline:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  e.toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14),
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    ref.read(timelineListProvider.notifier).refresh();
                  },
                  child: Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  Widget _buildBody(BuildContext context, TimelineListState timelineState) {
    // Show loading state
    if (timelineState.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // Show error state
    if (timelineState.error != null) {
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
              'Error: ${timelineState.error}',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.read(timelineListProvider.notifier).refresh(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Statistics bar
        _buildStatisticsBar(context, timelineState),
        const SizedBox(height: 8),
        
        // Filter tabs
        _buildFilterTabs(context),
        const SizedBox(height: 8),
        
        // Search results indicator
        if (_searchQuery != null && _searchQuery!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  'Search results for "$_searchQuery"',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _searchQuery = null;
                    });
                  },
                  child: const Text('Clear'),
                ),
              ],
            ),
          ),
        
        // Timeline content
        Expanded(
          child: _buildTimelineContent(context, timelineState),
        ),
      ],
    );
  }

  Widget _buildStatisticsBar(BuildContext context, TimelineListState timelineState) {
    final stats = _calculateStatistics(timelineState.items);
    
    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Timeline Summary',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(context, 'Total', stats['total'] ?? 0, Icons.timeline),
              _buildStatItem(context, 'Medicines', stats['medicines'] ?? 0, Icons.medication),
              _buildStatItem(context, 'Prescriptions', stats['prescriptions'] ?? 0, Icons.description),
              _buildStatItem(context, 'Follow-ups', stats['followUps'] ?? 0, Icons.calendar_today),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, int count, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          size: 24,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 4),
        Text(
          count.toString(),
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

  Widget _buildFilterTabs(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip(context, 'All', 'all'),
                  const SizedBox(width: 8),
                  _buildFilterChip(context, 'Today', 'today'),
                  const SizedBox(width: 8),
                  _buildFilterChip(context, 'This Week', 'week'),
                  const SizedBox(width: 8),
                  _buildFilterChip(context, 'This Month', 'month'),
                  const SizedBox(width: 8),
                  _buildFilterChip(context, 'Custom Range', 'custom'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(BuildContext context, String label, String value) {
    final isSelected = _selectedFilter == value;
    
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
        });
        _applyFilter(value);
      },
      selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected 
              ? Theme.of(context).colorScheme.primary 
              : Theme.of(context).colorScheme.outline,
        ),
      ),
    );
  }

  Widget _buildTimelineContent(BuildContext context, TimelineListState timelineState) {
    if (timelineState.items.isEmpty && !timelineState.isLoading && timelineState.error == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.timeline,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'No timeline items found',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              _getEmptyMessage(),
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Group items by date
    final groupedItems = <String, List<TimelineItem>>{};
    for (final item in timelineState.items) {
      final dateKey = '${item.date.year}-${item.date.month.toString().padLeft(2, '0')}-${item.date.day.toString().padLeft(2, '0')}';
      if (!groupedItems.containsKey(dateKey)) {
        groupedItems[dateKey] = [];
      }
      groupedItems[dateKey]!.add(item);
    }
    
    // Sort groups by date (newest first)
    final sortedGroups = Map.fromEntries(
      groupedItems.entries.toList()
        ..sort((a, b) => b.key.compareTo(a.key)),
    );

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(timelineListProvider.notifier).refresh();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: sortedGroups.length,
        itemBuilder: (context, index) {
          try {
            final dateKey = sortedGroups.keys.elementAt(index);
            final items = sortedGroups[dateKey]!;
            
            return _buildDateGroup(context, dateKey, items);
} catch (e) {
            return Card(
              color: Colors.red.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Error building timeline item:',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text('Error: $e'),
                    SizedBox(height: 4),
                    Text('Index: $index'),
                    SizedBox(height: 4),
                    Text('Group length: ${sortedGroups.length}'),
                  ],
                ),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildDateGroup(BuildContext context, String dateKey, List<TimelineItem> items) {
    final dateDisplay = _getDateDisplay(dateKey);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date header
        Padding(
          padding: const EdgeInsets.only(bottom: 8, top: 16),
          child: Text(
            dateDisplay,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        
        // Timeline items for this date
        Column(
          children: items.map((item) => _buildTimelineItem(context, item)).toList(),
        ),
      ],
    );
  }

  Widget _buildTimelineItem(BuildContext context, TimelineItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon based on type
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getTypeColor(context, item.type),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  item.type.icon,
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),
            const SizedBox(width: 12),
            
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and time
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        DateFormat('HH:mm').format(item.date),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  
                  // Description
                  if (item.description.isNotEmpty)
                    Text(
                      item.description,
                      style: Theme.of(context).textTheme.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  
                  // Status and metadata
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (item.status.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getStatusColor(context, item.status),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            item.status,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      const Spacer(),
                      Text(
                        item.type.displayName,
                        style: Theme.of(context).textTheme.bodySmall,
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

  Color _getTypeColor(BuildContext context, TimelineItemType type) {
    switch (type) {
      case TimelineItemType.medicine:
        return Colors.blue.shade100;
      case TimelineItemType.prescription:
        return Colors.green.shade100;
      case TimelineItemType.followUp:
        return Colors.orange.shade100;
      case TimelineItemType.reminderLog:
        return Colors.purple.shade100;
    }
  }

  Color _getStatusColor(BuildContext context, String status) {
    final lowerStatus = status.toLowerCase();
    
    if (lowerStatus.contains('taken') || lowerStatus.contains('completed') || lowerStatus.contains('success')) {
      return Colors.green;
    } else if (lowerStatus.contains('pending') || lowerStatus.contains('scheduled')) {
      return Colors.blue;
    } else if (lowerStatus.contains('skipped') || lowerStatus.contains('cancelled') || lowerStatus.contains('missed')) {
      return Colors.red;
    } else if (lowerStatus.contains('rescheduled') || lowerStatus.contains('snoozed')) {
      return Colors.orange;
    } else {
      return Colors.grey;
    }
  }

  void _applyFilter(String filter) {
    switch (filter) {
      case 'all':
        ref.read(timelineListProvider.notifier).loadAllTimeline();
        break;
      case 'today':
        ref.read(timelineListProvider.notifier).loadTodayTimeline();
        break;
      case 'week':
        ref.read(timelineListProvider.notifier).loadThisWeekTimeline();
        break;
      case 'month':
        ref.read(timelineListProvider.notifier).loadThisMonthTimeline();
        break;
      case 'custom':
        _showDateRangePicker(context);
        break;
    }
  }

  void _showDateRangePicker(BuildContext context) {
    showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(
        start: DateTime.now().subtract(const Duration(days: 30)),
        end: DateTime.now(),
      ),
    ).then((dateRange) {
      if (dateRange != null) {
        ref.read(timelineListProvider.notifier).loadTimeline(
          startDate: dateRange.start,
          endDate: dateRange.end,
        );
      }
    });
  }

  void _showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Timeline'),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search by title, description, or status...',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            // You could implement real-time search here
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Implement search functionality
              Navigator.pop(context);
            },
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }

  void _handleExportOption(String option) {
    switch (option) {
      case 'csv':
        _exportAsCsv();
        break;
      case 'json':
        _exportAsJson();
        break;
    }
  }

  Future<void> _exportAsCsv() async {
    try {
      final timelineRepository = ref.read(timelineRepositoryProvider);
      final csvData = await timelineRepository.exportTimelineAsCsv();
      
      // In a real app, you would save this to a file and share it
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'CSV export ready (${csvData.length} bytes)',
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _exportAsJson() async {
    try {
      final timelineRepository = ref.read(timelineRepositoryProvider);
      final jsonData = await timelineRepository.exportTimelineAsJson();
      
      // In a real app, you would save this to a file and share it
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'JSON export ready (${jsonData.length} bytes)',
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _getDateDisplay(String dateKey) {
    try {
      final parts = dateKey.split('-');
      if (parts.length != 3) return dateKey;
      
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final day = int.parse(parts[2]);
      
      final date = DateTime(year, month, day);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      if (date == today) {
        return 'Today';
      } else if (date == today.subtract(const Duration(days: 1))) {
        return 'Yesterday';
      } else if (date.isAfter(today.subtract(const Duration(days: 7)))) {
        final daysAgo = today.difference(date).inDays;
        return '$daysAgo days ago';
      } else {
        return '${day.toString().padLeft(2, '0')}/${month.toString().padLeft(2, '0')}/$year';
      }
    } catch (e) {
      return dateKey;
    }
  }

  Map<String, int> _calculateStatistics(List<TimelineItem> items) {
    final stats = <String, int>{
      'total': items.length,
      'medicines': items.where((item) => item.type == TimelineItemType.medicine).length,
      'prescriptions': items.where((item) => item.type == TimelineItemType.prescription).length,
      'followUps': items.where((item) => item.type == TimelineItemType.followUp).length,
      'reminderLogs': items.where((item) => item.type == TimelineItemType.reminderLog).length,
    };
    
    return stats;
  }

  String _getEmptyMessage() {
    switch (_selectedFilter) {
      case 'all':
        return 'Add medicines, prescriptions, or follow-ups to see them in your timeline.';
      case 'today':
        return 'No timeline items for today. Check back later or add new items.';
      case 'week':
        return 'No timeline items for this week.';
      case 'month':
        return 'No timeline items for this month.';
      case 'custom':
        return 'No timeline items in the selected date range.';
      default:
        return 'No timeline items found.';
    }
  }
}