import 'dart:async';
import 'package:sqflite/sqflite.dart';

import 'database_helper.dart';
import 'database_constants.dart';
import '../../domain/entities/timeline_item.dart';
import '../../domain/entities/medicine.dart';
import '../../domain/entities/prescription.dart';
import '../../domain/entities/follow_up.dart';
import '../../domain/entities/reminder_log.dart';

class TimelineDataSource {
  final DatabaseHelper _databaseHelper;

  TimelineDataSource(this._databaseHelper);

  // Get timeline items with optional date filtering
  Future<List<TimelineItem>> getTimelineItems({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await _databaseHelper.database;
    final items = <TimelineItem>[];

    // Get medicines
    final medicines = await _getMedicinesForTimeline(
      db,
      startDate: startDate,
      endDate: endDate,
    );
    items.addAll(medicines);

    // Get prescriptions
    final prescriptions = await _getPrescriptionsForTimeline(
      db,
      startDate: startDate,
      endDate: endDate,
    );
    items.addAll(prescriptions);

    // Get follow-ups
    final followUps = await _getFollowUpsForTimeline(
      db,
      startDate: startDate,
      endDate: endDate,
    );
    items.addAll(followUps);

    // Get reminder logs
    final reminderLogs = await _getReminderLogsForTimeline(
      db,
      startDate: startDate,
      endDate: endDate,
    );
    items.addAll(reminderLogs);

    // Sort by date (newest first)
    items.sort((a, b) => b.date.compareTo(a.date));

    return items;
  }

  // Get medicines for timeline
  Future<List<TimelineItem>> _getMedicinesForTimeline(
    Database db, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      String whereClause = '1 = 1';
      final whereArgs = <Object?>[];

      if (startDate != null) {
        whereClause += ' AND ${DatabaseConstants.columnCreatedAt} >= ?';
        whereArgs.add(startDate.toIso8601String());
      }

      if (endDate != null) {
        whereClause += ' AND ${DatabaseConstants.columnCreatedAt} <= ?';
        whereArgs.add(endDate.toIso8601String());
      }

      // Order by creation date (newest first)
      final maps = await db.query(
        DatabaseConstants.tableMedicines,
        where: whereClause,
        whereArgs: whereArgs,
        orderBy: '${DatabaseConstants.columnCreatedAt} DESC',
      );

      return maps.map((map) {
        final medicine = Medicine.fromMap(map);
        return TimelineItem.fromMedicine(medicine);
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // Get prescriptions for timeline
  Future<List<TimelineItem>> _getPrescriptionsForTimeline(
    Database db, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      String whereClause = '1 = 1';
      final whereArgs = <Object?>[];

      if (startDate != null) {
        whereClause += ' AND ${DatabaseConstants.columnPrescriptionDate} >= ?';
        whereArgs.add(startDate.toIso8601String());
      }

      if (endDate != null) {
        whereClause += ' AND ${DatabaseConstants.columnPrescriptionDate} <= ?';
        whereArgs.add(endDate.toIso8601String());
      }

      // Order by date (newest first)
      final maps = await db.query(
        DatabaseConstants.tablePrescriptions,
        where: whereClause,
        whereArgs: whereArgs,
        orderBy: '${DatabaseConstants.columnPrescriptionDate} DESC',
      );

      return maps.map((map) {
        final prescription = Prescription.fromMap(map);
        return TimelineItem.fromPrescription(prescription);
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // Get follow-ups for timeline
  Future<List<TimelineItem>> _getFollowUpsForTimeline(
    Database db, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      String whereClause = '1 = 1';
      final whereArgs = <Object?>[];

      if (startDate != null) {
        whereClause += ' AND ${DatabaseConstants.columnFollowUpDate} >= ?';
        whereArgs.add(startDate.toIso8601String());
      }

      if (endDate != null) {
        whereClause += ' AND ${DatabaseConstants.columnFollowUpDate} <= ?';
        whereArgs.add(endDate.toIso8601String());
      }

      // Order by date (newest first)
      final maps = await db.query(
        DatabaseConstants.tableFollowUps,
        where: whereClause,
        whereArgs: whereArgs,
        orderBy: '${DatabaseConstants.columnFollowUpDate} DESC',
      );

      return maps.map((map) {
        final followUp = FollowUp.fromMap(map);
        return TimelineItem.fromFollowUp(followUp);
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // Get reminder logs for timeline
  Future<List<TimelineItem>> _getReminderLogsForTimeline(
    Database db, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      String whereClause = '1 = 1';
      final whereArgs = <Object?>[];

      if (startDate != null) {
        whereClause += ' AND ${DatabaseConstants.columnReminderScheduledTime} >= ?';
        whereArgs.add(startDate.toIso8601String());
      }

      if (endDate != null) {
        whereClause += ' AND ${DatabaseConstants.columnReminderScheduledTime} <= ?';
        whereArgs.add(endDate.toIso8601String());
      }

      // Order by scheduled time (newest first)
      final maps = await db.query(
        DatabaseConstants.tableReminderLogs,
        where: whereClause,
        whereArgs: whereArgs,
        orderBy: '${DatabaseConstants.columnReminderScheduledTime} DESC',
      );

      return maps.map((map) {
        final reminderLog = ReminderLog.fromMap(map);
        return TimelineItem.fromReminderLog(reminderLog);
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // Get timeline items count
  Future<int> getTimelineItemsCount({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final items = await getTimelineItems(
      startDate: startDate,
      endDate: endDate,
    );
    return items.length;
  }

  // Get timeline items by type
  Future<List<TimelineItem>> getTimelineItemsByType(
    TimelineItemType type, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final allItems = await getTimelineItems(
      startDate: startDate,
      endDate: endDate,
    );
    
    return allItems.where((item) => item.type == type).toList();
  }

  // Search timeline items
  Future<List<TimelineItem>> searchTimelineItems(
    String query, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final allItems = await getTimelineItems(
      startDate: startDate,
      endDate: endDate,
    );
    
    final lowerQuery = query.toLowerCase();
    
    return allItems.where((item) {
      return item.title.toLowerCase().contains(lowerQuery) ||
          item.description.toLowerCase().contains(lowerQuery) ||
          item.status.toLowerCase().contains(lowerQuery);
    }).toList();
  }
}
