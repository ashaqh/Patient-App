import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/themes/app_theme.dart';
import '../../core/constants/spacing_constants.dart';
import '../../core/widgets/elderly_friendly_button.dart';
import '../providers/vital_sign_provider.dart';
import '../../domain/entities/vital_sign.dart';
import 'add_vital_sign_screen.dart';

class VitalSignListScreen extends ConsumerStatefulWidget {
  const VitalSignListScreen({super.key});

  @override
  ConsumerState<VitalSignListScreen> createState() => _VitalSignListScreenState();
}

class _VitalSignListScreenState extends ConsumerState<VitalSignListScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Refresh vital signs when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(vitalSignListProvider.notifier).refresh();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildFilterChips() {
    final currentFilter = ref.watch(vitalSignListProvider).filter;
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: VitalSignFilter.values.map((filter) {
          final isSelected = currentFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(_getFilterLabel(filter)),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  ref.read(vitalSignListProvider.notifier).setFilter(filter);
                }
              },
              backgroundColor: isSelected 
                  ? AppTheme.primaryColor.withOpacity(0.1)
                  : null,
              selectedColor: AppTheme.primaryColor,
              labelStyle: TextStyle(
                color: isSelected ? AppTheme.onPrimaryColor : null,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _getFilterLabel(VitalSignFilter filter) {
    switch (filter) {
      case VitalSignFilter.all:
        return 'All';
      case VitalSignFilter.bloodPressure:
        return 'Blood Pressure';
      case VitalSignFilter.bloodSugar:
        return 'Blood Sugar';
      case VitalSignFilter.weight:
        return 'Weight';
      case VitalSignFilter.temperature:
        return 'Temperature';
      case VitalSignFilter.oxygen:
        return 'Oxygen';
      case VitalSignFilter.abnormal:
        return 'Abnormal';
    }
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Search vital signs...',
        prefixIcon: const Icon(Icons.search),
        border: const OutlineInputBorder(),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  ref.read(vitalSignListProvider.notifier).setSearchQuery('');
                },
              )
            : null,
      ),
      onChanged: (value) {
        ref.read(vitalSignListProvider.notifier).setSearchQuery(value);
      },
    );
  }

  Widget _buildVitalSignCard(VitalSign vitalSign) {
    final statusColor = _getStatusColor(vitalSign.statusColor);
    
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.s),
      child: ListTile(
        contentPadding: const EdgeInsets.all(AppSpacing.m),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSmall),
          ),
          child: Center(
            child: Text(
              vitalSign.type.icon ?? '📊',
              style: const TextStyle(fontSize: 24),
            ),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  vitalSign.type.displayName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.m,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor, width: 1),
                  ),
                  child: Text(
                    vitalSign.isWithinTargetRange ? 'Normal' : 'Abnormal',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              vitalSign.displayValue,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppTheme.onSurfaceColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              DateFormat('MMM dd, yyyy - hh:mm a').format(vitalSign.readingTime),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.onSurfaceVariant,
              ),
            ),
            if (vitalSign.mealMarker != null) ...[
              const SizedBox(height: 4),
              Text(
                'Meal: ${vitalSign.mealMarker!.displayName}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.onSurfaceVariant,
                ),
              ),
            ],
            if (vitalSign.context != null && vitalSign.context!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Context: ${vitalSign.context!}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.onSurfaceVariant,
                ),
              ),
            ],
            if (vitalSign.deviceSource != null) ...[
              const SizedBox(height: 4),
              Text(
                'Source: ${vitalSign.deviceSource!}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 20),
                  SizedBox(width: 8),
                  Text('Edit'),
                ],
              ),
            ),
            const PopupMenuItem(
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
          onSelected: (value) {
            if (value == 'edit') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddVitalSignScreen(vitalSign: vitalSign),
                ),
              );
            } else if (value == 'delete') {
              _showDeleteDialog(vitalSign);
            }
          },
        ),
        onTap: () {
          // Show details dialog
          _showVitalSignDetails(vitalSign);
        },
      ),
    );
  }

  Color _getStatusColor(String colorName) {
    switch (colorName) {
      case 'red':
        return Colors.red;
      case 'orange':
        return Colors.orange;
      case 'yellow':
        return Colors.amber;
      case 'green':
        return Colors.green;
      default:
        return AppTheme.primaryColor;
    }
  }

  void _showDeleteDialog(VitalSign vitalSign) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Vital Sign'),
        content: Text(
          'Are you sure you want to delete this ${vitalSign.type.displayName.toLowerCase()} reading of ${vitalSign.displayValue}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(vitalSignListProvider.notifier).deleteVitalSign(vitalSign.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vital sign deleted successfully')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to delete vital sign: $e'),
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                );
              }
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showVitalSignDetails(VitalSign vitalSign) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Text(vitalSign.type.icon ?? '📊'),
            const SizedBox(width: 8),
            Text(vitalSign.type.displayName),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Text(
                  vitalSign.displayValue,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: _getStatusColor(vitalSign.statusColor),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildDetailRow('Reading Time:', 
                DateFormat('MMM dd, yyyy - hh:mm a').format(vitalSign.readingTime)),
              
              if (vitalSign.mealMarker != null)
                _buildDetailRow('Meal Context:', vitalSign.mealMarker!.displayName),
              
              if (vitalSign.context != null && vitalSign.context!.isNotEmpty)
                _buildDetailRow('Context:', vitalSign.context!),
              
              if (vitalSign.deviceSource != null)
                _buildDetailRow('Device Source:', vitalSign.deviceSource!),
              
              _buildDetailRow('Entry Type:', 
                vitalSign.isManualEntry ? 'Manual Entry' : 'Device Sync'),
              
              _buildDetailRow('Status:', 
                vitalSign.isWithinTargetRange ? 'Within normal range' : 'Outside normal range'),
              
              if (vitalSign.notes != null && vitalSign.notes!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Notes:',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  vitalSign.notes!,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddVitalSignScreen(vitalSign: vitalSign),
                ),
              );
            },
            child: const Text('Edit'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.monitor_heart_outlined,
            size: 64,
            color: AppTheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No vital signs recorded yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start tracking your health by adding your first vital sign',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          ElderlyFriendlyButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddVitalSignScreen(),
                ),
              );
            },
            text: 'Add First Vital Sign',
            icon: Icons.add,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildErrorState(String error) {
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
            'Error loading vital signs',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.errorColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.errorColor,
            ),
          ),
          const SizedBox(height: 24),
          ElderlyFriendlyButton(
            onPressed: () {
              ref.read(vitalSignListProvider.notifier).refresh();
            },
            text: 'Try Again',
            icon: Icons.refresh,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(vitalSignListProvider);
    final vitalSigns = ref.watch(filteredVitalSignsProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vital Signs'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: AppTheme.onPrimaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(vitalSignListProvider.notifier).refresh();
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: state.isLoading
          ? _buildLoadingState()
          : state.error != null
              ? _buildErrorState(state.error!)
              : Column(
                  children: [
                    // Search and Filter Section
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.m),
                      child: Column(
                        children: [
                          _buildSearchField(),
                          const SizedBox(height: 12),
                          _buildFilterChips(),
                        ],
                      ),
                    ),
                    
                    // Statistics Summary
                    if (vitalSigns.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.m,
                          vertical: AppSpacing.s,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${vitalSigns.length} ${vitalSigns.length == 1 ? 'entry' : 'entries'}',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              'Sorted by: Newest first',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    
                    // Vital Signs List
                    Expanded(
                      child: vitalSigns.isEmpty
                          ? _buildEmptyState()
                          : RefreshIndicator(
                              onRefresh: () async {
                                await ref.read(vitalSignListProvider.notifier).refresh();
                              },
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.m,
                                  vertical: AppSpacing.s,
                                ),
                                itemCount: vitalSigns.length,
                                itemBuilder: (context, index) {
                                  return _buildVitalSignCard(vitalSigns[index]);
                                },
                              ),
                            ),
                    ),
                  ],
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddVitalSignScreen(),
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
}
