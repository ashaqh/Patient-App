import 'dart:async';
// Temporarily commenting out health package due to compatibility issues
// import 'package:health/health.dart';
import '../utils/error_utils.dart';

/// Health data types supported by the app
enum AppHealthDataType {
  bloodPressure, // Systolic and diastolic
  bloodGlucose,  // Blood sugar
  weight,        // Body weight
  bodyTemperature, // Body temperature
  oxygenSaturation, // SpO2
}

// Stub HealthDataType enum since health package is temporarily disabled
enum HealthDataType {
  BLOOD_PRESSURE,
  BLOOD_GLUCOSE,
  WEIGHT,
  BODY_TEMPERATURE,
  OXYGEN_SATURATION,
}

// Stub HealthDataPoint class
class HealthDataPoint {
  final dynamic value;
  final String unitString;
  final DateTime dateFrom;
  final DateTime dateTo;
  final HealthDataType type;
  final String sourceId;
  final String sourceName;
  
  const HealthDataPoint({
    required this.value,
    required this.unitString,
    required this.dateFrom,
    required this.dateTo,
    required this.type,
    required this.sourceId,
    required this.sourceName,
  });
}

// Stub HealthFactory class
class HealthFactory {
  final bool useHealthConnectIfAvailable;
  
  const HealthFactory({this.useHealthConnectIfAvailable = true});
  
  
  
  Future<List<HealthDataPoint>> getHealthDataFromTypes(
    DateTime startDate,
    DateTime endDate,
    List<HealthDataType> types, {
    int? limit,
  }) async {
    return [];
  }
  
  Future<Map<HealthDataType, List<HealthDataPoint>>> fetch(
    List<HealthDataType> types, {
    DateTime? startDate,
    DateTime? endDate,
    int? limitPerType,
  }) async {
    return {};
  }
  
  // Stub methods for compatibility
  Future<bool> isHealthDataAvailable() async {
    return false;
  }
  
  Future<List<bool>> requestAuthorization(
    List<HealthDataType> types, {
    bool? readPermissions,
    bool? writePermissions,
  }) async {
    return List.filled(types.length, false);
  }
  
  Future<bool> hasPermissions(List<HealthDataType> types) async {
    return false;
  }
}

/// Health service for integrating with Apple HealthKit and Google Fit
class HealthService {
  static final HealthService _instance = HealthService._internal();
  final HealthFactory _health = HealthFactory(useHealthConnectIfAvailable: true);
  
  // List of data types to request permissions for
  final List<HealthDataType> _dataTypes = [
    HealthDataType.BLOOD_PRESSURE,
    HealthDataType.BLOOD_GLUCOSE,
    HealthDataType.WEIGHT,
    HealthDataType.BODY_TEMPERATURE,
    HealthDataType.OXYGEN_SATURATION,
  ];

  // Health data type mapping
  final Map<AppHealthDataType, String> _typeDisplayNames = {
    AppHealthDataType.bloodPressure: 'Blood Pressure',
    AppHealthDataType.bloodGlucose: 'Blood Sugar',
    AppHealthDataType.weight: 'Weight',
    AppHealthDataType.bodyTemperature: 'Temperature',
    AppHealthDataType.oxygenSaturation: 'Oxygen Saturation',
  };

  // Health data unit mapping
  final Map<AppHealthDataType, String> _typeUnits = {
    AppHealthDataType.bloodPressure: 'mmHg',
    AppHealthDataType.bloodGlucose: 'mg/dL',
    AppHealthDataType.weight: 'kg',
    AppHealthDataType.bodyTemperature: '°C',
    AppHealthDataType.oxygenSaturation: '%',
  };

  factory HealthService() {
    return _instance;
  }

  HealthService._internal();

  /// Check if health data is available on the device
  Future<bool> isHealthDataAvailable() async {
    try {
      return await _health.isHealthDataAvailable();
    } catch (e, stackTrace) {
      ErrorUtils.logError(
        'Failed to check health data availability',
        error: e,
        stackTrace: stackTrace,
        tag: 'HealthService',
      );
      return false;
    }
  }

  /// Request permissions for health data access
  Future<bool> requestPermissions() async {
    try {
      // Request permissions for all data types
      final permissions = await _health.requestAuthorization(
        _dataTypes,
        readPermissions: true,
        writePermissions: false,
      );

      // Check if all permissions are granted
      final allGranted = permissions.every((permission) => permission == true);

      ErrorUtils.logInfo(
        'Health permissions requested: $permissions',
        tag: 'HealthService',
      );

      return allGranted;
    } catch (e, stackTrace) {
      ErrorUtils.logError(
        'Failed to request health permissions',
        error: e,
        stackTrace: stackTrace,
        tag: 'HealthService',
      );
      return false;
    }
  }

  /// Check if app has health data permissions
  Future<bool> hasPermissions() async {
    try {
      final permissions = await _health.hasPermissions(_dataTypes);
      return permissions;
    } catch (e, stackTrace) {
      ErrorUtils.logError(
        'Failed to check health permissions',
        error: e,
        stackTrace: stackTrace,
        tag: 'HealthService',
      );
      return false;
    }
  }

  /// Fetch health data for a specific data type and time range
  Future<List<HealthDataPoint>> fetchHealthData({
    required HealthDataType dataType,
    required DateTime startDate,
    required DateTime endDate,
    int limit = 100,
  }) async {
    try {
      // Convert app data type to health package data type
      final healthDataType = _mapToHealthDataType(dataType);
      if (healthDataType == null) {
        ErrorUtils.logError(
          'Unsupported health data type: $dataType',
          tag: 'HealthService',
        );
        return [];
      }

      // Fetch data points
      final dataPoints = await _health.getHealthDataFromTypes(
        startDate,
        endDate,
        [healthDataType],
        limit: limit,
      );

      ErrorUtils.logInfo(
        'Fetched ${dataPoints.length} health data points for $dataType',
        tag: 'HealthService',
      );

      return dataPoints;
    } catch (e, stackTrace) {
      ErrorUtils.logError(
        'Failed to fetch health data for $dataType',
        error: e,
        stackTrace: stackTrace,
        tag: 'HealthService',
      );
      return [];
    }
  }

  /// Fetch all health data for all supported data types
  Future<Map<HealthDataType, List<HealthDataPoint>>> fetchAllHealthData({
    required DateTime startDate,
    required DateTime endDate,
    int limitPerType = 50,
  }) async {
    try {
      final results = <HealthDataType, List<HealthDataPoint>>{};

      // Fetch data for each data type
      for (final appDataType in HealthDataType.values) {
        final healthDataType = _mapToHealthDataType(appDataType);
        if (healthDataType == null) continue;

        final dataPoints = await _health.getHealthDataFromTypes(
          startDate,
          endDate,
          [healthDataType],
          limit: limitPerType,
        );

        results[appDataType] = dataPoints;

        ErrorUtils.logInfo(
          'Fetched ${dataPoints.length} data points for $appDataType',
          tag: 'HealthService',
        );
      }

      return results;
    } catch (e, stackTrace) {
      ErrorUtils.logError(
        'Failed to fetch all health data',
        error: e,
        stackTrace: stackTrace,
        tag: 'HealthService',
      );
      return {};
    }
  }

  /// Convert app data type to health package data type
  HealthDataType? _mapToHealthDataType(AppHealthDataType appDataType) {
    switch (appDataType) {
      case AppHealthDataType.bloodPressure:
        return HealthDataType.BLOOD_PRESSURE;
      case AppHealthDataType.bloodGlucose:
        return HealthDataType.BLOOD_GLUCOSE;
      case AppHealthDataType.weight:
        return HealthDataType.WEIGHT;
      case AppHealthDataType.bodyTemperature:
        return HealthDataType.BODY_TEMPERATURE;
      case AppHealthDataType.oxygenSaturation:
        return HealthDataType.OXYGEN_SATURATION;
      default:
        return null;
    }
  }

  /// Get display name for health data type
  String getDisplayName(AppHealthDataType dataType) {
    return _typeDisplayNames[dataType] ?? dataType.toString();
  }

  /// Get unit for health data type
  String getUnit(AppHealthDataType dataType) {
    return _typeUnits[dataType] ?? '';
  }

  /// Process and format health data point for app consumption
  Map<String, dynamic>? processHealthDataPoint(HealthDataPoint dataPoint) {
    try {
      return {
        'value': dataPoint.value,
        'unit': dataPoint.unitString,
        'dateFrom': dataPoint.dateFrom,
        'dateTo': dataPoint.dateTo,
        'dataType': dataPoint.type.toString(),
        'sourceId': dataPoint.sourceId,
        'sourceName': dataPoint.sourceName,
        // Stub fields since health package is temporarily disabled
        'device': '',
        'platform': '',
      };
    } catch (e, stackTrace) {
      ErrorUtils.logError(
        'Failed to process health data point',
        error: e,
        stackTrace: stackTrace,
        tag: 'HealthService',
      );
      return null;
    }
  }

  /// Get blood pressure data (combines systolic and diastolic)
  Future<List<Map<String, dynamic>>> fetchBloodPressureData({
    required DateTime startDate,
    required DateTime endDate,
    int limit = 50,
  }) async {
    try {
      // Fetch blood pressure data
      final bloodPressurePoints = await _health.getHealthDataFromTypes(
        startDate,
        endDate,
        [HealthDataType.BLOOD_PRESSURE],
        limit: limit,
      );

      // Process data
      final results = <Map<String, dynamic>>[];

      for (final point in bloodPressurePoints) {
        results.add({
          'value': point
              .value, // Note: This might be a map or special object for blood pressure
          'unit': point.unitString,
          'dateFrom': point.dateFrom,
          'dateTo': point.dateTo,
          'dataType': 'BLOOD_PRESSURE',
          'sourceId': point.sourceId,
          'sourceName': point.sourceName,
          'device': point.device ?? '',
          'platform': point.platform?.toString() ?? '',
        });
      }

      return results;
    } catch (e, stackTrace) {
      ErrorUtils.logError(
        'Failed to fetch blood pressure data',
        error: e,
        stackTrace: stackTrace,
        tag: 'HealthService',
      );
      return [];
    }
  }

  /// Get recent health data summary
  Future<Map<String, dynamic>> getHealthSummary({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final allData = await fetchAllHealthData(
        startDate: startDate,
        endDate: endDate,
        limitPerType: 10,
      );

      final summary = <String, dynamic>{
        'totalDataPoints': 0,
        'dataTypes': <String, dynamic>{},
      };

      for (final entry in allData.entries) {
        final dataType = entry.key;
        final dataPoints = entry.value;

        summary['totalDataPoints'] += dataPoints.length;

        if (dataPoints.isNotEmpty) {
          try {
            // Calculate statistics - handle different value types
            final values = dataPoints.map((p) {
              final value = p.value;
              if (value is num) {
                return value.toDouble();
              } else if (value is String) {
                return double.tryParse(value) ?? 0.0;
              } else {
                return 0.0;
              }
            }).toList();

            final average = values.reduce((a, b) => a + b) / values.length;
            final min = values.reduce((a, b) => a < b ? a : b);
            final max = values.reduce((a, b) => a > b ? a : b);

            // Convert HealthDataType to AppHealthDataType for unit lookup
            final appDataType = _mapToAppHealthDataType(dataType);
            summary['dataTypes'][dataType.toString()] = {
              'count': dataPoints.length,
              'average': average,
              'min': min,
              'max': max,
              'latest': dataPoints.last.dateFrom,
              'unit': appDataType != null ? getUnit(appDataType) : '',
            };
          } catch (e) {
            // Skip statistics calculation if values can't be converted
            final appDataType = _mapToAppHealthDataType(dataType);
            summary['dataTypes'][dataType.toString()] = {
              'count': dataPoints.length,
              'latest': dataPoints.last.dateFrom,
              'unit': appDataType != null ? getUnit(appDataType) : '',
            };
          }
        }
      }

      return summary;
    } catch (e, stackTrace) {
      ErrorUtils.logError(
        'Failed to get health summary',
        error: e,
        stackTrace: stackTrace,
        tag: 'HealthService',
      );
      return {'error': e.toString()};
    }
  }

  /// Clean up resources
  void dispose() {
    // HealthFactory doesn't need explicit disposal
  }
}
