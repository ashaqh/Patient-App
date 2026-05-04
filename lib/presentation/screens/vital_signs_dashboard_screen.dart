import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../core/themes/app_theme.dart';
import '../../core/constants/spacing_constants.dart';
import '../../core/widgets/elderly_friendly_button.dart';
import '../providers/vital_sign_provider.dart';
import '../../domain/entities/vital_sign.dart';
import 'add_vital_sign_screen.dart';

class VitalSignsDashboardScreen extends ConsumerStatefulWidget {
  const VitalSignsDashboardScreen({super.key});

  @override
  ConsumerState<VitalSignsDashboardScreen> createState() => _VitalSignsDashboardScreenState();
}

class _VitalSignsDashboardScreenState extends ConsumerState<VitalSignsDashboardScreen> {
  VitalSignType _selectedType = VitalSignType.bloodPressure;
  int _selectedTimeRange = 7; // 7 days by default

  final List<int> _timeRanges = [1, 7, 30, 90]; // days

  @override
  void initState() {
    super.initState();
    // Refresh vital signs when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(vitalSignListProvider.notifier).refresh();
    });
  }

  Widget _buildTypeSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: VitalSignType.values.map((type) {
          final isSelected = _selectedType == type;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Row(
                children: [
                  Text(type.icon ?? '📊'),
                  const SizedBox(width: 4),
                  Text(type.displayName),
                ],
              ),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedType = type;
                  });
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

  Widget _buildTimeRangeSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _timeRanges.map((days) {
          final isSelected = _selectedTimeRange == days;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text('$days ${days == 1 ? 'Day' : 'Days'}'),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedTimeRange = days;
                  });
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

  Widget _buildStatisticsCard({
    required String title,
    required String value,
    required IconData icon,
    Color? color,
  }) {
    return Container(
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
          Icon(icon, color: color ?? AppTheme.primaryColor, size: 24),
          const SizedBox(height: AppSpacing.s),
          Text(
            title,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppTheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: color ?? AppTheme.primaryColor,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTrendChart(List<VitalSign> vitalSigns) {
    if (vitalSigns.isEmpty) {
      return Container(
        height: 200,
        padding: const EdgeInsets.all(AppSpacing.l),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMedium),
          border: Border.all(
            width: 1,
            color: AppTheme.outlineVariant,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.show_chart,
                size: 48,
                color: AppTheme.onSurfaceVariant,
              ),
              const SizedBox(height: AppSpacing.m),
              Text(
                'No data available for the selected period',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Sort by date ascending for chart
    vitalSigns.sort((a, b) => a.readingTime.compareTo(b.readingTime));

    // Prepare data for chart
    final spots = vitalSigns.map((vs) {
      return FlSpot(
        vs.readingTime.millisecondsSinceEpoch.toDouble(),
        vs.value1,
      );
    }).toList();

    // Get target range for this vital sign type
    final targetMin = _selectedType.targetMin;
    final targetMax = _selectedType.targetMax;

    return Container(
      height: 250,
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMedium),
        border: Border.all(
          width: 1,
          color: AppTheme.outlineVariant,
        ),
      ),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: true),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                getTitlesWidget: (value, meta) {
                  final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
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
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: AppTheme.outlineVariant),
          ),
          minX: vitalSigns.first.readingTime.millisecondsSinceEpoch.toDouble(),
          maxX: vitalSigns.last.readingTime.millisecondsSinceEpoch.toDouble(),
          minY: _getMinY(vitalSigns),
          maxY: _getMaxY(vitalSigns),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: AppTheme.primaryColor,
              barWidth: 3,
              isStrokeCapRound: true,
              belowBarData: BarAreaData(show: false),
              dotData: const FlDotData(show: true),
            ),
            // Target range area (if available)
            if (targetMin != null && targetMax != null)
              LineChartBarData(
                spots: [
                  FlSpot(vitalSigns.first.readingTime.millisecondsSinceEpoch.toDouble(), targetMin),
                  FlSpot(vitalSigns.last.readingTime.millisecondsSinceEpoch.toDouble(), targetMin),
                ],
                isCurved: false,
                color: Colors.green.withOpacity(0.3),
                barWidth: 0,
                belowBarData: BarAreaData(
                  show: true,
                  color: Colors.green.withOpacity(0.1),
                ),
              ),
            if (targetMin != null && targetMax != null)
              LineChartBarData(
                spots: [
                  FlSpot(vitalSigns.first.readingTime.millisecondsSinceEpoch.toDouble(), targetMax),
                  FlSpot(vitalSigns.last.readingTime.millisecondsSinceEpoch.toDouble(), targetMax),
                ],
                isCurved: false,
                color: Colors.green.withOpacity(0.3),
                barWidth: 0,
                belowBarData: BarAreaData(
                  show: true,
                  color: Colors.green.withOpacity(0.1),
                ),
              ),
          ],
        ),
      ),
    );
  }

  double _getMinY(List<VitalSign> vitalSigns) {
    double min = double.infinity;
    for (final vs in vitalSigns) {
      if (vs.value1 < min) min = vs.value1;
      if (vs.value2 != null && vs.value2! < min) min = vs.value2!;
    }
    // Add some padding
    return min - (min * 0.1);
  }

  double _getMaxY(List<VitalSign> vitalSigns) {
    double max = double.negativeInfinity;
    for (final vs in vitalSigns) {
      if (vs.value1 > max) max = vs.value1;
      if (vs.value2 != null && vs.value2! > max) max = vs.value2!;
    }
    // Add some padding
    return max + (max * 0.1);
  }

  Widget _buildLatestReadings(List<VitalSign> vitalSigns) {
    final latestReadings = ref.watch(latestVitalSignsProvider);
    
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.5,
      mainAxisSpacing: AppSpacing.s,
      crossAxisSpacing: AppSpacing.s,
      children: VitalSignType.values.map((type) {
        final latest = latestReadings[type];
        final isAbnormal = latest != null && !latest.isWithinTargetRange;
        
        return Container(
          padding: const EdgeInsets.all(AppSpacing.m),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMedium),
            border: Border.all(
              width: 1,
              color: isAbnormal ? AppTheme.errorColor : AppTheme.outlineVariant,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                type.icon ?? '📊',
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                type.displayName,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppTheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                latest?.displayValue ?? 'No data',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: latest != null 
                      ? (isAbnormal ? AppTheme.errorColor : AppTheme.primaryColor)
                      : AppTheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              if (latest != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  DateFormat('MM/dd').format(latest.readingTime),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        );
      }).toList(),
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
            'No vital signs data yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start tracking your health metrics to see visualizations',
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
            text: 'Add First Reading',
            icon: Icons.add,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(vitalSignListProvider);
    final vitalSigns = state.getVitalSignsByType(_selectedType);
    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: _selectedTimeRange));
    
    // Filter vital signs by selected time range
    final filteredVitalSigns = vitalSigns
        .where((vs) => vs.readingTime.isAfter(startDate))
        .toList();
    
    // Calculate statistics
    final stats = state.getVitalSignStatistics(_selectedType, _selectedTimeRange);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Dashboard'),
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
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
              ? Center(
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
                        'Error loading data',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppTheme.errorColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        state.error!,
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
                )
              : state.vitalSigns.isEmpty
                  ? _buildEmptyState()
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(AppSpacing.m),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Vital Sign Type Selector
                          Text(
                            'Select Metric',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.s),
                          _buildTypeSelector(),
                          const SizedBox(height: AppSpacing.l),

                          // Time Range Selector
                          Text(
                            'Time Range',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.s),
                          _buildTimeRangeSelector(),
                          const SizedBox(height: AppSpacing.l),

                          // Statistics Cards
                          Text(
                            'Statistics',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
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
                              _buildStatisticsCard(
                                title: 'Average',
                                value: stats['average'] != null 
                                    ? stats['average'].toStringAsFixed(1) 
                                    : 'N/A',
                                icon: Icons.bar_chart,
                              ),
                              _buildStatisticsCard(
                                title: 'Min',
                                value: stats['min'] != null 
                                    ? stats['min'].toStringAsFixed(1) 
                                    : 'N/A',
                                icon: Icons.arrow_downward,
                              ),
                              _buildStatisticsCard(
                                title: 'Max',
                                value: stats['max'] != null 
                                    ? stats['max'].toStringAsFixed(1) 
                                    : 'N/A',
                                icon: Icons.arrow_upward,
                              ),
                              _buildStatisticsCard(
                                title: 'Readings',
                                value: '${stats['count'] ?? 0}',
                                icon: Icons.list,
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.l),

                          // Trend Chart
                          Text(
                            'Trend',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.m),
                          _buildTrendChart(filteredVitalSigns),
                          const SizedBox(height: AppSpacing.l),

                          // Latest Readings for All Types
                          Text(
                            'Latest Readings',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.m),
                          _buildLatestReadings(filteredVitalSigns),
                          const SizedBox(height: AppSpacing.xxl),
                        ],
                      ),
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