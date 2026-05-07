import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/database_change_monitor.dart';
import 'medicine_provider.dart';

final databaseChangeMonitorProvider = Provider<DatabaseChangeMonitor>((ref) {
  final helper = ref.watch(databaseHelperProvider);
  final monitor = DatabaseChangeMonitor(helper);
  
  // Start monitoring automatically when the provider is read
  monitor.start();
  
  ref.onDispose(() {
    monitor.dispose();
  });
  
  return monitor;
});

final databaseChangesStreamProvider = StreamProvider<List<DatabaseChangeEvent>>((ref) {
  final monitor = ref.watch(databaseChangeMonitorProvider);
  return monitor.onChangeStream;
});
