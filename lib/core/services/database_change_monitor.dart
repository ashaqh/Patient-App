import 'dart:async';
import '../../data/datasources/database_helper.dart';
import '../../data/datasources/database_constants.dart';

class DatabaseChangeEvent {
  final String id;
  final String tableName;
  final String rowId;
  final String operation;
  final DateTime timestamp;

  DatabaseChangeEvent({
    required this.id,
    required this.tableName,
    required this.rowId,
    required this.operation,
    required this.timestamp,
  });

  factory DatabaseChangeEvent.fromMap(Map<String, dynamic> map) {
    return DatabaseChangeEvent(
      id: map[DatabaseConstants.columnId] as String,
      tableName: map[DatabaseConstants.columnChangeTableName] as String,
      rowId: map[DatabaseConstants.columnChangeRowId] as String,
      operation: map[DatabaseConstants.columnChangeOperation] as String,
      timestamp: DateTime.parse(map[DatabaseConstants.columnChangeTimestamp] as String),
    );
  }
}

class DatabaseChangeMonitor {
  final DatabaseHelper _databaseHelper;
  Timer? _pollingTimer;
  DateTime _lastChecked = DateTime.now();
  
  final _changeController = StreamController<List<DatabaseChangeEvent>>.broadcast();
  Stream<List<DatabaseChangeEvent>> get onChangeStream => _changeController.stream;

  DatabaseChangeMonitor(this._databaseHelper);

  void start({Duration interval = const Duration(seconds: 2)}) {
    _pollingTimer?.cancel();
    _lastChecked = DateTime.now();
    _pollingTimer = Timer.periodic(interval, (_) => _pollChanges());
  }

  void stop() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  Future<void> _pollChanges() async {
    try {
      final db = await _databaseHelper.database;
      final lastCheckedIso = _lastChecked.toIso8601String();
      
      final maps = await db.query(
        DatabaseConstants.tableDatabaseChanges,
        where: '${DatabaseConstants.columnChangeTimestamp} > ?',
        whereArgs: [lastCheckedIso],
        orderBy: '${DatabaseConstants.columnChangeTimestamp} ASC',
      );

      if (maps.isNotEmpty) {
        final changes = maps.map((map) => DatabaseChangeEvent.fromMap(map)).toList();
        _lastChecked = changes.last.timestamp;
        _changeController.add(changes);
      }
    } catch (e) {
      // Ignore errors for polling
    }
  }
  
  void dispose() {
    stop();
    _changeController.close();
  }
}
