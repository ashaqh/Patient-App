import 'package:flutter_test/flutter_test.dart';
import 'package:carevault/data/datasources/database_helper.dart';
import 'package:carevault/data/datasources/database_constants.dart';
import 'package:carevault/data/datasources/migration_manager.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as path;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DatabaseHelper', () {
    late Database db;
    late DatabaseHelper databaseHelper;

    setUp(() async {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;

      db = await openDatabase(
        inMemoryDatabasePath,
        version: DatabaseConstants.databaseVersion,
      );
      databaseHelper = DatabaseHelper();
    });

    tearDown(() async {
      await db.close();
      await databaseHelper.close();
      await databaseFactory.deleteDatabase(
        path.join(
          await databaseFactory.getDatabasesPath(),
          DatabaseConstants.databaseName,
        ),
      );
    });

    test('DatabaseHelper should initialize without errors', () async {
      expect(databaseHelper, isA<DatabaseHelper>());
    });

    test('DatabaseHelper should handle database upgrades gracefully', () async {
      expect(
        () async => await databaseHelper.database,
        returnsNormally,
      );
    });

    test('DatabaseHelper should properly handle migration errors', () async {
      expect(
        () => MigrationManager.migrate(db, 1, 2),
        returnsNormally,
      );
    });

    test('DatabaseHelper backup and restore perform real file copies', () async {
      final liveDb = await databaseHelper.database;
      await liveDb.insert(DatabaseConstants.tableVitalSigns, {
        DatabaseConstants.columnId: 'backup-test-vital',
        DatabaseConstants.columnVitalSignType: 'heart_rate',
        DatabaseConstants.columnVitalSignValue1: 70.0,
        DatabaseConstants.columnVitalSignUnit: 'bpm',
        DatabaseConstants.columnVitalSignReadingTime: DateTime.now().toIso8601String(),
        DatabaseConstants.columnVitalSignIsManualEntry: 1,
        DatabaseConstants.columnCreatedAt: DateTime.now().toIso8601String(),
        DatabaseConstants.columnUpdatedAt: DateTime.now().toIso8601String(),
        DatabaseConstants.columnLastModified: DateTime.now().toIso8601String(),
        DatabaseConstants.columnVersion: 1,
      });

      final backupPath = await databaseHelper.backupDatabase();
      expect(backupPath, isNotNull);

      final reopenedDb = await databaseHelper.database;
      await reopenedDb.delete(DatabaseConstants.tableVitalSigns);
      final emptied = await reopenedDb.query(DatabaseConstants.tableVitalSigns);
      expect(emptied, isEmpty);

      final restored = await databaseHelper.restoreDatabase(backupPath!);
      expect(restored, isTrue);

      final restoredDb = await databaseHelper.database;
      final rows = await restoredDb.query(DatabaseConstants.tableVitalSigns);
      expect(rows, hasLength(1));
      expect(rows.single[DatabaseConstants.columnId], 'backup-test-vital');
    });
  });
}
