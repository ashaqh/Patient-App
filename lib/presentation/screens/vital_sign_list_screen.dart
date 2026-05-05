import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
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

  Widget _buildVitalSignChart({
    required VitalSignType type,
    required List<VitalSign> vitalSigns,
    bool showLegend = true,
    bool isCompact = false,
  }) {
    if (vitalSigns.isEmpty) {
      return _buildEmptyChartState(type);
    }

    final sortedSigns = List<VitalSign>.from(vitalSigns)
      ..sort((a, b) => a.readingTime.compareTo(b.readingTime));

    final spots = <FlSpot>[];
    final systolicSpots = <FlSpot>[];
    final diastolicSpots = <FlSpot>[];

    for (int i = 0; i < sortedSigns.length; i++) {
      final sign = sortedSigns[i];
      spots.add(FlSpot(i.toDouble(), sign.value1));
      
      if (type == VitalSignType.bloodPressure && sign.value2 != null) {
        systolicSpots.add(FlSpot(i.toDouble(), sign.value1));
        diastolicSpots.add(FlSpot(i.toDouble(), sign.value2!));
      }
    }

    final minY = sortedSigns.map((s) => s.value1).reduce((a, b) => a < b ? a : b);
    final maxY = sortedSigns.map((s) => s.value1).reduce((a, b) => a > b ? a : b);
    
    double chartMinY = minY - (maxY - minY) * 0.1;
    double chartMaxY = maxY + (maxY - minY) * 0.1;
    
    if (type == VitalSignType.bloodPressure) {
      final minDiastolic = sortedSigns.map((s) => s.value2 ?? 0).reduce((a, b) => a < b ? a : b);
      final maxDiastolic = sortedSigns.map((s) => s.value2 ?? 0).reduce((a, b) => a > b ? a : b);
      chartMinY = (chartMinY < minDiastolic - 10) ? chartMinY : minDiastolic - 10;
      chartMaxY = (chartMaxY > maxDiastolic + 10) ? chartMaxY : maxDiastolic + 10;
    }

    if (chartMinY < type.minValue) chartMinY = type.minValue;
    if (chartMaxY > type.maxValue) chartMaxY = type.maxValue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isCompact) ...[
          Row(
            children: [
              Text(
                type.icon ?? '📊',
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 8),
              Text(
                type.displayName,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (!isCompact)
                Text(
                  '${sortedSigns.length} ${sortedSigns.length == 1 ? 'reading' : 'readings'}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        if (showLegend && type == VitalSignType.bloodPressure) ...[
          Row(
            children: [
              _buildLegendItem('Systolic', Colors.red),
              const SizedBox(width: 16),
              _buildLegendItem('Diastolic', Colors.blue),
            ],
          ),
          const SizedBox(height: 8),
        ],
        SizedBox(
          height: isCompact ? 120 : 200,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: (chartMaxY - chartMinY) / 4,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: AppTheme.onSurfaceVariant.withOpacity(0.2),
                    strokeWidth: 1,
                  );
                },
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    interval: sortedSigns.length > 7 
                        ? (sortedSigns.length / 5).ceilToDouble() 
                        : 1,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= sortedSigns.length) {
                        return const SizedBox.shrink();
                      }
                      final date = sortedSigns[index].readingTime;
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          DateFormat('MM/dd').format(date),
                          style: const TextStyle(fontSize: 10),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 45,
                    interval: (chartMaxY - chartMinY) / 4,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toInt().toString(),
                        style: const TextStyle(fontSize: 10),
                      );
                    },
                  ),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border(
                  bottom: BorderSide(
                    color: AppTheme.onSurfaceVariant.withOpacity(0.3),
                  ),
                  left: BorderSide(
                    color: AppTheme.onSurfaceVariant.withOpacity(0.3),
                  ),
                ),
              ),
              minX: 0,
              maxX: (sortedSigns.length - 1).toDouble(),
              minY: chartMinY,
              maxY: chartMaxY,
              lineBarsData: [
                if (type == VitalSignType.bloodPressure) ...[
                  LineChartBarData(
                    spots: systolicSpots,
                    isCurved: true,
                    color: Colors.red,
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, bar, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: Colors.red,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.red.withOpacity(0.1),
                    ),
                  ),
                  LineChartBarData(
                    spots: diastolicSpots,
                    isCurved: true,
                    color: Colors.blue,
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, bar, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: Colors.blue,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.blue.withOpacity(0.1),
                    ),
                  ),
                ] else ...[
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: _getChartColor(type),
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, bar, index) {
                        final statusColor = sortedSigns[index].statusColor;
                        return FlDotCirclePainter(
                          radius: 4,
                          color: _getStatusColor(statusColor),
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: _getChartColor(type).withOpacity(0.1),
                    ),
                  ),
                ],
              ],
              lineTouchData: LineTouchData(
                enabled: true,
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      final index = spot.x.toInt();
                      if (index < 0 || index >= sortedSigns.length) {
                        return null;
                      }
                      final sign = sortedSigns[index];
                      String label;
                      if (type == VitalSignType.bloodPressure) {
                        label = '${spot.y.toInt()}/${sign.value2?.toInt() ?? 0}';
                      } else {
                        label = '${spot.y.toStringAsFixed(1)}';
                      }
                      return LineTooltipItem(
                        '${DateFormat('MMM dd, HH:mm').format(sign.readingTime)}\n$label ${type.unit}',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
              extraLinesData: ExtraLinesData(
                horizontalLines: [
                  if (type.targetMin != null && type.targetMax != null) ...[
                    HorizontalLine(
                      y: type.targetMin!,
                      color: Colors.green.withOpacity(0.5),
                      strokeWidth: 1,
                      dashArray: [5, 5],
                      label: HorizontalLineLabel(
                        show: true,
                        alignment: Alignment.topRight,
                        labelResolver: (line) => 'Min: ${type.targetMin!.toInt()}',
                        style: const TextStyle(
                          fontSize: 9,
                          color: Colors.green,
                        ),
                      ),
                    ),
                    HorizontalLine(
                      y: type.targetMax!,
                      color: Colors.green.withOpacity(0.5),
                      strokeWidth: 1,
                      dashArray: [5, 5],
                      label: HorizontalLineLabel(
                        show: true,
                        alignment: Alignment.bottomRight,
                        labelResolver: (line) => 'Max: ${type.targetMax!.toInt()}',
                        style: const TextStyle(
                          fontSize: 9,
                          color: Colors.green,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        if (!isCompact && sortedSigns.isNotEmpty) ...[
          const SizedBox(height: 8),
          _buildLatestReading(sortedSigns.last),
        ],
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildLatestReading(VitalSign sign) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getStatusColor(sign.statusColor).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getStatusColor(sign.statusColor).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Text(
            'Latest: ${sign.displayValue}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Text(
            DateFormat('MMM dd, HH:mm').format(sign.readingTime),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyChartState(VitalSignType type) {
    return Container(
      height: 150,
      decoration: BoxDecoration(
        color: AppTheme.onSurfaceVariant.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.onSurfaceVariant.withOpacity(0.2),
          style: BorderStyle.solid,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              type.icon ?? '📊',
              style: const TextStyle(fontSize: 32),
            ),
            const SizedBox(height: 8),
            Text(
              'No ${type.displayName} data yet',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap + to add your first reading',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getChartColor(VitalSignType type) {
    switch (type) {
      case VitalSignType.bloodPressure:
        return Colors.red;
      case VitalSignType.bloodSugar:
        return Colors.orange;
      case VitalSignType.weight:
        return Colors.purple;
      case VitalSignType.temperature:
        return Colors.amber;
      case VitalSignType.oxygen:
        return Colors.blue;
    }
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
              ).then((_) {
                ref.read(vitalSignListProvider.notifier).refresh();
              });
            } else if (value == 'delete') {
              _showDeleteDialog(vitalSign);
            }
          },
        ),
        onTap: () {
          _showVitalSignDetails(vitalSign);
        },
      ),
    );
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
              ).then((_) {
                ref.read(vitalSignListProvider.notifier).refresh();
              });
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
          const Icon(
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
              ).then((_) {
                ref.read(vitalSignListProvider.notifier).refresh();
              });
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
          const Icon(
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

  Widget _buildGraphView(VitalSignFilter filter, List<VitalSign> vitalSigns) {
    if (filter == VitalSignFilter.all) {
      return _buildAllGraphsView(vitalSigns);
    } else if (filter == VitalSignFilter.abnormal) {
      return _buildAbnormalGraphsView(vitalSigns);
    } else {
      final type = _filterToType(filter);
      if (type == null) return _buildEmptyState();
      
      final filtered = vitalSigns.where((vs) => vs.type == type).toList();
      return _buildSingleTypeGraphView(type, filtered);
    }
  }

  VitalSignType? _filterToType(VitalSignFilter filter) {
    switch (filter) {
      case VitalSignFilter.bloodPressure:
        return VitalSignType.bloodPressure;
      case VitalSignFilter.bloodSugar:
        return VitalSignType.bloodSugar;
      case VitalSignFilter.weight:
        return VitalSignType.weight;
      case VitalSignFilter.temperature:
        return VitalSignType.temperature;
      case VitalSignFilter.oxygen:
        return VitalSignType.oxygen;
      default:
        return null;
    }
  }

  Widget _buildAllGraphsView(List<VitalSign> allVitalSigns) {
    final graphs = <Widget>[];
    
    for (final type in VitalSignType.values) {
      final typeSigns = allVitalSigns.where((vs) => vs.type == type).toList();
      graphs.add(
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.m),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.m),
              child: _buildVitalSignChart(
                type: type,
                vitalSigns: typeSigns,
                showLegend: true,
                isCompact: false,
              ),
            ),
          ),
        ),
      );
    }

    final hasAnyData = allVitalSigns.isNotEmpty;

    return hasAnyData
        ? ListView(
            padding: const EdgeInsets.all(AppSpacing.m),
            children: graphs,
          )
        : _buildEmptyState();
  }

  Widget _buildAbnormalGraphsView(List<VitalSign> abnormalSigns) {
    if (abnormalSigns.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 64,
              color: Colors.green,
            ),
            const SizedBox(height: 16),
            Text(
              'All readings are normal!',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No abnormal vital signs detected',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    final groupedByType = <VitalSignType, List<VitalSign>>{};
    for (final sign in abnormalSigns) {
      groupedByType.putIfAbsent(sign.type, () => []).add(sign);
    }

    final graphs = <Widget>[];
    groupedByType.forEach((type, signs) {
      graphs.add(
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.m),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.m),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(type.icon ?? '📊', style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 8),
                      Text(
                        type.displayName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${signs.length} abnormal',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.red,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildVitalSignChart(
                    type: type,
                    vitalSigns: signs,
                    showLegend: false,
                    isCompact: true,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.m),
      children: graphs,
    );
  }

  Widget _buildSingleTypeGraphView(VitalSignType type, List<VitalSign> vitalSigns) {
    if (vitalSigns.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              type.icon ?? '📊',
              style: const TextStyle(fontSize: 64),
            ),
            const SizedBox(height: 16),
            Text(
              'No ${type.displayName} data yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap + to add your first reading',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.m),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.m),
          child: _buildVitalSignChart(
            type: type,
            vitalSigns: vitalSigns,
            showLegend: type == VitalSignType.bloodPressure,
            isCompact: false,
          ),
        ),
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
                    Expanded(
                      child: _buildGraphView(state.filter, vitalSigns),
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
          ).then((_) {
            ref.read(vitalSignListProvider.notifier).refresh();
          });
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