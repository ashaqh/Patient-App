# Backup & Restore - Recommended Fixes & Code Examples

## Priority 1: Critical Fixes (Implement Immediately)

### Fix 1: Replace Database with Verification

**File**: `lib/core/services/backup/restore_service.dart`
**Current Location**: Lines 199-207
**Severity**: CRITICAL - Data corruption risk

**Current Code**:
```dart
Future<void> _replaceDatabase(String backupDatabasePath) async {
  await _databaseHelper.close();
  final currentPath = path.join(
    await getDatabasesPath(),
    DatabaseConstants.databaseName,
  );
  await File(backupDatabasePath).copy(currentPath);
  await _databaseHelper.database;
}
```

**Recommended Fix**:
```dart
Future<void> _replaceDatabase(String backupDatabasePath) async {
  await _databaseHelper.close();
  final currentPath = path.join(
    await getDatabasesPath(),
    DatabaseConstants.databaseName,
  );
  
  final sourceFile = File(backupDatabasePath);
  final destFile = File(currentPath);
  
  // Verify source exists and is readable
  if (!await sourceFile.exists()) {
    throw StateError('Backup database file not found at $backupDatabasePath');
  }
  
  final sourceSize = await sourceFile.length();
  if (sourceSize == 0) {
    throw StateError('Backup database is empty (0 bytes)');
  }
  
  // Verify destination directory exists
  final destDir = destFile.parent;
  if (!await destDir.exists()) {
    await destDir.create(recursive: true);
  }
  
  try {
    // Perform copy
    final copiedFile = await sourceFile.copy(currentPath);
    
    // Verify copy succeeded
    final copiedSize = await copiedFile.length();
    if (sourceSize != copiedSize) {
      throw StateError(
        'Database copy verification failed: '
        'expected $sourceSize bytes, got $copiedSize bytes'
      );
    }
    
    // Verify database integrity with test query
    int retries = 3;
    Database? testDb;
    while (retries > 0) {
      try {
        testDb = await openDatabase(currentPath);
        await testDb.rawQuery('SELECT 1');
        await testDb.close();
        break;
      } catch (e) {
        await testDb?.close();
        retries--;
        if (retries == 0) {
          throw StateError('Database integrity check failed: $e');
        }
        await Future.delayed(const Duration(milliseconds: 200));
      }
    }
    
    // Reopen database connection
    await _databaseHelper.database;
    
    ErrorUtils.logInfo(
      'Database replaced successfully: $sourceSize bytes',
      tag: 'Restore',
    );
  } catch (e) {
    ErrorUtils.logError(
      'Failed to replace database',
      error: e,
      tag: 'Restore',
    );
    rethrow;
  }
}
```

**Changes**:
- ✅ Verify source file exists and is not empty
- ✅ Verify destination directory exists
- ✅ Verify copy size matches source size
- ✅ Test database integrity with query
- ✅ Retry logic for database connection
- ✅ Proper error logging

---

### Fix 2: Disk Space Validation

**File**: `lib/core/services/backup/restore_service.dart`
**Current Location**: Lines 273-308 (in `_createRollbackSnapshot`)
**Severity**: CRITICAL - Restore failure risk

**Add Before Snapshot Creation**:
```dart
Future<Directory> _createRollbackSnapshot() async {
  // Check available disk space
  final tempDir = await getTemporaryDirectory();
  
  try {
    // Get current database size
    final currentDbPath = path.join(
      await getDatabasesPath(),
      DatabaseConstants.databaseName,
    );
    final currentDbFile = File(currentDbPath);
    int totalSizeNeeded = 0;
    
    if (await currentDbFile.exists()) {
      totalSizeNeeded += await currentDbFile.length();
    }
    
    // Add attachment directories size
    final appDir = await getApplicationDocumentsDirectory();
    for (final dirName in [
      AppConstants.prescriptionsDirectory,
      AppConstants.reportsDirectory,
      AppConstants.imagesDirectory,
    ]) {
      final dir = Directory(path.join(appDir.path, dirName));
      if (await dir.exists()) {
        totalSizeNeeded += await _getDirectorySize(dir);
      }
    }
    
    // Check available space (need 1.5x for safety margin)
    final requiredSpace = (totalSizeNeeded * 1.5).toInt();
    final stat = await tempDir.stat();
    final availableSpace = stat.size;
    
    if (availableSpace < requiredSpace) {
      throw StateError(
        'Insufficient disk space for restore. '
        'Required: ${_formatBytes(requiredSpace)}, '
        'Available: ${_formatBytes(availableSpace)}'
      );
    }
    
    ErrorUtils.logInfo(
      'Disk space check passed: '
      'need ${_formatBytes(requiredSpace)}, '
      'have ${_formatBytes(availableSpace)}',
      tag: 'Restore',
    );
  } catch (e) {
    ErrorUtils.logError(
      'Disk space check failed',
      error: e,
      tag: 'Restore',
    );
    rethrow;
  }
  
  // ... rest of snapshot creation
}

Future<int> _getDirectorySize(Directory dir) async {
  int size = 0;
  try {
    await for (final entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is File) {
        size += await entity.length();
      }
    }
  } catch (e) {
    ErrorUtils.logWarning(
      'Error calculating directory size: $e',
      tag: 'Restore',
    );
  }
  return size;
}

String _formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  if (bytes < 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
}
```

**Changes**:
- ✅ Calculate total space needed
- ✅ Check available disk space
- ✅ Require 1.5x safety margin
- ✅ Provide detailed error messages
- ✅ Log space check results

---

### Fix 3: File Reference Verification

**File**: `lib/core/services/backup/restore_service.dart`
**Current Location**: Lines 150-197 (in `_rewriteFileReferences`)
**Severity**: HIGH - App crashes risk

**Replace the update loops**:
```dart
Future<List<Map<String, String>>> _rewriteFileReferences({
  required String databasePath,
  required List<Map<String, String>> manifest,
  bool alreadyResolved = false,
}) async {
  if (manifest.isEmpty) return manifest;
  final appDir = await getApplicationDocumentsDirectory();
  
  final resolved = manifest
      .map(
        (entry) => {
          'originalPath': entry['originalPath']!,
          'relativePath': entry['relativePath']!,
          'restoredPath': alreadyResolved
              ? entry['restoredPath'] ?? entry['originalPath']!
              : path.join(
                  appDir.path,
                  entry['relativePath']!.replaceFirst(
                    RegExp(r'^files[/\\]'),
                    '',
                  ),
                ),
        },
      )
      .toList(growable: false);

  final db = await openDatabase(databasePath);
  try {
    int successCount = 0;
    int failureCount = 0;
    
    for (final entry in resolved) {
      final originalPath = entry['originalPath']!;
      final restoredPath = entry['restoredPath']!;
      
      // Verify file exists before updating database
      final restoredFile = File(restoredPath);
      if (!await restoredFile.exists()) {
        ErrorUtils.logWarning(
          'Restored file not found: $restoredPath (original: $originalPath)',
          tag: 'Restore',
        );
        failureCount++;
        continue;
      }
      
      // Verify file is readable
      try {
        await restoredFile.stat();
      } catch (e) {
        ErrorUtils.logWarning(
          'Cannot access restored file: $restoredPath - $e',
          tag: 'Restore',
        );
        failureCount++;
        continue;
      }
      
      try {
        // Update prescriptions table
        final prescriptionUpdates = await db.update(
          DatabaseConstants.tablePrescriptions,
          {DatabaseConstants.columnPrescriptionFilePath: restoredPath},
          where: '${DatabaseConstants.columnPrescriptionFilePath} = ?',
          whereArgs: [originalPath],
        );
        
        // Update test reports table
        final reportUpdates = await db.update(
          DatabaseConstants.tableTestReports,
          {DatabaseConstants.columnTestReportFilePath: restoredPath},
          where: '${DatabaseConstants.columnTestReportFilePath} = ?',
          whereArgs: [originalPath],
        );
        
        if (prescriptionUpdates > 0 || reportUpdates > 0) {
          successCount++;
          ErrorUtils.logInfo(
            'Updated file reference: $originalPath -> $restoredPath '
            '(prescriptions: $prescriptionUpdates, reports: $reportUpdates)',
            tag: 'Restore',
          );
        }
      } catch (e) {
        ErrorUtils.logError(
          'Failed to update file reference: $originalPath',
          error: e,
          tag: 'Restore',
        );
        failureCount++;
      }
    }
    
    ErrorUtils.logInfo(
      'File reference rewriting complete: '
      '$successCount successful, $failureCount failed',
      tag: 'Restore',
    );
    
  } finally {
    await db.close();
  }
  
  return resolved;
}
```

**Changes**:
- ✅ Verify file exists before updating database
- ✅ Verify file is readable
- ✅ Track success/failure counts
- ✅ Log detailed information
- ✅ Continue on individual failures instead of crashing

---

## Priority 2: Important Fixes (Implement Soon)

### Fix 4: Column Type Validation in Merge

**File**: `lib/core/services/backup/restore_service.dart`
**Current Location**: Lines 209-233 (in `_mergeDatabase`)
**Severity**: MEDIUM - Data corruption risk

**Add Helper Method**:
```dart
Future<Map<String, String>> _getColumnTypes(
  Transaction txn,
  String table, {
  String? schema,
}) async {
  final pragma = schema == null
      ? 'PRAGMA table_info(${_quoteIdentifier(table)})'
      : 'PRAGMA ${_quoteIdentifier(schema)}.table_info(${_quoteIdentifier(table)})';
  
  try {
    final rows = await txn.rawQuery(pragma);
    return {
      for (final row in rows)
        row['name'] as String: (row['type'] as String).toUpperCase(),
    };
  } catch (e) {
    ErrorUtils.logWarning(
      'Failed to get column types for $table: $e',
      tag: 'Restore',
    );
    return {};
  }
}
```

**Update Merge Loop**:
```dart
Future<void> _mergeDatabase(String backupDatabasePath) async {
  final db = await _databaseHelper.database;
  await db.execute('PRAGMA foreign_keys = OFF');
  
  try {
    await db.transaction((txn) async {
      await txn.execute('ATTACH DATABASE ? AS backup', [backupDatabasePath]);
      try {
        for (final table in _mergeTables) {
          try {
            final currentColumns = await _columns(txn, table);
            final backupColumns = await _columns(txn, table, schema: 'backup');
            
            if (currentColumns.isEmpty || backupColumns.isEmpty) {
              ErrorUtils.logInfo(
                'Skipping merge for $table: '
                'current columns: ${currentColumns.length}, '
                'backup columns: ${backupColumns.length}',
                tag: 'Restore',
              );
              continue;
            }
            
            // Get column types for validation
            final currentTypes = await _getColumnTypes(txn, table);
            final backupTypes = await _getColumnTypes(txn, table, schema: 'backup');
            
            // Find compatible columns (same name AND same type)
            final columns = currentColumns
                .where((col) =>
                  backupColumns.contains(col) &&
                  currentTypes[col] == backupTypes[col]
                )
                .toList(growable: false);
            
            if (columns.isEmpty) {
              ErrorUtils.logWarning(
                'No compatible columns found for merge in $table',
                tag: 'Restore',
              );
              continue;
            }
            
            final columnSql = columns.map(_quoteIdentifier).join(', ');
            final rowsAffected = await txn.rawUpdate(
              'INSERT OR REPLACE INTO ${_quoteIdentifier(table)} ($columnSql) '
              'SELECT $columnSql FROM backup.${_quoteIdentifier(table)}',
            );
            
            ErrorUtils.logInfo(
              'Merged $table: $rowsAffected rows, '
              '${columns.length} columns',
              tag: 'Restore',
            );
          } catch (e) {
            ErrorUtils.logError(
              'Error merging table $table',
              error: e,
              tag: 'Restore',
            );
            // Continue with next table instead of failing
          }
        }
      } finally {
        await txn.execute('DETACH DATABASE backup');
      }
    });
  } finally {
    await db.execute('PRAGMA foreign_keys = ON');
  }
}
```

**Changes**:
- ✅ Validate column types match
- ✅ Skip incompatible columns
- ✅ Log merge statistics
- ✅ Handle per-table errors gracefully

---

### Fix 5: Referential Integrity Check

**File**: `lib/core/services/backup/restore_service.dart`
**Add After Merge**:

```dart
Future<void> _verifyReferentialIntegrity(Database db) async {
  try {
    ErrorUtils.logInfo('Starting referential integrity check', tag: 'Restore');
    
    // Check for orphaned prescriptions (if medicine_id column exists)
    try {
      final orphanedPrescriptions = await db.rawQuery('''
        SELECT COUNT(*) as count FROM prescriptions p
        WHERE p.medicine_id IS NOT NULL 
        AND NOT EXISTS (SELECT 1 FROM medicines m WHERE m.id = p.medicine_id)
      ''');
      
      final orphanCount = Sqflite.firstIntValue(orphanedPrescriptions) ?? 0;
      if (orphanCount > 0) {
        ErrorUtils.logWarning(
          'Found $orphanCount orphaned prescriptions',
          tag: 'Restore',
        );
        
        // Delete orphaned records
        await db.delete(
          DatabaseConstants.tablePrescriptions,
          where: 'medicine_id IS NOT NULL AND medicine_id NOT IN '
              '(SELECT id FROM medicines)',
        );
        
        ErrorUtils.logInfo(
          'Deleted $orphanCount orphaned prescriptions',
          tag: 'Restore',
        );
      }
    } catch (e) {
      ErrorUtils.logWarning(
        'Could not check prescriptions referential integrity: $e',
        tag: 'Restore',
      );
    }
    
    // Check for orphaned reminder logs
    try {
      final orphanedReminders = await db.rawQuery('''
        SELECT COUNT(*) as count FROM reminder_logs r
        WHERE r.medicine_id IS NOT NULL 
        AND NOT EXISTS (SELECT 1 FROM medicines m WHERE m.id = r.medicine_id)
      ''');
      
      final orphanCount = Sqflite.firstIntValue(orphanedReminders) ?? 0;
      if (orphanCount > 0) {
        ErrorUtils.logWarning(
          'Found $orphanCount orphaned reminder logs',
          tag: 'Restore',
        );
        
        await db.delete(
          DatabaseConstants.tableReminderLogs,
          where: 'medicine_id IS NOT NULL AND medicine_id NOT IN '
              '(SELECT id FROM medicines)',
        );
      }
    } catch (e) {
      ErrorUtils.logWarning(
        'Could not check reminder logs referential integrity: $e',
        tag: 'Restore',
      );
    }
    
    ErrorUtils.logInfo(
      'Referential integrity check completed',
      tag: 'Restore',
    );
  } catch (e) {
    ErrorUtils.logError(
      'Referential integrity check failed',
      error: e,
      tag: 'Restore',
    );
    // Don't rethrow - this is a cleanup operation
  }
}
```

**Call After Merge**:
```dart
case RestoreMode.merge:
  await _mergeDatabase(backupDb.path);
  await _verifyReferentialIntegrity(await _databaseHelper.database);
  break;
```

---

## Priority 3: Enhancements (Nice to Have)

### Enhancement 1: Restore Progress Tracking

**Add to RestoreService**:
```dart
class RestoreProgress {
  final int totalSteps;
  int currentStep = 0;
  String currentMessage = '';
  
  double get progress => currentStep / totalSteps;
  
  void update(int step, String message) {
    currentStep = step;
    currentMessage = message;
  }
}

// Add to restoreFromDriveBackup
final progress = RestoreProgress(totalSteps: 5);

// Step 1: Download
progress.update(1, 'Downloading backup...');
final downloadedFile = await _backupService.downloadBackup(driveFileId);

// Step 2: Decrypt
progress.update(2, 'Decrypting backup...');
final archive = await _packageService.decryptPackage(downloadedFile);

// Step 3: Create snapshot
progress.update(3, 'Creating rollback snapshot...');
rollbackDir = await _createRollbackSnapshot();

// Step 4: Restore
progress.update(4, 'Restoring data...');
await _restoreArchive(archive, mode: mode);

// Step 5: Verify
progress.update(5, 'Verifying restore...');
```

---

### Enhancement 2: Restore Statistics

**Add to RestoreResult**:
```dart
class RestoreResult {
  final bool success;
  final String message;
  final DateTime? startTime;
  final DateTime? endTime;
  final int? recordsRestored;
  final int? filesRestored;
  final int? bytesRestored;

  const RestoreResult({
    required this.success,
    required this.message,
    this.startTime,
    this.endTime,
    this.recordsRestored,
    this.filesRestored,
    this.bytesRestored,
  });
  
  Duration? get duration {
    if (startTime == null || endTime == null) return null;
    return endTime!.difference(startTime!);
  }
}
```

---

## Testing Recommendations

### Unit Tests to Add

```dart
// test/restore_service_test.dart

void main() {
  group('RestoreService', () {
    test('replace mode verifies database integrity', () async {
      // Test that corrupted database is detected
    });
    
    test('merge mode handles missing tables', () async {
      // Test that merge skips non-existent tables
    });
    
    test('file reference rewriting skips missing files', () async {
      // Test that missing files don't crash restore
    });
    
    test('rollback restores previous state on failure', () async {
      // Test that rollback works correctly
    });
    
    test('disk space check prevents restore on low space', () async {
      // Test that insufficient space is detected
    });
    
    test('referential integrity check removes orphaned records', () async {
      // Test that orphaned records are cleaned up
    });
  });
}
```

---

## Implementation Checklist

- [ ] Fix 1: Replace database with verification
- [ ] Fix 2: Disk space validation
- [ ] Fix 3: File reference verification
- [ ] Fix 4: Column type validation in merge
- [ ] Fix 5: Referential integrity check
- [ ] Add unit tests for all fixes
- [ ] Test with corrupted backups
- [ ] Test with low disk space
- [ ] Test with missing files
- [ ] Test with schema version mismatches
- [ ] Update error messages for clarity
- [ ] Add logging for debugging
- [ ] Document restore process
- [ ] Create user guide for restore modes

---

## Deployment Notes

1. **Backward Compatibility**: All fixes are backward compatible
2. **Database Migration**: No schema changes required
3. **Testing**: Test with real backups before deploying
4. **Rollout**: Consider phased rollout to catch issues
5. **Monitoring**: Monitor restore failures in production
6. **Documentation**: Update user documentation with new error messages

