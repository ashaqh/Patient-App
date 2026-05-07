import 'dart:async';
import 'database_change_monitor.dart';
import '../../utils/error_utils.dart';

class DataSyncService {
  final DatabaseChangeMonitor _monitor;
  StreamSubscription? _subscription;
  bool _isSyncing = false;

  DataSyncService(this._monitor);

  void start() {
    _subscription = _monitor.onChangeStream.listen((changes) {
      _handleChanges(changes);
    });
  }

  void stop() {
    _subscription?.cancel();
  }

  Future<void> _handleChanges(List<DatabaseChangeEvent> changes) async {
    if (_isSyncing || changes.isEmpty) return;
    _isSyncing = true;
    
    try {
      // In a real application, here we would push changes to a backend
      // API or a cloud database. For now, we simulate sync logic:
      for (var change in changes) {
        ErrorUtils.logInfo('Syncing ${change.operation} on ${change.tableName} (Row: ${change.rowId})', tag: 'DataSync');
      }
      
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 500));
      
    } catch (e, stackTrace) {
      ErrorUtils.logError('Data sync failed', error: e, stackTrace: stackTrace, tag: 'DataSync');
    } finally {
      _isSyncing = false;
    }
  }
  
  void dispose() {
    stop();
  }
}
