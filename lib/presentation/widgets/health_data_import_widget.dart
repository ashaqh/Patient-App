import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../core/services/health_service.dart';
import '../../core/utils/error_utils.dart';
import '../providers/health_service_provider.dart';
import '../../domain/entities/vital_sign.dart';

/// Widget for importing health data from Apple Health/Google Fit
class HealthDataImportWidget extends ConsumerStatefulWidget {
  final Function(VitalSign)? onVitalSignImported;
  final VitalSignType? filterType;

  const HealthDataImportWidget({
    super.key,
    this.onVitalSignImported,
    this.filterType,
  });

  @override
  ConsumerState<HealthDataImportWidget> createState() =>
      _HealthDataImportWidgetState();
}

class _HealthDataImportWidgetState
    extends ConsumerState<HealthDataImportWidget> {
  bool _isLoading = false;
  bool _showImportOptions = false;
  List<Map<String, dynamic>> _healthDataPoints = [];
  String? _errorMessage;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final healthState = ref.watch(healthServiceStateProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Health integration header
        _buildHealthIntegrationHeader(healthState),

        // Health data import options (if available and permissions granted)
        if (healthState.isAvailable &&
            healthState.hasPermissions &&
            _showImportOptions)
          _buildImportOptions(),

        // Loading indicator
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Center(child: CircularProgressIndicator()),
          ),

        // Error message
        if (_errorMessage != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              _errorMessage!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 14,
              ),
            ),
          ),

        // Imported health data list
        if (_healthDataPoints.isNotEmpty) _buildHealthDataList(),
      ],
    );
  }

  /// Build health integration header
  Widget _buildHealthIntegrationHeader(HealthServiceState healthState) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.health_and_safety,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Health Data Integration',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _showImportOptions ? Icons.expand_less : Icons.expand_more,
                  ),
                  onPressed: () {
                    setState(() {
                      _showImportOptions = !_showImportOptions;
                      if (_showImportOptions) {
                        _clearError();
                      }
                    });
                  },
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Status indicator
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: healthState.isAvailable
                        ? (healthState.hasPermissions
                              ? Colors.green
                              : Colors.orange)
                        : Colors.grey,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    healthState.isAvailable
                        ? (healthState.hasPermissions
                              ? 'Connected to Apple Health/Google Fit'
                              : 'Permissions required for health data access')
                        : 'Health data not available on this device',
                    style: TextStyle(
                      color: healthState.isAvailable
                          ? (healthState.hasPermissions
                                ? Colors.green
                                : Colors.orange)
                          : Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),

            // Action buttons
            if (healthState.isAvailable && !healthState.hasPermissions)
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: ElevatedButton(
                  onPressed: _requestPermissions,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: const Text('Request Health Data Permissions'),
                ),
              ),

            // Import button (if permissions granted)
            if (healthState.isAvailable &&
                healthState.hasPermissions &&
                !_showImportOptions)
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _showImportOptions = true;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.download, size: 20),
                      SizedBox(width: 8),
                      Text('Import from Health Data'),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Build import options
  Widget _buildImportOptions() {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Import Health Data',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 16),

            // Date range selector
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'From: ${DateFormat('MMM d, yyyy').format(_startDate)}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      Slider(
                        value: _startDate
                            .difference(
                              DateTime.now().subtract(const Duration(days: 30)),
                            )
                            .inDays
                            .toDouble(),
                        min: 0,
                        max: 30,
                        divisions: 30,
                        label:
                            '${_startDate.difference(DateTime.now().subtract(const Duration(days: 30))).inDays} days ago',
                        onChanged: (value) {
                          setState(() {
                            _startDate = DateTime.now().subtract(
                              Duration(days: 30 - value.toInt()),
                            );
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Data type selector (if filterType is not specified)
            if (widget.filterType == null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Data Type',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: VitalSignType.values.map((type) {
                      return FilterChip(
                        label: Text(type.displayName),
                        selected: true,
                        onSelected: (_) {},
                      );
                    }).toList(),
                  ),
                ],
              ),

            const SizedBox(height: 16),

            // Import buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _fetchHealthData,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search, size: 20),
                        SizedBox(width: 8),
                        Text('Fetch Health Data'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build health data list
  Widget _buildHealthDataList() {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Available Health Data',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_healthDataPoints.length} items',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Health data list
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _healthDataPoints.length,
                itemBuilder: (context, index) {
                  final dataPoint = _healthDataPoints[index];
                  return _buildHealthDataItem(dataPoint, index);
                },
              ),
            ),

            // Batch import button
            if (_healthDataPoints.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: ElevatedButton(
                  onPressed: _importAllData,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: const Text('Import All Data Points'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Build health data item
  Widget _buildHealthDataItem(Map<String, dynamic> dataPoint, int index) {
    final type = VitalSignType.values.firstWhere(
      (t) => t.displayName == dataPoint['type'],
      orElse: () => VitalSignType.bloodPressure,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: ListTile(
        leading: Icon(
          _getVitalSignIcon(type),
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(
          '${dataPoint['value1']}${type.unit} ${dataPoint['value2'] != null ? '/ ${dataPoint['value2']}${type.unit}' : ''}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(type.displayName),
            Text(
              DateFormat(
                'MMM d, yyyy h:mm a',
              ).format(DateTime.parse(dataPoint['readingTime'])),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            if (dataPoint['deviceSource'] != null)
              Text(
                'Source: ${dataPoint['deviceSource']}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.add_circle, color: Colors.green),
          onPressed: () => _importSingleDataPoint(dataPoint),
        ),
      ),
    );
  }

  /// Get icon for vital sign type
  IconData _getVitalSignIcon(VitalSignType type) {
    switch (type) {
      case VitalSignType.bloodPressure:
        return Icons.favorite;
      case VitalSignType.bloodSugar:
        return Icons.water_drop;
      case VitalSignType.weight:
        return Icons.monitor_weight;
      case VitalSignType.temperature:
        return Icons.thermostat;
      case VitalSignType.oxygen:
        return Icons.air;
    }
  }

  /// Request health data permissions
  Future<void> _requestPermissions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final healthNotifier = ref.read(healthServiceStateProvider.notifier);
    final granted = await healthNotifier.requestPermissions();

    setState(() {
      _isLoading = false;
      if (!granted) {
        _errorMessage =
            'Health data permissions were denied. Please enable them in device settings.';
      }
    });
  }

  /// Fetch health data
  Future<void> _fetchHealthData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _healthDataPoints.clear();
    });

    try {
      final healthService = ref.read(healthServiceProvider);

      // Map app data types to health service data types
      final appDataType = widget.filterType ?? VitalSignType.bloodPressure;
      final healthDataType = _mapToHealthDataType(appDataType);

      if (healthDataType == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Unsupported health data type';
        });
        return;
      }

      // Fetch health data
      final healthDataPoints = await healthService.fetchHealthData(
        dataType: healthDataType,
        startDate: _startDate,
        endDate: _endDate,
        limit: 50,
      );

      // Convert to app format
      final List<Map<String, dynamic>> convertedData = [];

      for (final dataPoint in healthDataPoints) {
        final processed = healthService.processHealthDataPoint(dataPoint);
        if (processed != null) {
          // Convert to app vital sign format
          convertedData.add({
            'type': appDataType.displayName,
            'value1': processed['value'],
            'value2': null,
            'unit': appDataType.unit,
            'readingTime':
                processed['dateFrom']?.toString() ??
                DateTime.now().toIso8601String(),
            'deviceSource': processed['sourceName'] ?? 'Health App',
            'isManualEntry': false,
            'healthData': processed,
          });
        }
      }

      setState(() {
        _isLoading = false;
        _healthDataPoints = convertedData;

        if (convertedData.isEmpty) {
          _errorMessage =
              'No health data found for the selected date range and type.';
        }
      });
    } catch (e, stackTrace) {
      ErrorUtils.logError(
        'Failed to fetch health data',
        error: e,
        stackTrace: stackTrace,
        tag: 'HealthDataImportWidget',
      );

      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to fetch health data: ${e.toString()}';
      });
    }
  }

  /// Map app data type to health service data type
  AppHealthDataType? _mapToHealthDataType(VitalSignType appDataType) {
    switch (appDataType) {
      case VitalSignType.bloodPressure:
        return AppHealthDataType.bloodPressure;
      case VitalSignType.bloodSugar:
        return AppHealthDataType.bloodGlucose;
      case VitalSignType.weight:
        return AppHealthDataType.weight;
      case VitalSignType.temperature:
        return AppHealthDataType.bodyTemperature;
      case VitalSignType.oxygen:
        return AppHealthDataType.oxygenSaturation;
      default:
        return null;
    }
  }

  /// Import single data point
  void _importSingleDataPoint(Map<String, dynamic> dataPoint) {
    try {
      // Create vital sign from health data
      final vitalSign = _createVitalSignFromHealthData(dataPoint);

      if (widget.onVitalSignImported != null) {
        widget.onVitalSignImported!(vitalSign);
      }

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Imported ${vitalSign.type.displayName} data'),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e, stackTrace) {
      ErrorUtils.logError(
        'Failed to import health data point',
        error: e,
        stackTrace: stackTrace,
        tag: 'HealthDataImportWidget',
      );

      setState(() {
        _errorMessage = 'Failed to import data: ${e.toString()}';
      });
    }
  }

  /// Import all data points
  Future<void> _importAllData() async {
    try {
      int importedCount = 0;

      for (final dataPoint in _healthDataPoints) {
        final vitalSign = _createVitalSignFromHealthData(dataPoint);

        if (widget.onVitalSignImported != null) {
          widget.onVitalSignImported!(vitalSign);
          importedCount++;
        }
      }

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Imported $importedCount data points'),
          duration: const Duration(seconds: 3),
        ),
      );

      // Clear imported data list
      setState(() {
        _healthDataPoints.clear();
      });
    } catch (e, stackTrace) {
      ErrorUtils.logError(
        'Failed to import all health data',
        error: e,
        stackTrace: stackTrace,
        tag: 'HealthDataImportWidget',
      );

      setState(() {
        _errorMessage = 'Failed to import data: ${e.toString()}';
      });
    }
  }

  /// Create vital sign from health data
  VitalSign _createVitalSignFromHealthData(Map<String, dynamic> dataPoint) {
    final type = VitalSignType.values.firstWhere(
      (t) => t.displayName == dataPoint['type'],
      orElse: () => VitalSignType.bloodPressure,
    );

    return VitalSign(
      id: Uuid().v4(),
      type: type,
      value1: double.parse(dataPoint['value1'].toString()),
      value2: dataPoint['value2'] != null
          ? double.parse(dataPoint['value2'].toString())
          : null,
      unit: type.unit,
      readingTime: DateTime.parse(dataPoint['readingTime']),
      mealMarker: null, // Health data doesn't include meal markers
      context: 'Imported from Health App',
      notes:
          'Automatically imported from ${dataPoint['deviceSource'] ?? 'health data'}',
      deviceSource: dataPoint['deviceSource'] ?? 'Health App',
      isManualEntry: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Clear error message
  void _clearError() {
    setState(() {
      _errorMessage = null;
    });
  }
}

