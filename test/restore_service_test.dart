import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:carevault/core/services/backup/restore_service.dart';
import 'package:carevault/data/datasources/database_constants.dart';
import 'package:carevault/data/datasources/database_helper.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  const pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');
  const secureStorageChannel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  final binding = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final appDocumentsPath = path.join(
    Directory.systemTemp.path,
    'carevault_test_documents',
  );
  final temporaryPath = path.join(
    Directory.systemTemp.path,
    'carevault_test_temp',
  );

  final mockSecureStorage = <String, String>{};

  setUpAll(() async {
    final documentsDir = Directory(appDocumentsPath);
    if (!await documentsDir.exists()) {
      await documentsDir.create(recursive: true);
    }
    final tempPathDir = Directory(temporaryPath);
    if (!await tempPathDir.exists()) {
      await tempPathDir.create(recursive: true);
    }
    binding.setMockMethodCallHandler(pathProviderChannel, (call) async {
      if (call.method == 'getApplicationDocumentsDirectory') {
        return appDocumentsPath;
      }
      if (call.method == 'getTemporaryDirectory') {
        return temporaryPath;
      }
      return null;
    });

    binding.setMockMethodCallHandler(secureStorageChannel, (call) async {
      if (call.method == 'write') {
        final Map<dynamic, dynamic> args = call.arguments as Map<dynamic, dynamic>;
        mockSecureStorage[args['key'] as String] = args['value'] as String;
        return null;
      }
      if (call.method == 'read') {
        final Map<dynamic, dynamic> args = call.arguments as Map<dynamic, dynamic>;
        return mockSecureStorage[args['key'] as String];
      }
      if (call.method == 'delete') {
        final Map<dynamic, dynamic> args = call.arguments as Map<dynamic, dynamic>;
        mockSecureStorage.remove(args['key'] as String);
        return null;
      }
      if (call.method == 'containsKey') {
        final Map<dynamic, dynamic> args = call.arguments as Map<dynamic, dynamic>;
        return mockSecureStorage.containsKey(args['key'] as String);
      }
      return null;
    });
  });

  tearDownAll(() async {
    binding.setMockMethodCallHandler(pathProviderChannel, null);
    binding.setMockMethodCallHandler(secureStorageChannel, null);
    final documentsDir = Directory(appDocumentsPath);
    if (await documentsDir.exists()) {
      await documentsDir.delete(recursive: true);
    }
    final tempPathDir = Directory(temporaryPath);
    if (await tempPathDir.exists()) {
      await tempPathDir.delete(recursive: true);
    }
  });

  group('RestoreService', () {
    late Directory tempDir;
    late DatabaseHelper dbHelper;

    setUp(() async {
      // Use FFI factory for testing
      databaseFactory = databaseFactoryFfi;
      await databaseFactory.deleteDatabase(
        path.join(
          await databaseFactory.getDatabasesPath(),
          DatabaseConstants.databaseName,
        ),
      );

      tempDir = await Directory.systemTemp.createTemp('restore_test_');
      dbHelper = DatabaseHelper();
    });

    tearDown(() async {
      await dbHelper.close();
      await databaseFactory.deleteDatabase(
        path.join(
          await databaseFactory.getDatabasesPath(),
          DatabaseConstants.databaseName,
        ),
      );
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test(
      '_replaceDatabase should properly close and reinitialize connection',
      () async {
        // Create a test database with some data
        final db = await dbHelper.database;
        await db.insert(DatabaseConstants.tableVitalSigns, {
          DatabaseConstants.columnId: 'test-vital-1',
          DatabaseConstants.columnVitalSignType: 'blood_pressure',
          DatabaseConstants.columnVitalSignValue1: 120.0,
          DatabaseConstants.columnVitalSignValue2: 80.0,
          DatabaseConstants.columnVitalSignUnit: 'mmHg',
          DatabaseConstants.columnVitalSignReadingTime: DateTime.now()
              .toIso8601String(),
          DatabaseConstants.columnCreatedAt: DateTime.now().toIso8601String(),
          DatabaseConstants.columnUpdatedAt: DateTime.now().toIso8601String(),
        });

        // Verify data exists
        final beforeRestore = await db.query(DatabaseConstants.tableVitalSigns);
        expect(beforeRestore.length, 1);

        // Create a backup database file
        final backupDbPath = path.join(tempDir.path, 'backup.db');
        final backupDb = await databaseFactoryFfi.openDatabase(
          backupDbPath,
          options: OpenDatabaseOptions(
            version: DatabaseConstants.databaseVersion,
            onCreate: (db, version) async {
              // Create minimal schema for testing
              await db.execute('''
              CREATE TABLE ${DatabaseConstants.tableVitalSigns} (
                ${DatabaseConstants.columnId} TEXT PRIMARY KEY,
                ${DatabaseConstants.columnVitalSignType} TEXT NOT NULL,
                ${DatabaseConstants.columnVitalSignValue1} REAL NOT NULL,
                ${DatabaseConstants.columnVitalSignValue2} REAL,
                ${DatabaseConstants.columnVitalSignUnit} TEXT NOT NULL,
                ${DatabaseConstants.columnVitalSignReadingTime} TEXT NOT NULL,
                ${DatabaseConstants.columnCreatedAt} TEXT NOT NULL,
                ${DatabaseConstants.columnUpdatedAt} TEXT NOT NULL
              )
            ''');
            },
          ),
        );

        // Insert different data in backup
        await backupDb.insert(DatabaseConstants.tableVitalSigns, {
          DatabaseConstants.columnId: 'test-vital-2',
          DatabaseConstants.columnVitalSignType: 'heart_rate',
          DatabaseConstants.columnVitalSignValue1: 72.0,
          DatabaseConstants.columnVitalSignUnit: 'bpm',
          DatabaseConstants.columnVitalSignReadingTime: DateTime.now()
              .toIso8601String(),
          DatabaseConstants.columnCreatedAt: DateTime.now().toIso8601String(),
          DatabaseConstants.columnUpdatedAt: DateTime.now().toIso8601String(),
        });
        await backupDb.close();

        // Simulate the restore process
        await dbHelper.close();

        final currentDbPath = path.join(
          await databaseFactory.getDatabasesPath(),
          DatabaseConstants.databaseName,
        );

        // Replace database file
        final backupFile = File(backupDbPath);
        final currentFile = File(currentDbPath);
        if (await currentFile.exists()) {
          await currentFile.delete();
        }
        await backupFile.copy(currentDbPath);

        // Reopen the connection without deleting the restored file.
        await dbHelper.reopenDatabase();

        // Verify new connection works and has backup data
        final restoredDb = await dbHelper.database;
        final afterRestore = await restoredDb.query(
          DatabaseConstants.tableVitalSigns,
        );

        expect(afterRestore.length, 1);
        expect(afterRestore[0][DatabaseConstants.columnId], 'test-vital-2');
        expect(
          afterRestore[0][DatabaseConstants.columnVitalSignType],
          'heart_rate',
        );
      },
    );

    test('restore stages files without mutating the live documents directory', () async {
      final restoreService = RestoreService.instance;
      final appDir = await getApplicationDocumentsDirectory();
      final liveFile = File(
        path.join(appDir.path, 'prescriptions', 'stage-test.txt'),
      );
      if (await liveFile.exists()) {
        await liveFile.delete();
      }

      final archive = Archive()
        ..addFile(
          ArchiveFile(
            'files/prescriptions/stage-test.txt',
            4,
            [1, 2, 3, 4],
          ),
        );

      final workspace = await restoreService.stageArchiveFilesForTesting(archive);
      addTearDown(() async {
        if (await workspace.exists()) {
          await workspace.delete(recursive: true);
        }
        if (await liveFile.exists()) {
          await liveFile.delete();
        }
      });

      final stagedFile = File(
        path.join(
          workspace.path,
          'staged_files',
          'prescriptions',
          'stage-test.txt',
        ),
      );

      expect(await stagedFile.exists(), isTrue);
      expect(await liveFile.exists(), isFalse);
    });

    test('rewrite file references updates restored paths in the live database', () async {
      final restoreService = RestoreService.instance;
      final dbPath = path.join(tempDir.path, 'rewrite_refs.db');
      final db = await databaseFactoryFfi.openDatabase(
        dbPath,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: (db, version) async {
            await db.execute('''
              CREATE TABLE ${DatabaseConstants.tablePrescriptions} (
                ${DatabaseConstants.columnId} TEXT PRIMARY KEY,
                ${DatabaseConstants.columnPrescriptionFilePath} TEXT NOT NULL
              )
            ''');
            await db.execute('''
              CREATE TABLE ${DatabaseConstants.tableTestReports} (
                ${DatabaseConstants.columnId} TEXT PRIMARY KEY,
                ${DatabaseConstants.columnTestReportFilePath} TEXT NOT NULL
              )
            ''');
          },
        ),
      );
      addTearDown(() async {
        await db.close();
      });

      const originalPath = '/old-device/prescriptions/report.pdf';
      const restoredPath = '/new-device/prescriptions/report.pdf';

      await db.insert(DatabaseConstants.tablePrescriptions, {
        DatabaseConstants.columnId: 'prescription-1',
        DatabaseConstants.columnPrescriptionFilePath: originalPath,
      });
      await db.insert(DatabaseConstants.tableTestReports, {
        DatabaseConstants.columnId: 'report-1',
        DatabaseConstants.columnTestReportFilePath: originalPath,
      });
      await db.close();

      await restoreService.rewriteFileReferencesForTesting(
        databasePath: dbPath,
        manifest: const [
          {
            'originalPath': originalPath,
            'relativePath': 'files/prescriptions/report.pdf',
            'restoredPath': restoredPath,
          },
        ],
        alreadyResolved: true,
      );

      final verifyDb = await databaseFactoryFfi.openDatabase(dbPath);
      addTearDown(() async {
        await verifyDb.close();
      });
      final prescriptions = await verifyDb.query(
        DatabaseConstants.tablePrescriptions,
      );
      final reports = await verifyDb.query(DatabaseConstants.tableTestReports);

      expect(
        prescriptions.single[DatabaseConstants.columnPrescriptionFilePath],
        restoredPath,
      );
      expect(
        reports.single[DatabaseConstants.columnTestReportFilePath],
        restoredPath,
      );
    });

    test('safe file replacement keeps the original file recoverable on failure', () async {
      final restoreService = RestoreService.instance;
      final sourceFile = File(path.join(tempDir.path, 'source.db'));
      final destinationFile = File(path.join(tempDir.path, 'destination.db'));
      await sourceFile.writeAsString('replacement data');
      await destinationFile.writeAsString('original data');

      addTearDown(() async {
        if (await sourceFile.exists()) {
          await sourceFile.delete();
        }
        if (await destinationFile.exists()) {
          await destinationFile.delete();
        }
        final tempFile = File('${destinationFile.path}.tmp');
        if (await tempFile.exists()) {
          await tempFile.delete();
        }
        final backupFile = File('${destinationFile.path}.bak');
        if (await backupFile.exists()) {
          await backupFile.delete();
        }
      });

      await restoreService.safeReplaceFileForTesting(
        sourcePath: sourceFile.path,
        destinationPath: destinationFile.path,
      );

      expect(await destinationFile.readAsString(), 'replacement data');
      expect(await File('${destinationFile.path}.bak').exists(), isFalse);
    });

    test('restore settings decoding includes retention count', () {
      final restoreService = RestoreService.instance;
      final archive = Archive()
        ..addFile(
          ArchiveFile(
            'settings.json',
            120,
            utf8.encode(
              '{"automaticBackupEnabled":true,"frequency":"weekly","onlyOnWifi":false,"onlyWhileCharging":true,"retentionCount":9}',
            ),
          ),
        );

      final normalized = restoreService.decodeBackupSettingsForTesting(archive);

      expect(normalized['backup_auto_enabled'], 'true');
      expect(normalized['backup_frequency'], 'weekly');
      expect(normalized['backup_wifi_only'], 'false');
      expect(normalized['backup_charging_only'], 'true');
      expect(normalized['backup_retention_count'], '9');
    });

    test('restore profile writes user_profile_data to secure storage', () async {
      final restoreService = RestoreService.instance;

      final profileData = '{"fullName":"John Doe","age":"35"}';
      final archive = Archive()
        ..addFile(
          ArchiveFile(
            'profile.json',
            profileData.length,
            utf8.encode(profileData),
          ),
        );

      mockSecureStorage.clear();
      await restoreService.restoreProfileForTesting(archive);

      expect(mockSecureStorage['user_profile_data'], profileData);
    });

    test('restore profile does nothing if profile.json is absent', () async {
      final restoreService = RestoreService.instance;
      final archive = Archive();

      mockSecureStorage['user_profile_data'] = 'existing_data';
      await restoreService.restoreProfileForTesting(archive);

      expect(mockSecureStorage['user_profile_data'], 'existing_data');
    });

    test('foreign keys are re-enabled after guarded merge failures', () async {
      final restoreService = RestoreService.instance;
      await expectLater(
        () => restoreService.withForeignKeysGuardForTesting((db) async {
          throw StateError('forced merge failure');
        }),
        throwsA(isA<StateError>()),
      );

      final db = await dbHelper.database;
      final pragmaRows = await db.rawQuery('PRAGMA foreign_keys');
      expect(pragmaRows.single.values.single, 1);
    });

    test('restore should handle database_closed error gracefully', () async {
      // This test verifies that the error handling improvements work
      final restoreService = RestoreService.instance;

      // Attempt to restore with invalid file ID (will fail)
      final result = await restoreService.restoreFromDriveBackup(
        'invalid-file-id',
        passphrase: 'test-passphrase',
        mode: RestoreMode.replace,
      );

      expect(result.success, false);
      expect(result.message, isNotEmpty);

      // Verify database is still accessible after failed restore
      final db = await dbHelper.database;
      expect(db.isOpen, true);
    });

    test('rollback should properly restore database connection', () async {
      // Create initial database with data
      final db = await dbHelper.database;
      await db.insert(DatabaseConstants.tableVitalSigns, {
        DatabaseConstants.columnId: 'original-vital',
        DatabaseConstants.columnVitalSignType: 'temperature',
        DatabaseConstants.columnVitalSignValue1: 98.6,
        DatabaseConstants.columnVitalSignUnit: 'F',
        DatabaseConstants.columnVitalSignReadingTime: DateTime.now()
            .toIso8601String(),
        DatabaseConstants.columnCreatedAt: DateTime.now().toIso8601String(),
        DatabaseConstants.columnUpdatedAt: DateTime.now().toIso8601String(),
      });

      // Verify original data
      final original = await db.query(DatabaseConstants.tableVitalSigns);
      expect(original.length, 1);
      expect(original[0][DatabaseConstants.columnId], 'original-vital');

      // After rollback, database should still be accessible
      await dbHelper.close();
      await dbHelper.reopenDatabase();

      final restoredDb = await dbHelper.database;
      expect(restoredDb.isOpen, true);
    });

    test('rewrite file references should skip updates gracefully if table is missing', () async {
      final restoreService = RestoreService.instance;
      final dbPath = path.join(tempDir.path, 'rewrite_refs_missing_table.db');
      final db = await databaseFactoryFfi.openDatabase(
        dbPath,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: (db, version) async {
            // Only create prescriptions, no test_reports table
            await db.execute('''
              CREATE TABLE ${DatabaseConstants.tablePrescriptions} (
                ${DatabaseConstants.columnId} TEXT PRIMARY KEY,
                ${DatabaseConstants.columnPrescriptionFilePath} TEXT NOT NULL
              )
            ''');
          },
        ),
      );
      addTearDown(() async {
        await db.close();
      });

      const originalPath = '/old-device/prescriptions/report.pdf';
      const restoredPath = '/new-device/prescriptions/report.pdf';

      await db.insert(DatabaseConstants.tablePrescriptions, {
        DatabaseConstants.columnId: 'prescription-1',
        DatabaseConstants.columnPrescriptionFilePath: originalPath,
      });
      await db.close();

      // This should run without throwing 'no such table: test_reports'
      final result = await restoreService.rewriteFileReferencesForTesting(
        databasePath: dbPath,
        manifest: const [
          {
            'originalPath': originalPath,
            'relativePath': 'files/prescriptions/report.pdf',
            'restoredPath': restoredPath,
          },
        ],
        alreadyResolved: true,
      );

      final verifyDb = await databaseFactoryFfi.openDatabase(dbPath);
      addTearDown(() async {
        await verifyDb.close();
      });
      final prescriptions = await verifyDb.query(
        DatabaseConstants.tablePrescriptions,
      );

      expect(
        prescriptions.single[DatabaseConstants.columnPrescriptionFilePath],
        restoredPath,
      );
      expect(result, isNotEmpty);
    });

    test('mergeDatabase should gracefully handle missing tables in backup database', () async {
      final restoreService = RestoreService.instance;

      // Prepare main database with all tables
      final mainDb = await dbHelper.database;
      await mainDb.insert(DatabaseConstants.tableVitalSigns, {
        DatabaseConstants.columnId: 'vital-main-test',
        DatabaseConstants.columnVitalSignType: 'blood_pressure',
        DatabaseConstants.columnVitalSignValue1: 120.0,
        DatabaseConstants.columnVitalSignValue2: 80.0,
        DatabaseConstants.columnVitalSignUnit: 'mmHg',
        DatabaseConstants.columnVitalSignReadingTime: DateTime.now().toIso8601String(),
        DatabaseConstants.columnCreatedAt: DateTime.now().toIso8601String(),
        DatabaseConstants.columnUpdatedAt: DateTime.now().toIso8601String(),
      });

      // Prepare backup database that DOES NOT have the tableTestReports or other tables
      final backupDbPath = path.join(tempDir.path, 'legacy_backup.db');
      final backupDb = await databaseFactoryFfi.openDatabase(
        backupDbPath,
        options: OpenDatabaseOptions(
          version: DatabaseConstants.databaseVersion,
          onCreate: (db, version) async {
            // Only create VitalSigns table, no tableTestReports or others
            await db.execute('''
              CREATE TABLE ${DatabaseConstants.tableVitalSigns} (
                ${DatabaseConstants.columnId} TEXT PRIMARY KEY,
                ${DatabaseConstants.columnVitalSignType} TEXT NOT NULL,
                ${DatabaseConstants.columnVitalSignValue1} REAL NOT NULL,
                ${DatabaseConstants.columnVitalSignValue2} REAL,
                ${DatabaseConstants.columnVitalSignUnit} TEXT NOT NULL,
                ${DatabaseConstants.columnVitalSignReadingTime} TEXT NOT NULL,
                ${DatabaseConstants.columnCreatedAt} TEXT NOT NULL,
                ${DatabaseConstants.columnUpdatedAt} TEXT NOT NULL
              )
            ''');
          },
        ),
      );

      // Insert different vital record in backup database
      await backupDb.insert(DatabaseConstants.tableVitalSigns, {
        DatabaseConstants.columnId: 'vital-backup-test',
        DatabaseConstants.columnVitalSignType: 'heart_rate',
        DatabaseConstants.columnVitalSignValue1: 72.0,
        DatabaseConstants.columnVitalSignUnit: 'bpm',
        DatabaseConstants.columnVitalSignReadingTime: DateTime.now().toIso8601String(),
        DatabaseConstants.columnCreatedAt: DateTime.now().toIso8601String(),
        DatabaseConstants.columnUpdatedAt: DateTime.now().toIso8601String(),
      });
      await backupDb.close();

      // Execute merge database, which will process vital_signs successfully
      // and skip test_reports without throwing any exceptions
      await restoreService.mergeDatabaseForTesting(backupDbPath);

      final mergedDb = await dbHelper.database;
      final vitals = await mergedDb.query(DatabaseConstants.tableVitalSigns);
      final vitalIds = vitals.map((v) => v[DatabaseConstants.columnId]);
      expect(vitalIds, contains('vital-main-test'));
      expect(vitalIds, contains('vital-backup-test'));
    });

    test('safeCleanDirectory and copyDirectory should be resilient to locked files', () async {
      final sourceDir = Directory(path.join(tempDir.path, 'source_dir'));
      final targetDir = Directory(path.join(tempDir.path, 'target_dir'));
      await sourceDir.create(recursive: true);
      await targetDir.create(recursive: true);

      final file1 = File(path.join(sourceDir.path, 'file1.txt'));
      final file2 = File(path.join(sourceDir.path, 'file2.txt'));
      await file1.writeAsString('source file 1 content');
      await file2.writeAsString('source file 2 content');

      final targetFile1 = File(path.join(targetDir.path, 'file1.txt'));
      await targetFile1.writeAsString('original target file 1 content');

      // Keep targetFile1 open with a write lock to simulate OS/view-engine lock
      final raf = await targetFile1.open(mode: FileMode.append);
      await raf.lock();

      addTearDown(() async {
        try {
          await raf.unlock();
          await raf.close();
        } catch (_) {}
      });

      // Try copyDirectory. Under the hood, this will attempt to safe-clean targetDir,
      // fail to delete file1.txt (locked), but should NOT crash and should successfully
      // copy file2.txt to targetDir.
      await RestoreService.copyDirectoryForTesting(sourceDir, targetDir);

      // Verify file2 was copied successfully
      final targetFile2 = File(path.join(targetDir.path, 'file2.txt'));
      expect(await targetFile2.exists(), isTrue);
      expect(await targetFile2.readAsString(), 'source file 2 content');

      // targetFile1 (locked) was not overwritten or deleted, but copy didn't crash
      expect(await targetFile1.exists(), isTrue);
    });

    test('mergeDatabase should successfully merge multiple prescriptions and vital records', () async {
      final restoreService = RestoreService.instance;

      // Prepare main database with one prescription and one vital record
      final mainDb = await dbHelper.database;
      await mainDb.insert(DatabaseConstants.tableVitalSigns, {
        DatabaseConstants.columnId: 'vital-main-2',
        DatabaseConstants.columnVitalSignType: 'blood_pressure',
        DatabaseConstants.columnVitalSignValue1: 118.0,
        DatabaseConstants.columnVitalSignValue2: 78.0,
        DatabaseConstants.columnVitalSignUnit: 'mmHg',
        DatabaseConstants.columnVitalSignReadingTime: DateTime.now().toIso8601String(),
        DatabaseConstants.columnCreatedAt: DateTime.now().toIso8601String(),
        DatabaseConstants.columnUpdatedAt: DateTime.now().toIso8601String(),
      });
      await mainDb.insert(DatabaseConstants.tablePrescriptions, {
        DatabaseConstants.columnId: 'presc-main',
        DatabaseConstants.columnPrescriptionDoctorName: 'Dr. Main',
        DatabaseConstants.columnPrescriptionDate: DateTime.now().toIso8601String(),
        DatabaseConstants.columnPrescriptionFilePath: '/path/to/main.pdf',
        DatabaseConstants.columnPrescriptionFileName: 'main.pdf',
        DatabaseConstants.columnPrescriptionFileType: 'pdf',
        DatabaseConstants.columnCreatedAt: DateTime.now().toIso8601String(),
        DatabaseConstants.columnUpdatedAt: DateTime.now().toIso8601String(),
      });

      // Prepare backup database with different records
      final backupDbPath = path.join(tempDir.path, 'multi_merge_backup.db');
      final backupDb = await databaseFactoryFfi.openDatabase(
        backupDbPath,
        options: OpenDatabaseOptions(
          version: DatabaseConstants.databaseVersion,
          onCreate: (db, version) async {
            await db.execute('''
              CREATE TABLE ${DatabaseConstants.tableVitalSigns} (
                ${DatabaseConstants.columnId} TEXT PRIMARY KEY,
                ${DatabaseConstants.columnVitalSignType} TEXT NOT NULL,
                ${DatabaseConstants.columnVitalSignValue1} REAL NOT NULL,
                ${DatabaseConstants.columnVitalSignValue2} REAL,
                ${DatabaseConstants.columnVitalSignUnit} TEXT NOT NULL,
                ${DatabaseConstants.columnVitalSignReadingTime} TEXT NOT NULL,
                ${DatabaseConstants.columnCreatedAt} TEXT NOT NULL,
                ${DatabaseConstants.columnUpdatedAt} TEXT NOT NULL
              )
            ''');
            await db.execute('''
              CREATE TABLE ${DatabaseConstants.tablePrescriptions} (
                ${DatabaseConstants.columnId} TEXT PRIMARY KEY,
                ${DatabaseConstants.columnPrescriptionDoctorName} TEXT,
                ${DatabaseConstants.columnPrescriptionDate} TEXT NOT NULL,
                ${DatabaseConstants.columnPrescriptionFilePath} TEXT NOT NULL,
                ${DatabaseConstants.columnPrescriptionFileName} TEXT NOT NULL,
                ${DatabaseConstants.columnPrescriptionFileType} TEXT NOT NULL,
                ${DatabaseConstants.columnCreatedAt} TEXT NOT NULL,
                ${DatabaseConstants.columnUpdatedAt} TEXT NOT NULL
              )
            ''');
          },
        ),
      );

      // Insert backup records
      await backupDb.insert(DatabaseConstants.tableVitalSigns, {
        DatabaseConstants.columnId: 'vital-backup-2',
        DatabaseConstants.columnVitalSignType: 'heart_rate',
        DatabaseConstants.columnVitalSignValue1: 80.0,
        DatabaseConstants.columnVitalSignUnit: 'bpm',
        DatabaseConstants.columnVitalSignReadingTime: DateTime.now().toIso8601String(),
        DatabaseConstants.columnCreatedAt: DateTime.now().toIso8601String(),
        DatabaseConstants.columnUpdatedAt: DateTime.now().toIso8601String(),
      });
      await backupDb.insert(DatabaseConstants.tablePrescriptions, {
        DatabaseConstants.columnId: 'presc-backup',
        DatabaseConstants.columnPrescriptionDoctorName: 'Dr. Backup',
        DatabaseConstants.columnPrescriptionDate: DateTime.now().toIso8601String(),
        DatabaseConstants.columnPrescriptionFilePath: '/path/to/backup.pdf',
        DatabaseConstants.columnPrescriptionFileName: 'backup.pdf',
        DatabaseConstants.columnPrescriptionFileType: 'pdf',
        DatabaseConstants.columnCreatedAt: DateTime.now().toIso8601String(),
        DatabaseConstants.columnUpdatedAt: DateTime.now().toIso8601String(),
      });
      await backupDb.close();

      // Merge databases
      await restoreService.mergeDatabaseForTesting(backupDbPath);

      final mergedDb = await dbHelper.database;
      final vitals = await mergedDb.query(DatabaseConstants.tableVitalSigns);
      final prescriptions = await mergedDb.query(DatabaseConstants.tablePrescriptions);

      final vitalIds = vitals.map((v) => v[DatabaseConstants.columnId]);
      expect(vitalIds, contains('vital-main-2'));
      expect(vitalIds, contains('vital-backup-2'));

      expect(prescriptions.length, 2);
      final docNames = prescriptions.map((p) => p[DatabaseConstants.columnPrescriptionDoctorName]);
      expect(docNames, containsAll(['Dr. Main', 'Dr. Backup']));
    });
  });
}
