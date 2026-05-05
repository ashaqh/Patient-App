import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/audit_log.dart';
import '../providers/audit_log_provider.dart';
import '../widgets/audit_log_charts.dart';
import '../widgets/common/app_scaffold.dart';
import '../widgets/common/loading_indicator.dart';
import '../widgets/common/error_state.dart';

class AuditLogReportingScreen extends ConsumerStatefulWidget {
  const AuditLogReportingScreen({super.key});

  @override
  ConsumerState<AuditLogReportingScreen> createState() =>
      _AuditLogReportingScreenState();
}

class _AuditLogReportingScreenState
    extends ConsumerState<AuditLogReportingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTimeRange? _selectedDateRange;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadInitialData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load initial data for all tabs
      await ref.read(auditLogProvider.notifier).loadAuditLogs();
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await ref
          .read(auditLogProvider.notifier)
          .refreshAuditLogs(
            startDate: _selectedDateRange?.start,
            endDate: _selectedDateRange?.end,
          );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _showDateRangePicker() async {
    final now = DateTime.now();
    final initialDateRange =
        _selectedDateRange ??
        DateTimeRange(start: now.subtract(const Duration(days: 30)), end: now);

    final pickedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange: initialDateRange,
    );

    if (pickedRange != null) {
      setState(() {
        _selectedDateRange = pickedRange;
      });
      _refreshData();
    }
  }

  String _formatDateRange(DateTimeRange? range) {
    if (range == null) return 'Last 30 Days';
    final format = DateFormat('MMM dd, yyyy');
    return '${format.format(range.start)} - ${format.format(range.end)}';
  }

  Widget _buildDateFilter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          const Icon(Icons.calendar_today, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _formatDateRange(_selectedDateRange),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          TextButton(
            onPressed: _showDateRangePicker,
            child: const Text('Change'),
          ),
          if (_selectedDateRange != null)
            IconButton(
              icon: const Icon(Icons.clear, size: 16),
              onPressed: () {
                setState(() {
                  _selectedDateRange = null;
                });
                _refreshData();
              },
            ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    final auditLogState = ref.watch(auditLogProvider);

    return switch (auditLogState) {
      AuditLogLoading() => const Center(child: LoadingIndicator()),
      AuditLogError(:final error) => Center(
        child: ErrorState(error: error, onRetry: _refreshData),
      ),
      AuditLogEmpty() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.analytics_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No audit data available',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Audit logs will appear here as activity occurs',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _refreshData,
              child: const Text('Refresh'),
            ),
          ],
        ),
      ),
      AuditLogData(
        :final logs,
        :final totalCount,
        :final successCount,
        :final failureCount,
        :final securityCount,
        :final resourceTypeDistribution,
        :final actionDistribution,
      ) =>
        RefreshIndicator(
          onRefresh: _refreshData,
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildSummaryCards(
                totalCount,
                successCount,
                failureCount,
                securityCount,
              ),
              const SizedBox(height: 16),
              AuditLogCharts.buildSuccessRateChart(
                successCount,
                failureCount,
                context,
              ),
              const SizedBox(height: 16),
              AuditLogCharts.buildActionDistributionChart(
                actionDistribution,
                context,
              ),
              const SizedBox(height: 16),
              AuditLogCharts.buildResourceTypeChart(
                resourceTypeDistribution,
                context,
              ),
            ],
          ),
        ),
    };
  }

  Widget _buildTrendsTab() {
    final auditLogState = ref.watch(auditLogProvider);

    return switch (auditLogState) {
      AuditLogData(:final logs) => FutureBuilder<List<Map<String, dynamic>>>(
        future: _getActivityOverTimeData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: LoadingIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: ErrorState(
                error: 'Failed to load trends data',
                onRetry: _refreshData,
              ),
            );
          }

          final activityData = snapshot.data ?? [];

          return RefreshIndicator(
            onRefresh: _refreshData,
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                AuditLogCharts.buildActivityOverTimeChart(
                  activityData,
                  context,
                ),
                const SizedBox(height: 16),
                AuditLogCharts.buildHourlyActivityChart(
                  _getHourlyActivityData(logs),
                  context,
                ),
              ],
            ),
          );
        },
      ),
      _ => const Center(child: LoadingIndicator()),
    };
  }

  Widget _buildUsersTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: ref
          .read(auditLogProvider.notifier)
          .getUserActivitySummary(
            startDate: _selectedDateRange?.start,
            endDate: _selectedDateRange?.end,
            limit: 20,
          ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: LoadingIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: ErrorState(
              error: 'Failed to load user activity data',
              onRetry: _refreshData,
            ),
          );
        }

        final userActivity = snapshot.data ?? [];

        return RefreshIndicator(
          onRefresh: _refreshData,
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              AuditLogCharts.buildUserActivityChart(userActivity, context),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSecurityTab() {
    return FutureBuilder<List<AuditLog>>(
      future: ref
          .read(auditLogProvider.notifier)
          .getSecurityIncidents(
            startDate: _selectedDateRange?.start,
            endDate: _selectedDateRange?.end,
            limit: 50,
          ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: LoadingIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: ErrorState(
              error: 'Failed to load security incidents',
              onRetry: _refreshData,
            ),
          );
        }

        final securityIncidents = snapshot.data ?? [];

        return RefreshIndicator(
          onRefresh: _refreshData,
          child: securityIncidents.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.security, size: 64, color: Colors.green),
                      const SizedBox(height: 16),
                      Text(
                        'No security incidents',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'All security events are within normal parameters',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: securityIncidents.length,
                  itemBuilder: (context, index) {
                    final incident = securityIncidents[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12.0),
                      color: Colors.red.shade50,
                      child: ListTile(
                        leading: Icon(
                          Icons.security,
                          color: Colors.red.shade700,
                        ),
                        title: Text(
                          incident.summary,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              'User: ${incident.userId} (${incident.userRole})',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              DateFormat(
                                'MMM dd, yyyy HH:mm:ss',
                              ).format(incident.timestamp),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            if (incident.details != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                incident.details!,
                                style: Theme.of(context).textTheme.bodySmall,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            if (incident.errorMessage != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Error: ${incident.errorMessage}',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: Colors.red),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                        trailing: const Icon(
                          Icons.warning_amber,
                          color: Colors.orange,
                        ),
                        onTap: () {
                          // TODO: Show incident details
                        },
                      ),
                    );
                  },
                ),
        );
      },
    );
  }

  Widget _buildSummaryCards(
    int totalCount,
    int successCount,
    int failureCount,
    int securityCount,
  ) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.5,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: [
        _buildSummaryCard(
          'Total Events',
          totalCount.toString(),
          Icons.event,
          Theme.of(context).colorScheme.primary,
        ),
        _buildSummaryCard(
          'Success Rate',
          '${totalCount > 0 ? ((successCount / totalCount) * 100).toStringAsFixed(1) : '0.0'}%',
          Icons.check_circle,
          Colors.green,
        ),
        _buildSummaryCard(
          'Failed Events',
          failureCount.toString(),
          Icons.error,
          Colors.red,
        ),
        _buildSummaryCard(
          'Security Events',
          securityCount.toString(),
          Icons.security,
          Colors.orange,
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 12),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _getActivityOverTimeData() async {
    try {
      final logs = await ref
          .read(auditLogProvider.notifier)
          .getAuditLogs(
            startDate: _selectedDateRange?.start,
            endDate: _selectedDateRange?.end,
          );

      // Group by date
      final Map<DateTime, int> activityByDate = {};

      for (final log in logs) {
        final date = DateTime(
          log.timestamp.year,
          log.timestamp.month,
          log.timestamp.day,
        );

        activityByDate[date] = (activityByDate[date] ?? 0) + 1;
      }

      // Convert to list and sort by date
      final result = activityByDate.entries
          .map((entry) => {'date': entry.key, 'count': entry.value})
          .toList();

      result.sort(
        (a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime),
      );

      return result;
    } catch (e) {
      return [];
    }
  }

  Map<int, int> _getHourlyActivityData(List<AuditLog> logs) {
    final Map<int, int> hourlyData = {};

    for (final log in logs) {
      final hour = log.timestamp.hour;
      hourlyData[hour] = (hourlyData[hour] ?? 0) + 1;
    }

    return hourlyData;
  }

  Future<List<AuditLog>> getAuditLogs({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      return await ref
          .read(auditLogProvider.notifier)
          .getAuditLogs(startDate: startDate, endDate: endDate);
    } catch (e) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Audit Analytics',
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _refreshData,
          tooltip: 'Refresh data',
        ),
      ],
      body: Column(
        children: [
          _buildDateFilter(),
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
              Tab(icon: Icon(Icons.trending_up), text: 'Trends'),
              Tab(icon: Icon(Icons.people), text: 'Users'),
              Tab(icon: Icon(Icons.security), text: 'Security'),
            ],
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Theme.of(
              context,
            ).colorScheme.onSurfaceVariant,
            indicatorColor: Theme.of(context).colorScheme.primary,
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildTrendsTab(),
                _buildUsersTab(),
                _buildSecurityTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

