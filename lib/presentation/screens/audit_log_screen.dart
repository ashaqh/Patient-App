import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/audit_log.dart';
import '../../core/services/audit_logging_service.dart';
import '../providers/audit_log_provider.dart';
import '../widgets/common/app_scaffold.dart';
import '../widgets/common/loading_indicator.dart';
import '../widgets/common/empty_state.dart';
import '../widgets/common/error_state.dart';
import 'audit_log_reporting_screen.dart';

class AuditLogScreen extends ConsumerStatefulWidget {
  const AuditLogScreen({super.key});

  @override
  ConsumerState<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends ConsumerState<AuditLogScreen> {
  final _searchController = TextEditingController();
  AuditLogResourceType? _selectedResourceType;
  AuditLogAction? _selectedAction;
  AuditLogSeverity? _selectedSeverity;
  DateTimeRange? _selectedDateRange;
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await ref.read(auditLogProvider.notifier).loadAuditLogs();
  }

  Future<void> _refreshData() async {
    await ref.read(auditLogProvider.notifier).refreshAuditLogs(
      searchQuery: _searchController.text,
      resourceType: _selectedResourceType,
      action: _selectedAction,
      severity: _selectedSeverity,
      startDate: _selectedDateRange?.start,
      endDate: _selectedDateRange?.end,
    );
  }

  void _clearFilters() {
    _searchController.clear();
    _selectedResourceType = null;
    _selectedAction = null;
    _selectedSeverity = null;
    _selectedDateRange = null;
    _refreshData();
  }

  Future<void> _showDateRangePicker() async {
    final now = DateTime.now();
    final initialDateRange = _selectedDateRange ??
        DateTimeRange(
          start: now.subtract(const Duration(days: 7)),
          end: now,
        );

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
    if (range == null) return 'Select Date Range';
    final format = DateFormat('MMM dd, yyyy');
    return '${format.format(range.start)} - ${format.format(range.end)}';
  }

  @override
  Widget build(BuildContext context) {
    final auditLogState = ref.watch(auditLogProvider);

    return AppScaffold(
      title: 'Audit Logs',
      actions: [
        IconButton(
          icon: const Icon(Icons.analytics),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AuditLogReportingScreen(),
              ),
            );
          },
          tooltip: 'View Analytics',
        ),
        IconButton(
          icon: Icon(_showFilters ? Icons.filter_list_off : Icons.filter_list),
          onPressed: () {
            setState(() {
              _showFilters = !_showFilters;
            });
          },
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _refreshData,
        ),
      ],
      body: Column(
        children: [
          if (_showFilters) _buildFilters(),
          Expanded(
            child: _buildAuditLogList(auditLogState),
          ),
          if (auditLogState is AuditLogData) _buildStatistics(auditLogState),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.filter_alt, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Filters',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const Spacer(),
                TextButton(
                  onPressed: _clearFilters,
                  child: const Text('Clear All'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search logs...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => _refreshData(),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildResourceTypeFilter(),
                _buildActionFilter(),
                _buildSeverityFilter(),
                _buildDateRangeFilter(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResourceTypeFilter() {
    return FilterChip(
      label: Text(_selectedResourceType?.displayName ?? 'Resource Type'),
      selected: _selectedResourceType != null,
      onSelected: (selected) {
        if (!selected) {
          setState(() {
            _selectedResourceType = null;
          });
          _refreshData();
        }
      },
      deleteIcon: const Icon(Icons.close, size: 16),
      onDeleted: _selectedResourceType != null
          ? () {
              setState(() {
                _selectedResourceType = null;
              });
              _refreshData();
            }
          : null,
    );
  }

  Widget _buildActionFilter() {
    return FilterChip(
      label: Text(_selectedAction?.displayName ?? 'Action'),
      selected: _selectedAction != null,
      onSelected: (selected) {
        if (!selected) {
          setState(() {
            _selectedAction = null;
          });
          _refreshData();
        }
      },
      deleteIcon: const Icon(Icons.close, size: 16),
      onDeleted: _selectedAction != null
          ? () {
              setState(() {
                _selectedAction = null;
              });
              _refreshData();
            }
          : null,
    );
  }

  Widget _buildSeverityFilter() {
    return FilterChip(
      label: Text(_selectedSeverity?.displayName ?? 'Severity'),
      selected: _selectedSeverity != null,
      onSelected: (selected) {
        if (!selected) {
          setState(() {
            _selectedSeverity = null;
          });
          _refreshData();
        }
      },
      deleteIcon: const Icon(Icons.close, size: 16),
      onDeleted: _selectedSeverity != null
          ? () {
              setState(() {
                _selectedSeverity = null;
              });
              _refreshData();
            }
          : null,
    );
  }

  Widget _buildDateRangeFilter() {
    return FilterChip(
      label: Text(_formatDateRange(_selectedDateRange)),
      selected: _selectedDateRange != null,
      onSelected: (selected) {
        if (selected) {
          _showDateRangePicker();
        } else {
          setState(() {
            _selectedDateRange = null;
          });
          _refreshData();
        }
      },
      deleteIcon: const Icon(Icons.close, size: 16),
      onDeleted: _selectedDateRange != null
          ? () {
              setState(() {
                _selectedDateRange = null;
              });
              _refreshData();
            }
          : null,
    );
  }

  Widget _buildAuditLogList(AuditLogState state) {
    return switch (state) {
      AuditLogLoading() => const Center(child: LoadingIndicator()),
      AuditLogError(:final error) => Center(
          child: ErrorState(
            error: error,
            onRetry: _refreshData,
          ),
        ),
      AuditLogEmpty() => Center(
          child: EmptyState(
            icon: Icons.assignment,
            message: 'No audit logs found',
            actionText: 'Refresh',
            onAction: _refreshData,
          ),
        ),
      AuditLogData(:final logs) => RefreshIndicator(
          onRefresh: _refreshData,
          child: ListView.builder(
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final log = logs[index];
              return _buildAuditLogItem(log);
            },
          ),
        ),
    };
  }

  Widget _buildAuditLogItem(AuditLog log) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: _buildAuditLogIcon(log),
        title: Text(
          log.summary,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: _getSeverityColor(log.severity),
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'User: ${log.userId} (${log.userRole})',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 2),
            Text(
              DateFormat('MMM dd, yyyy HH:mm:ss').format(log.timestamp),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (log.details != null) ...[
              const SizedBox(height: 4),
              Text(
                log.details!,
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (log.errorMessage != null) ...[
              const SizedBox(height: 4),
              Text(
                'Error: ${log.errorMessage}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
        trailing: Icon(
          log.success ? Icons.check_circle : Icons.error,
          color: log.success
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.error,
        ),
        onTap: () => _showAuditLogDetails(log),
      ),
    );
  }

  Widget _buildAuditLogIcon(AuditLog log) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: _getSeverityColor(log.severity).withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        _getAuditLogIcon(log.action),
        color: _getSeverityColor(log.severity),
        size: 20,
      ),
    );
  }

  IconData _getAuditLogIcon(AuditLogAction action) {
    return switch (action) {
      AuditLogAction.create => Icons.add_circle,
      AuditLogAction.read => Icons.visibility,
      AuditLogAction.update => Icons.edit,
      AuditLogAction.delete => Icons.delete,
      AuditLogAction.export => Icons.download,
      AuditLogAction.backup => Icons.backup,
      AuditLogAction.restore => Icons.restore,
      AuditLogAction.login => Icons.login,
      AuditLogAction.logout => Icons.logout,
      AuditLogAction.accessDenied => Icons.block,
    };
  }

  Color _getSeverityColor(AuditLogSeverity severity) {
    return switch (severity) {
      AuditLogSeverity.info => Theme.of(context).colorScheme.primary,
      AuditLogSeverity.warning => Theme.of(context).colorScheme.secondary,
      AuditLogSeverity.error => Theme.of(context).colorScheme.error,
      AuditLogSeverity.security => Colors.red,
    };
  }

  Widget _buildStatistics(AuditLogData state) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            icon: Icons.list_alt,
            label: 'Total',
            value: state.totalCount.toString(),
          ),
          _buildStatItem(
            icon: Icons.check_circle,
            label: 'Success',
            value: state.successCount.toString(),
            color: Colors.green,
          ),
          _buildStatItem(
            icon: Icons.error,
            label: 'Failed',
            value: state.failureCount.toString(),
            color: Colors.red,
          ),
          _buildStatItem(
            icon: Icons.security,
            label: 'Security',
            value: state.securityCount.toString(),
            color: Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    Color? color,
  }) {
    return Column(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  void _showAuditLogDetails(AuditLog log) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return AuditLogDetailsSheet(log: log);
      },
    );
  }
}

class AuditLogDetailsSheet extends StatelessWidget {
  final AuditLog log;

  const AuditLogDetailsSheet({super.key, required this.log});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.background,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline),
                    const SizedBox(width: 8),
                    Text(
                      'Audit Log Details',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildDetailItem('Action', log.action.displayName),
                    _buildDetailItem('Resource Type', log.resourceType.displayName),
                    if (log.resourceId != null)
                      _buildDetailItem('Resource ID', log.resourceId!),
                    _buildDetailItem('User ID', log.userId),
                    _buildDetailItem('User Role', log.userRole),
                    _buildDetailItem(
                      'Timestamp',
                      DateFormat('yyyy-MM-dd HH:mm:ss').format(log.timestamp),
                    ),
                    _buildDetailItem('Success', log.success ? 'Yes' : 'No'),
                    _buildDetailItem('Severity', log.severity.displayName),
                    if (log.ipAddress != null)
                      _buildDetailItem('IP Address', log.ipAddress!),
                    if (log.deviceName != null)
                      _buildDetailItem('Device', log.deviceName!),
                    if (log.location != null)
                      _buildDetailItem('Location', log.location!),
                    _buildDetailItem('Session ID', log.sessionId),
                    if (log.details != null)
                      _buildDetailItem('Details', log.details!),
                    if (log.errorMessage != null)
                      _buildDetailItem('Error Message', log.errorMessage!),
                    if (log.beforeState != null && log.beforeState!.isNotEmpty)
                      _buildStateDetails('Before State', log.beforeState!),
                    if (log.afterState != null && log.afterState!.isNotEmpty)
                      _buildStateDetails('After State', log.afterState!),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Theme.of(context).dividerColor),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          // TODO: Implement export/flag functionality
                        },
                        child: const Text('Flag for Review'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 14),
          ),
          const Divider(height: 16),
        ],
      ),
    );
  }

  Widget _buildStateDetails(String label, Map<String, dynamic> state) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: state.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    '${entry.key}: ${entry.value ?? "null"}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const Divider(height: 16),
        ],
      ),
    );
  }
}