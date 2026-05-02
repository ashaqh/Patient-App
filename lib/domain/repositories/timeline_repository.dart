import '../entities/timeline_item.dart';

abstract class TimelineRepository {
  // Get all timeline items with optional date filtering
  Future<List<TimelineItem>> getTimelineItems({
    DateTime? startDate,
    DateTime? endDate,
  });

  // Get timeline items grouped by date
  Future<Map<String, List<TimelineItem>>> getTimelineItemsGroupedByDate({
    DateTime? startDate,
    DateTime? endDate,
  });

  // Get timeline statistics
  Future<Map<String, int>> getTimelineStatistics({
    DateTime? startDate,
    DateTime? endDate,
  });

  // Export timeline data as CSV
  Future<String> exportTimelineAsCsv({
    DateTime? startDate,
    DateTime? endDate,
  });

  // Export timeline data as JSON
  Future<String> exportTimelineAsJson({
    DateTime? startDate,
    DateTime? endDate,
  });
}