import 'dart:convert';

import '../../data/datasources/database_helper.dart';
import '../../data/datasources/timeline_data_source.dart';
import '../../domain/entities/timeline_item.dart';
import '../../domain/repositories/timeline_repository.dart';

class TimelineRepositoryImpl implements TimelineRepository {
  final DatabaseHelper _databaseHelper;
  late final TimelineDataSource _dataSource;

  TimelineRepositoryImpl(this._databaseHelper) {
    _dataSource = TimelineDataSource(_databaseHelper);
  }

  @override
  Future<List<TimelineItem>> getTimelineItems({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      return await _dataSource.getTimelineItems(
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      throw Exception('Failed to get timeline items: $e');
    }
  }

  @override
  Future<Map<String, List<TimelineItem>>> getTimelineItemsGroupedByDate({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final items = await getTimelineItems(
        startDate: startDate,
        endDate: endDate,
      );
      
      final groups = <String, List<TimelineItem>>{};
      
      for (final item in items) {
        final dateKey = _getDateKey(item.date);
        if (!groups.containsKey(dateKey)) {
          groups[dateKey] = [];
        }
        groups[dateKey]!.add(item);
      }
      
      // Sort groups by date (newest first)
      final sortedGroups = Map.fromEntries(
        groups.entries.toList()
          ..sort((a, b) => b.key.compareTo(a.key)),
      );
      
      return sortedGroups;
    } catch (e) {
      throw Exception('Failed to group timeline items: $e');
    }
  }

  @override
  Future<Map<String, int>> getTimelineStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final items = await getTimelineItems(
        startDate: startDate,
        endDate: endDate,
      );
      
      final stats = <String, int>{
        'total': items.length,
        'medicines': items.where((item) => item.type == TimelineItemType.medicine).length,
        'prescriptions': items.where((item) => item.type == TimelineItemType.prescription).length,
        'followUps': items.where((item) => item.type == TimelineItemType.followUp).length,
        'reminderLogs': items.where((item) => item.type == TimelineItemType.reminderLog).length,
      };
      
      return stats;
    } catch (e) {
      throw Exception('Failed to get timeline statistics: $e');
    }
  }

  @override
  Future<String> exportTimelineAsCsv({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final items = await getTimelineItems(
        startDate: startDate,
        endDate: endDate,
      );
      
      final csvLines = <String>[];
      
      // Add header
      csvLines.add('Type,Date,Time,Title,Description,Status');
      
      // Add data rows
      for (final item in items) {
        final date = '${item.date.day.toString().padLeft(2, '0')}/${item.date.month.toString().padLeft(2, '0')}/${item.date.year}';
        final time = '${item.date.hour.toString().padLeft(2, '0')}:${item.date.minute.toString().padLeft(2, '0')}';
        
        csvLines.add('${item.type.name},"$date","$time","${_escapeCsvField(item.title)}","${_escapeCsvField(item.description)}","${_escapeCsvField(item.status)}"');
      }
      
      return csvLines.join('\n');
    } catch (e) {
      throw Exception('Failed to export timeline as CSV: $e');
    }
  }

  @override
  Future<String> exportTimelineAsJson({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final items = await getTimelineItems(
        startDate: startDate,
        endDate: endDate,
      );
      
      final jsonData = items.map((item) => item.toJson()).toList();
      
      return jsonEncode({
        'exportDate': DateTime.now().toIso8601String(),
        'startDate': startDate?.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'itemCount': items.length,
        'items': jsonData,
      });
    } catch (e) {
      throw Exception('Failed to export timeline as JSON: $e');
    }
  }

  String _getDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _escapeCsvField(String field) {
    // Escape quotes by doubling them
    final escaped = field.replaceAll('"', '""');
    // Wrap in quotes if contains comma, newline, or quote
    if (escaped.contains(',') || escaped.contains('\n') || escaped.contains('"')) {
      return '"$escaped"';
    }
    return escaped;
  }
}