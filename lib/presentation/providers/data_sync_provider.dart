import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/data_sync_service.dart';
import 'database_change_monitor_provider.dart';

final dataSyncServiceProvider = Provider<DataSyncService>((ref) {
  final monitor = ref.watch(databaseChangeMonitorProvider);
  final service = DataSyncService(monitor);
  
  // Start the sync service
  service.start();
  
  ref.onDispose(() {
    service.dispose();
  });
  
  return service;
});
