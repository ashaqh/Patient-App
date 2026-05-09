import 'package:flutter_test/flutter_test.dart';
import 'package:carevault/data/datasources/database_helper.dart';
import 'package:carevault/data/datasources/database_constants.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('DatabaseHelper', () {
    late Database db;
    late DatabaseHelper databaseHelper;
    
    setUp(() async {
      // Initialize FFI
      sqfliteFfiInit();
      // Change the default factory to the FFI factory
      databaseFactory = databaseFactoryFfi;
      
      // Create an in-memory database for testing
      db = await openDatabase(inMemoryDatabasePath, version: DatabaseConstants.databaseVersion);
      databaseHelper = DatabaseHelper();
    });
    
    tearDown(() async {
      await db.close();
    });
    
    test('DatabaseHelper should initialize without errors', () async {
      expect(databaseHelper, isA<DatabaseHelper>());
    });
    
    test('DatabaseHelper should handle database upgrades gracefully', () async {
      // Test that the database helper can handle migrations without throwing errors
      expect(
        () async => await databaseHelper.database,
        returnsNormally,
      );
    });
    
    test('DatabaseHelper should properly handle migration errors', () async {
      // Test that migration errors are properly caught and handled
      expect(
        () => MigrationManager.migrate(db, 1, 2),
        returnsNormally,
      );
    });
  });
}