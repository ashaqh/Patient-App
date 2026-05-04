import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/themes/app_theme.dart';
import '../../core/constants/spacing_constants.dart';
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
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _showFilters = false;

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
        backgroundColor: AppTheme.secondaryColor,
        body: CustomScrollView(
          controller: _scrollController,
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
                      'Health Timeline',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        color: AppTheme.onPrimaryColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Track your health history',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.onPrimaryColor.withAlpha(230),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.filter_list),
                  onPressed: () {
                    setState(() {
                      _showFilters = !_showFilters;
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    ref.read(timelineListProvider.notifier).refresh();
                  },
                ),
              ],
            ),

            // Main Content
            SliverPadding(
              padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Search Bar
                  _buildSearchBar(context),
                  const SizedBox(height: AppSpacing.m),

                  // Statistics Cards
                  _buildStatisticsCards(context, timelineState),
                  const SizedBox(height: AppSpacing.l),

                  // Filter Chips
                  if (_showFilters) _buildFilterChips(context),
                  if (_showFilters) const SizedBox(height: AppSpacing.m),

                  // Timeline Content
                  _buildTimelineContent(context, timelineState),
                  const SizedBox(height: AppSpacing.xxl),
                ]),
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            _showExportOptions(context);
          },
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: AppTheme.onPrimaryColor,
          child: const Icon(Icons.download),
        ),
      );
    } catch (e) {
      return Scaffold(
        backgroundColor: AppTheme.secondaryColor,
        appBar: AppBar(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: AppTheme.onPrimaryColor,
          title: const Text('Health Timeline'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: AppTheme.errorColor,
                ),
                const SizedBox(height: AppSpacing.l),
                Text(
                  'Error loading timeline:',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppTheme.errorColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.s),
                Text(
                  e.toString(),
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.l),
                ElevatedButton(
                  onPressed: () {
                    ref.read(timelineListProvider.notifier).refresh();
                  },
                  style: AppTheme.primaryButtonStyle,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  Widget _buildSearchBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search timeline...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = null;
                    });
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: AppTheme.surfaceColor,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value.isNotEmpty ? value : null;
          });
        },
      ),
    );
  }

  Widget _buildStatisticsCards(BuildContext context, TimelineListState timelineState) {
    final stats = _calculateStatistics(timelineState.items);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Timeline Overview',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: AppTheme.onSurfaceColor,
          ),
        ),
        const SizedBox(height: AppSpacing.m),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: AppSpacing.s,
          crossAxisSpacing: AppSpacing.s,
          childAspectRatio: 1.5,
          children: [
            _buildStatCard(
              context,
              'Total Items',
              stats['total']?.toString() ?? '0',
              Icons.timeline,
              AppTheme.primaryColor,
            ),
            _buildStatCard(
              context,
              'Medicines',
              stats['medicines']?.toString() ?? '0',
              Icons.medication,
              Colors.blue,
            ),
            _buildStatCard(
              context,
              'Prescriptions',
              stats['prescriptions']?.toString() ?? '0',
              Icons.description,
              Colors.green,
            ),
            _buildStatCard(
              context,
              'Follow-ups',
              stats['followUps']?.toString() ?? '0',
              Icons.calendar_today,
              Colors.orange,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(width: 1, color: AppTheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withAlpha(26),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: color,
                  ),
                ),
                const Spacer(),
              ],
            ),
            const SizedBox(height: AppSpacing.m),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: AppTheme.onSurfaceColor,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Filter by Time',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppTheme.onSurfaceColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.s),
        Wrap(
          spacing: AppSpacing.s,
          runSpacing: AppSpacing.s,
          children: [
            _buildModernFilterChip(context, 'All', 'all'),
            _buildModernFilterChip(context, 'Today', 'today'),
            _buildModernFilterChip(context, 'This Week', 'week'),
            _buildModernFilterChip(context, 'This Month', 'month'),
            _buildModernFilterChip(context, 'Custom Range', 'custom'),
          ],
        ),
      ],
    );
  }



  Widget _buildModernFilterChip(BuildContext context, String label, String value) {
    final isSelected = _selectedFilter == value;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = value;
        });
        _applyFilter(value);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.m,
          vertical: AppSpacing.s,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            width: 2,
            color: isSelected ? AppTheme.primaryColor : AppTheme.outlineColor,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primaryColor.withAlpha(77),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected)
              Icon(
                Icons.check,
                size: 16,
                color: AppTheme.onPrimaryColor,
              ),
            if (isSelected) const SizedBox(width: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: isSelected ? AppTheme.onPrimaryColor : AppTheme.onSurfaceColor,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineContent(BuildContext context, TimelineListState timelineState) {
    // Show loading state
    if (timelineState.isLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: AppSpacing.l),
              Text(
                'Loading timeline...',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Show error state
    if (timelineState.error != null) {
      return Container(
        decoration: BoxDecoration(
          color: AppTheme.errorContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(width: 2, color: AppTheme.errorColor),
        ),
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Column(
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: AppTheme.errorColor,
            ),
            const SizedBox(height: AppSpacing.m),
            Text(
              'Failed to load timeline',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.errorColor,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.s),
            Text(
              timelineState.error!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.m),
            ElevatedButton(
              onPressed: () => ref.read(timelineListProvider.notifier).refresh(),
              style: AppTheme.primaryButtonStyle,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // Show empty state
    if (timelineState.items.isEmpty && !timelineState.isLoading && timelineState.error == null) {
      return Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(width: 1, color: AppTheme.outlineVariant),
        ),
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.timeline,
              size: 64,
              color: AppTheme.neutralColor,
            ),
            const SizedBox(height: AppSpacing.l),
            Text(
              'No timeline items found',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppTheme.onSurfaceColor,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.s),
            Text(
              _getEmptyMessage(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

// Search filtering
    List<TimelineItem> filteredItems = timelineState.items;
    if (_searchQuery != null && _searchQuery!.isNotEmpty) {
      filteredItems = timelineState.items.where((item) {
        return item.title.toLowerCase().contains(_searchQuery!.toLowerCase()) ||
               item.description.toLowerCase().contains(_searchQuery!.toLowerCase()) ||
               item.status.toLowerCase().contains(_searchQuery!.toLowerCase());
      }).toList();
    }

    // Group items by date
    final groupedItems = <String, List<TimelineItem>>{};
    for (final item in filteredItems) {
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

    // Show search results indicator
    if (_searchQuery != null && _searchQuery!.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(width: 1, color: AppTheme.outlineVariant),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.m,
              vertical: AppSpacing.s,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.search,
                  size: 20,
                  color: AppTheme.onSurfaceVariant,
                ),
                const SizedBox(width: AppSpacing.s),
                Expanded(
                  child: Text(
                    '${filteredItems.length} results for "$_searchQuery"',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.onSurfaceVariant,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = null;
                    });
                  },
                  style: TextButton.styleFrom(
                    minimumSize: const Size(0, 0),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.s,
                      vertical: 4,
                    ),
                  ),
                  child: Text(
                    'Clear',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.l),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await ref.read(timelineListProvider.notifier).refresh();
              },
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
                itemCount: sortedGroups.length,
                itemBuilder: (context, index) {
                  try {
                    final dateKey = sortedGroups.keys.elementAt(index);
                    final items = sortedGroups[dateKey]!;
                    
                    return _buildDateGroup(context, dateKey, items);
                  } catch (e) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: AppSpacing.m),
                      decoration: BoxDecoration(
                        color: AppTheme.errorContainer,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(width: 2, color: AppTheme.errorColor),
                      ),
                      padding: const EdgeInsets.all(AppSpacing.m),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Error building timeline item:',
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: AppTheme.errorColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.s),
                          Text(
                            'Error: $e',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    );
                  }
                },
              ),
            ),
          ),
        ],
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(timelineListProvider.notifier).refresh();
      },
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
        itemCount: sortedGroups.length,
        itemBuilder: (context, index) {
          try {
            final dateKey = sortedGroups.keys.elementAt(index);
            final items = sortedGroups[dateKey]!;
            
            return _buildDateGroup(context, dateKey, items);
          } catch (e) {
            return Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.m),
              decoration: BoxDecoration(
                color: AppTheme.errorContainer,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(width: 2, color: AppTheme.errorColor),
              ),
              padding: const EdgeInsets.all(AppSpacing.m),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Error building timeline item:',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppTheme.errorColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s),
                  Text(
                    'Error: $e',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
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
        Container(
          margin: const EdgeInsets.only(top: AppSpacing.l, bottom: AppSpacing.m),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.m,
            vertical: AppSpacing.s,
          ),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withAlpha(26),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(width: 1, color: AppTheme.primaryColor.withAlpha(77)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 16,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(width: AppSpacing.s),
              Text(
                dateDisplay,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
              ),
              const Spacer(),
              Text(
                '${items.length} ${items.length == 1 ? 'item' : 'items'}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.onSurfaceVariant,
                ),
              ),
            ],
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
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.m),
      child: Material(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        elevation: 1,
        child: InkWell(
          onTap: () {
            _showItemDetails(context, item);
          },
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.m),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Timeline connector
                Container(
                  width: 2,
                  margin: const EdgeInsets.only(top: 8, bottom: 8),
                  decoration: BoxDecoration(
                    color: _getTypeColor(context, item.type),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
                const SizedBox(width: AppSpacing.m),
                
                // Icon based on type
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _getTypeColor(context, item.type).withAlpha(26),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      width: 2,
                      color: _getTypeColor(context, item.type),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      item.type.icon,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.m),
                
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title and time
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              item.title,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppTheme.onSurfaceColor,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.s),
                          Text(
                            DateFormat('HH:mm').format(item.date),
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: AppTheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      
                      // Description
                      if (item.description.isNotEmpty)
                        Text(
                          item.description,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.onSurfaceVariant,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      
                      // Status and type
                      const SizedBox(height: AppSpacing.s),
                      Row(
                        children: [
                          // Status badge
                          if (item.status.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.s,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(context, item.status),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _getStatusIcon(item.status),
                                    size: 12,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    item.status,
                                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const Spacer(),
                          
                          // Type badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.s,
                              vertical: 4,
                            ),
decoration: BoxDecoration(
                                color: _getTypeColor(context, item.type).withAlpha(26),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                width: 1,
                                color: _getTypeColor(context, item.type),
                              ),
                            ),
                            child: Text(
                              item.type.displayName,
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: _getTypeColor(context, item.type),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getTypeColor(BuildContext context, TimelineItemType type) {
    switch (type) {
      case TimelineItemType.medicine:
        return const Color(0xFF3B82F6); // Blue
      case TimelineItemType.prescription:
        return const Color(0xFF10B981); // Green
      case TimelineItemType.followUp:
        return const Color(0xFFF59E0B); // Amber
      case TimelineItemType.reminderLog:
        return const Color(0xFF8B5CF6); // Purple
    }
  }

  Color _getStatusColor(BuildContext context, String status) {
    final lowerStatus = status.toLowerCase();
    
    if (lowerStatus.contains('taken') || lowerStatus.contains('completed') || lowerStatus.contains('success')) {
      return const Color(0xFF10B981); // Success green
    } else if (lowerStatus.contains('pending') || lowerStatus.contains('scheduled')) {
      return const Color(0xFF3B82F6); // Info blue
    } else if (lowerStatus.contains('skipped') || lowerStatus.contains('cancelled') || lowerStatus.contains('missed')) {
      return const Color(0xFFEF4444); // Error red
    } else if (lowerStatus.contains('rescheduled') || lowerStatus.contains('snoozed')) {
      return const Color(0xFFF59E0B); // Warning amber
    } else {
      return AppTheme.neutralColor;
    }
  }

  IconData _getStatusIcon(String status) {
    final lowerStatus = status.toLowerCase();
    
    if (lowerStatus.contains('taken') || lowerStatus.contains('completed') || lowerStatus.contains('success')) {
      return Icons.check_circle;
    } else if (lowerStatus.contains('pending') || lowerStatus.contains('scheduled')) {
      return Icons.schedule;
    } else if (lowerStatus.contains('skipped') || lowerStatus.contains('cancelled') || lowerStatus.contains('missed')) {
      return Icons.cancel;
    } else if (lowerStatus.contains('rescheduled') || lowerStatus.contains('snoozed')) {
      return Icons.update;
    } else {
      return Icons.info;
    }
  }

  void _showItemDetails(BuildContext context, TimelineItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.l),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _getTypeColor(context, item.type).withAlpha(26),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        width: 2,
                        color: _getTypeColor(context, item.type),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        item.type.icon,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.m),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: AppTheme.onSurfaceColor,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('EEEE, MMMM d, y • HH:mm').format(item.date),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.l),
              
              // Description
              if (item.description.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Description',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.onSurfaceColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s),
                    Text(
                      item.description,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.l),
                  ],
                ),
              
              // Status and Type
              Row(
                children: [
                  // Status
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Status',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppTheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.m,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(context, item.status),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getStatusIcon(item.status),
                              size: 14,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              item.status,
                              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: AppSpacing.l),
                  
                  // Type
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Type',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppTheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.m,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getTypeColor(context, item.type).withAlpha(26),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            width: 1,
                            color: _getTypeColor(context, item.type),
                          ),
                        ),
                        child: Text(
                          item.type.displayName,
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: _getTypeColor(context, item.type),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.l),
              
              // Metadata
              if (item.metadata != null && item.metadata!.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Details',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.onSurfaceColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s),
for (final entry in item.metadata!.entries)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              '${entry.key}:',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              entry.value.toString(),
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              
              const SizedBox(height: AppSpacing.xxl),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: AppTheme.primaryButtonStyle,
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        );
      },
    );
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

void _showExportOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.l),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Export Timeline',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppTheme.onSurfaceColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.s),
              Text(
                'Choose a format to export your timeline data',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.l),
              
              // Export Options
              Column(
                children: [
                  ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withAlpha(26),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.table_chart,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    title: Text(
                      'CSV Format',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.onSurfaceColor,
                      ),
                    ),
                    subtitle: Text(
                      'Spreadsheet-friendly format',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.pop(context);
                      _exportAsCsv();
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.green.withAlpha(26),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.code,
                        color: Colors.green,
                      ),
                    ),
                    title: Text(
                      'JSON Format',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.onSurfaceColor,
                      ),
                    ),
                    subtitle: Text(
                      'Developer-friendly format',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.pop(context);
                      _exportAsJson();
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.orange.withAlpha(26),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.print,
                        color: Colors.orange,
                      ),
                    ),
                    title: Text(
                      'Print Summary',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.onSurfaceColor,
                      ),
                    ),
                    subtitle: Text(
                      'Printable report format',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.pop(context);
                      _showPrintPreview(context);
                    },
                  ),
                ],
              ),
              
              const SizedBox(height: AppSpacing.l),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.onSurfaceVariant,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  

Future<void> _exportAsCsv() async {
    try {
      final timelineRepository = ref.read(timelineRepositoryProvider);
      final csvData = await timelineRepository.exportTimelineAsCsv();
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'CSV export ready (${csvData.length} bytes)',
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Export failed: $e'),
              ),
            ],
          ),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
);
    }
  }

  Future<void> _exportAsJson() async {
    try {
      final timelineRepository = ref.read(timelineRepositoryProvider);
      final jsonData = await timelineRepository.exportTimelineAsJson();
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'JSON export ready (${jsonData.length} bytes)',
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Export failed: $e'),
              ),
            ],
          ),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  void _showPrintPreview(BuildContext context) {
    final timelineState = ref.read(timelineListProvider);
    final stats = _calculateStatistics(timelineState.items);
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceColor,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              const Icon(Icons.print),
              const SizedBox(width: AppSpacing.s),
              Text(
                'Print Preview',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppTheme.onSurfaceColor,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Timeline Summary Report',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.onSurfaceColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.s),
                Text(
                  'Generated on ${DateFormat('MMMM d, y • HH:mm').format(DateTime.now())}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
                const Divider(height: AppSpacing.l),
                
                // Statistics
                Text(
                  'Statistics',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.onSurfaceColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.s),
                Wrap(
                  spacing: AppSpacing.s,
                  runSpacing: AppSpacing.s,
                  children: [
                    _buildPrintStatItem('Total Items', stats['total'] ?? 0),
                    _buildPrintStatItem('Medicines', stats['medicines'] ?? 0),
                    _buildPrintStatItem('Prescriptions', stats['prescriptions'] ?? 0),
                    _buildPrintStatItem('Follow-ups', stats['followUps'] ?? 0),
                  ],
                ),
                const Divider(height: AppSpacing.l),
                
                // Recent Items
                Text(
                  'Recent Timeline Items',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.onSurfaceColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.s),
                if (timelineState.items.isEmpty)
                  Text(
                    'No timeline items to display',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.onSurfaceVariant,
                    ),
                  )
                else
                  for (final item in timelineState.items.take(5))
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.s),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(top: 6),
                            decoration: BoxDecoration(
                              color: _getTypeColor(context, item.type),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.s),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  '${DateFormat('MMM d, y').format(item.date)} • ${item.type.displayName}',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                
                const SizedBox(height: AppSpacing.l),
                Text(
                  'Note: This is a preview. In a real app, this would generate a printable document.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Print functionality would be implemented here'),
                  ),
                );
              },
              style: AppTheme.primaryButtonStyle,
              child: const Text('Print'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPrintStatItem(String label, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.m,
        vertical: AppSpacing.s,
      ),
      decoration: BoxDecoration(
        color: AppTheme.secondaryColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(width: 1, color: AppTheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            count.toString(),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppTheme.primaryColor,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.neutralColor,
            ),
          ),
        ],
      ),
    );
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