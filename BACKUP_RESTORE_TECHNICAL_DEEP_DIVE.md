# Backup & Restore - Technical Deep Dive

## Replace Method Implementation Analysis

### Current Implementation (restore_service.dart, lines 199-207)

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

### Execution Flow

1. **Close Current Database**
   - Closes all connections to current database
   - Ensures no locks on the file
   - State: `_database = null` in DatabaseHelper

2. **Get Current Database Path**
   - Uses `getDatabasesPath()` from `path_provider`
   - Joins with `DatabaseConstants.databaseName` ("carevault.db")
   - Result: `/data/data/com.example.carevault/databases/carevault.db`

3. **Copy Backup to Current Location**
   - Source: `backupDatabasePath` (temporary restore directory)
   - Destination: Current database path
   - Operation: File system copy (atomic on most systems)

4. **Reopen Database**
   - Calls `_databaseHelper.database` getter
   - Triggers `_initDatabase()` in DatabaseHelper
   - Initializes new connection with current database file

### Potential Issues

#### Issue 1: No Copy Verification
**Severity**: HIGH
**Problem**: File copy may fail silently or partially
**Scenario**: 
- Disk space exhausted during copy
- File permissions changed
- Destination file locked by another process

**Current Code**:
```dart
await File(backupDatabasePath).copy(currentPath);
// No verification that copy succeeded
```

**Impact**: Database file may be corrupted or incomplete, app crashes on next access

**Fix**:
```dart
Future<void> _replaceDatabase(String backupDatabasePath) async {
  await _databaseHelper.close();
  final currentPath = path.join(
    await getDatabasesPath(),
    DatabaseConstants.databaseName,
  );
  
  // Verify source exists and is readable
  final sourceFile = File(backupDatabasePath);
  if (!await sourceFile.exists()) {
    throw StateError('Backup database file not found');
  }
  
  final sourceSize = await sourceFile.length();
  if (sourceSize == 0) {
    throw StateError('Backup database is empty');
  }
  
  // Perform copy with verification
  final destFile = await sourceFile.copy(currentPath);
  
  // Verify copy succeeded
  final destSize = await destFile.length();
  if (sourceSize != destSize) {
    throw StateError(
      'Database copy verification failed: '
      'expected $sourceSize bytes, got $destSize bytes'
    );
  }
  
  // Verify database integrity
  try {
    await _databaseHelper.database;
  } catch (e) {
    // Restore from rollback if available
    rethrow;
  }
}
```

#### Issue 2: Race Condition on Database Reopen
**Severity**: MEDIUM
**Problem**: Database reopened immediately after copy
**Scenario**:
- File system hasn't flushed write buffers
- SQLite WAL (Write-Ahead Logging) files not properly synced
- Connection pool still has stale references

**Current Code**:
```dart
await File(backupDatabasePath).copy(currentPath);
await _databaseHelper.database;  // Immediate reopen
```

**Impact**: Database may be in inconsistent state, queries fail

**Fix**:
```dart
await File(backupDatabasePath).copy(currentPath);

// Ensure file is synced to disk
final destFile = File(currentPath);
await destFile.stat();  // Force OS to sync

// Small delay for file system consistency
await Future.delayed(const Duration(milliseconds: 100));

// Reopen with retry logic
int retries = 3;
while (retries > 0) {
  try {
    await _databaseHelper.database;
    break;
  } catch (e) {
    retries--;
    if (retries == 0) rethrow;
    await Future.delayed(const Duration(milliseconds: 200));
  }
}
```

#### Issue 3: No Rollback on Failure
**Severity**: HIGH
**Problem**: If database reopen fails, no automatic rollback
**Scenario**:
- Copy succeeds but database is corrupted
- Reopen fails with database error
- User loses both backup and current data

**Current Code**:
```dart
// No try-catch, no rollback
await File(backupDatabasePath).copy(currentPath);
await _databaseHelper.database;
```

**Impact**: Data loss, app in broken state

**Fix**: Already partially handled by `restoreFromDriveBackup()` which calls `_createRollbackSnapshot()` before restore. However, `_replaceDatabase()` should verify success:

```dart
Future<void> _replaceDatabase(String backupDatabasePath) async {
  await _databaseHelper.close();
  final currentPath = path.join(
    await getDatabasesPath(),
    DatabaseConstants.databaseName,
  );
  
  try {
    // Backup current file before replacing
    final currentFile = File(currentPath);
    final backupPath = '$currentPath.pre_restore_backup';
    if (await currentFile.exists()) {
      await currentFile.copy(backupPath);
    }
    
    // Perform copy
    await File(backupDatabasePath).copy(currentPath);
    
    // Verify database
    final db = await _databaseHelper.database;
    await db.rawQuery('SELECT 1');  // Test query
    
  } catch (e) {
    // Attempt to restore from backup
    final backupPath = '$currentPath.pre_restore_backup';
    final backupFile = File(backupPath);
    if (await backupFile.exists()) {
      await backupFile.copy(currentPath);
      await _databaseHelper.database;
    }
    rethrow;
  }
}
```

---

## Merge Method Implementation Analysis

### Current Implementation (restore_service.dart, lines 209-233)

```dart
Future<void> _mergeDatabase(String backupDatabasePath) async {
  final db = await _databaseHelper.database;
  await db.execute('PRAGMA foreign_keys = OFF');
  await db.transaction((txn) async {
    await txn.execute('ATTACH DATABASE ? AS backup', [backupDatabasePath]);
    try {
      for (final table in _mergeTables) {
        final currentColumns = await _columns(txn, table);
        final backupColumns = await _columns(txn, table, schema: 'backup');
        final columns = currentColumns
            .where(backupColumns.contains)
            .toList(growable: false);
        if (columns.isEmpty) continue;
        final columnSql = columns.map(_quoteIdentifier).join(', ');
        await txn.execute(
          'INSERT OR REPLACE INTO ${_quoteIdentifier(table)} ($columnSql) '
          'SELECT $columnSql FROM backup.${_quoteIdentifier(table)}',
        );
      }
    } finally {
      await txn.execute('DETACH DATABASE backup');
    }
  });
  await db.execute('PRAGMA foreign_keys = ON');
}
```

### Execution Flow

1. **Get Database Connection**
   - Opens connection to current database
   - Keeps connection open for entire merge

2. **Disable Foreign Keys**
   - `PRAGMA foreign_keys = OFF`
   - Allows inserting records without constraint violations
   - Critical for merge to work

3. **Start Transaction**
   - All operations atomic
   - Rollback on any error

4. **Attach Backup Database**
   - Opens backup as read-only schema "backup"
   - Allows cross-database queries

5. **For Each Merge Table**
   - Get columns from current table
   - Get columns from backup table
   - Find intersection (columns in both)
   - Execute `INSERT OR REPLACE` for matching columns

6. **Detach Backup Database**
   - In finally block (always executes)
   - Ensures cleanup even on error

7. **Re-enable Foreign Keys**
   - `PRAGMA foreign_keys = ON`
   - Restores constraint checking

### Merge Tables (Line 398-406)

```dart
static const _mergeTables = [
  DatabaseConstants.tableMedicines,
  DatabaseConstants.tablePrescriptions,
  DatabaseConstants.tableTestReports,
  DatabaseConstants.tableReminderLogs,
  DatabaseConstants.tableFollowUps,
  DatabaseConstants.tableVitalSigns,
  DatabaseConstants.tableAuditLogs,
];
```

**NOT merged**: `tableDatabaseChanges`

### Column Intersection Logic (Lines 235-245)

```dart
Future<List<String>> _columns(
  Transaction txn,
  String table, {
  String? schema,
}) async {
  final pragma = schema == null
      ? 'PRAGMA table_info(${_quoteIdentifier(table)})'
      : 'PRAGMA ${_quoteIdentifier(schema)}.table_info(${_quoteIdentifier(table)})';
  final rows = await txn.rawQuery(pragma);
  return rows.map((row) => row['name'] as String).toList(growable: false);
}
```

**Purpose**: Get all column names from a table
**Returns**: List of column names in order

### INSERT OR REPLACE Strategy

```dart
'INSERT OR REPLACE INTO ${_quoteIdentifier(table)} ($columnSql) '
'SELECT $columnSql FROM backup.${_quoteIdentifier(table)}'
```

**Behavior**:
- If record with same PRIMARY KEY exists: UPDATE
- If record doesn't exist: INSERT
- Only affects columns in intersection

**Example**:
```sql
-- If medicines table has columns: id, name, dosage, frequency, created_at, updated_at
-- And backup has: id, name, dosage, frequency, created_at, updated_at, last_modified
-- Intersection: id, name, dosage, frequency, created_at, updated_at

INSERT OR REPLACE INTO medicines (id, name, dosage, frequency, created_at, updated_at)
SELECT id, name, dosage, frequency, created_at, updated_at FROM backup.medicines
```

### Potential Issues

#### Issue 1: Missing Tables in Backup
**Severity**: MEDIUM
**Problem**: Backup may not have all tables (older app version)
**Scenario**:
- Backup created with app v5
- Current app is v7
- New tables added in v6 and v7

**Current Code**:
```dart
for (final table in _mergeTables) {
  final currentColumns = await _columns(txn, table);
  final backupColumns = await _columns(txn, table, schema: 'backup');
  // If table doesn't exist in backup, _columns returns empty list
  // Then columns.isEmpty check skips it
}
```

**Impact**: No error, but silently skips missing tables (acceptable)

**Verification**: Works correctly because:
- `PRAGMA table_info()` returns empty list for non-existent table
- `columns.isEmpty` check skips the merge
- No exception thrown

#### Issue 2: Column Type Mismatches
**Severity**: MEDIUM
**Problem**: Column types may differ between versions
**Scenario**:
- Backup has `dosage TEXT`
- Current has `dosage REAL`
- Merge inserts TEXT into REAL column

**Current Code**:
```dart
// No type checking, just column name matching
final columns = currentColumns
    .where(backupColumns.contains)
    .toList(growable: false);
```

**Impact**: SQLite type coercion may cause data loss or corruption

**Fix**:
```dart
Future<Map<String, String>> _columnTypes(
  Transaction txn,
  String table, {
  String? schema,
}) async {
  final pragma = schema == null
      ? 'PRAGMA table_info(${_quoteIdentifier(table)})'
      : 'PRAGMA ${_quoteIdentifier(schema)}.table_info(${_quoteIdentifier(table)})';
  final rows = await txn.rawQuery(pragma);
  return {
    for (final row in rows)
      row['name'] as String: row['type'] as String,
  };
}

// In merge loop:
final currentTypes = await _columnTypes(txn, table);
final backupTypes = await _columnTypes(txn, table, schema: 'backup');
final columns = currentColumns
    .where((col) => 
      backupColumns.contains(col) && 
      currentTypes[col] == backupTypes[col]
    )
    .toList(growable: false);
```

#### Issue 3: Foreign Key Constraint Violations
**Severity**: HIGH
**Problem**: Backup records may reference non-existent parent records
**Scenario**:
- Backup has prescription with medicine_id = "123"
- Current database doesn't have medicine "123"
- Foreign key constraint violated

**Current Code**:
```dart
await db.execute('PRAGMA foreign_keys = OFF');
// Merge happens here
await db.execute('PRAGMA foreign_keys = ON');
```

**Impact**: Foreign keys disabled during merge, but re-enabled after. If orphaned records exist, subsequent operations fail.

**Fix**:
```dart
// After merge, verify referential integrity
Future<void> _verifyReferentialIntegrity(Database db) async {
  // Check for orphaned prescriptions
  final orphanedPrescriptions = await db.rawQuery('''
    SELECT p.id FROM prescriptions p
    LEFT JOIN medicines m ON p.medicine_id = m.id
    WHERE p.medicine_id IS NOT NULL AND m.id IS NULL
  ''');
  
  if (orphanedPrescriptions.isNotEmpty) {
    // Log warning or delete orphaned records
    await db.delete(
      DatabaseConstants.tablePrescriptions,
      where: 'id IN (${orphanedPrescriptions.map((_) => '?').join(',')})',
      whereArgs: orphanedPrescriptions.map((r) => r['id']).toList(),
    );
  }
}
```

#### Issue 4: Audit Logs Merge
**Severity**: LOW
**Problem**: Audit logs included in merge but may cause confusion
**Scenario**:
- Backup has audit log: "User deleted medicine X at 2026-05-01"
- Current has audit log: "User added medicine Y at 2026-05-09"
- After merge, both logs present but out of context

**Current Code**:
```dart
static const _mergeTables = [
  // ...
  DatabaseConstants.tableAuditLogs,  // Included
];
```

**Impact**: Audit trail becomes confusing, timestamps don't match actions

**Recommendation**: Consider excluding audit logs from merge:
```dart
static const _mergeTables = [
  DatabaseConstants.tableMedicines,
  DatabaseConstants.tablePrescriptions,
  DatabaseConstants.tableTestReports,
  DatabaseConstants.tableReminderLogs,
  DatabaseConstants.tableFollowUps,
  DatabaseConstants.tableVitalSigns,
  // Removed: DatabaseConstants.tableAuditLogs,
];
```

---

## File Reference Rewriting

### Implementation (Lines 150-197)

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
    for (final entry in resolved) {
      final originalPath = entry['originalPath']!;
      final restoredPath = entry['restoredPath']!;
      await db.update(
        DatabaseConstants.tablePrescriptions,
        {DatabaseConstants.columnPrescriptionFilePath: restoredPath},
        where: '${DatabaseConstants.columnPrescriptionFilePath} = ?',
        whereArgs: [originalPath],
      );
      await db.update(
        DatabaseConstants.tableTestReports,
        {DatabaseConstants.columnTestReportFilePath: restoredPath},
        where: '${DatabaseConstants.columnTestReportFilePath} = ?',
        whereArgs: [originalPath],
      );
    }
  } finally {
    await db.close();
  }
  return resolved;
}
```

### Path Resolution Logic

**Input Manifest Entry**:
```json
{
  "originalPath": "/data/data/com.example.carevault/files/prescriptions/report.pdf",
  "relativePath": "files/prescriptions/report.pdf"
}
```

**Resolution Process**:
1. Get app documents directory: `/data/data/com.example.carevault/files`
2. Remove `files/` prefix from relativePath: `prescriptions/report.pdf`
3. Join: `/data/data/com.example.carevault/files/prescriptions/report.pdf`

**Result**:
```json
{
  "originalPath": "/data/data/com.example.carevault/files/prescriptions/report.pdf",
  "relativePath": "files/prescriptions/report.pdf",
  "restoredPath": "/data/data/com.example.carevault/files/prescriptions/report.pdf"
}
```

### Potential Issues

#### Issue 1: File Existence Not Verified
**Severity**: MEDIUM
**Problem**: Database updated even if file doesn't exist
**Scenario**:
- Manifest lists file that wasn't restored
- Database points to non-existent file
- App crashes when trying to open file

**Current Code**:
```dart
// No check if file exists
await db.update(
  DatabaseConstants.tablePrescriptions,
  {DatabaseConstants.columnPrescriptionFilePath: restoredPath},
  where: '${DatabaseConstants.columnPrescriptionFilePath} = ?',
  whereArgs: [originalPath],
);
```

**Fix**:
```dart
for (final entry in resolved) {
  final originalPath = entry['originalPath']!;
  final restoredPath = entry['restoredPath']!;
  
  // Verify file exists before updating database
  if (!await File(restoredPath).exists()) {
    ErrorUtils.logWarning(
      'Restored file not found: $restoredPath',
      tag: 'Restore',
    );
    continue;  // Skip this entry
  }
  
  await db.update(
    DatabaseConstants.tablePrescriptions,
    {DatabaseConstants.columnPrescriptionFilePath: restoredPath},
    where: '${DatabaseConstants.columnPrescriptionFilePath} = ?',
    whereArgs: [originalPath],
  );
  // ... similar for test reports
}
```

#### Issue 2: Path Separator Issues
**Severity**: LOW
**Problem**: Windows vs Unix path separators
**Scenario**:
- Backup created on Windows: `files\prescriptions\report.pdf`
- Restored on Android: `files/prescriptions/report.pdf`
- Path mismatch

**Current Code**:
```dart
entry['relativePath']!.replaceFirst(
  RegExp(r'^files[/\\]'),  // Handles both separators
  '',
)
```

**Status**: Already handled correctly with regex `[/\\]`

---

## Rollback Mechanism

### Snapshot Creation (Lines 273-308)

```dart
Future<Directory> _createRollbackSnapshot() async {
  await _databaseHelper.close();
  final tempDir = await getTemporaryDirectory();
  final rollbackDir = Directory(
    path.join(tempDir.path, 'carevault_restore_rollback'),
  );
  if (await rollbackDir.exists()) {
    await rollbackDir.delete(recursive: true);
  }
  await rollbackDir.create(recursive: true);

  final currentDbPath = path.join(
    await getDatabasesPath(),
    DatabaseConstants.databaseName,
  );
  final currentDbFile = File(currentDbPath);
  if (await currentDbFile.exists()) {
    await currentDbFile.copy(path.join(rollbackDir.path, 'database.db'));
  }

  final appDir = await getApplicationDocumentsDirectory();
  for (final dirName in [
    AppConstants.prescriptionsDirectory,
    AppConstants.reportsDirectory,
    AppConstants.imagesDirectory,
  ]) {
    final source = Directory(path.join(appDir.path, dirName));
    if (await source.exists()) {
      await _copyDirectory(
        source,
        Directory(path.join(rollbackDir.path, dirName)),
      );
    }
  }
  return rollbackDir;
}
```

### Rollback Execution (Lines 310-335)

```dart
Future<void> _rollback(Directory rollbackDir) async {
  await _databaseHelper.close();
  final dbBackup = File(path.join(rollbackDir.path, 'database.db'));
  if (await dbBackup.exists()) {
    final currentDbPath = path.join(
      await getDatabasesPath(),
      DatabaseConstants.databaseName,
    );
    await dbBackup.copy(currentDbPath);
  }

  final appDir = await getApplicationDocumentsDirectory();
  for (final dirName in [
    AppConstants.prescriptionsDirectory,
    AppConstants.reportsDirectory,
    AppConstants.imagesDirectory,
  ]) {
    final source = Directory(path.join(rollbackDir.path, dirName));
    if (await source.exists()) {
      await _copyDirectory(
        source,
        Directory(path.join(appDir.path, dirName)),
      );
    }
  }
}
```

### Potential Issues

#### Issue 1: Rollback Directory Cleanup
**Severity**: LOW
**Problem**: Rollback directory deleted even on success
**Location**: Lines 71-72
```dart
if (rollbackDir != null && await rollbackDir.exists()) {
  await rollbackDir.delete(recursive: true);
}
```

**Impact**: No way to recover if restore succeeds but causes issues later

**Recommendation**: Keep rollback for 24 hours:
```dart
// In finally block
if (rollbackDir != null && await rollbackDir.exists()) {
  // Mark with timestamp instead of immediate delete
  final markerFile = File(
    path.join(rollbackDir.path, '.restore_timestamp')
  );
  await markerFile.writeAsString(DateTime.now().toIso8601String());
  
  // Schedule cleanup after 24 hours
  // (implement via background task)
}
```

#### Issue 2: Disk Space for Rollback
**Severity**: HIGH
**Problem**: Rollback requires 2x database size
**Scenario**:
- Database: 500 MB
- Rollback snapshot: 500 MB
- Total needed: 1 GB
- Device has 800 MB free
- Restore fails

**Current Code**: No disk space check

**Fix**:
```dart
Future<Directory> _createRollbackSnapshot() async {
  // Check available disk space
  final tempDir = await getTemporaryDirectory();
  final stat = await tempDir.stat();
  final availableSpace = stat.size;
  
  final dbPath = path.join(
    await getDatabasesPath(),
    DatabaseConstants.databaseName,
  );
  final dbSize = await File(dbPath).length();
  
  // Estimate total space needed (2x for safety)
  if (availableSpace < dbSize * 2) {
    throw StateError(
      'Insufficient disk space for restore. '
      'Need ${(dbSize * 2 / 1024 / 1024).toStringAsFixed(1)} MB, '
      'have ${(availableSpace / 1024 / 1024).toStringAsFixed(1)} MB'
    );
  }
  
  // ... rest of snapshot creation
}
```

---

## Summary of Critical Findings

| Issue | Severity | Location | Impact |
|-------|----------|----------|--------|
| No copy verification | HIGH | Line 205 | Data corruption |
| No rollback on failure | HIGH | Line 199-207 | Data loss |
| Missing disk space check | HIGH | Line 273 | Restore failure |
| Column type mismatches | MEDIUM | Line 215-220 | Data corruption |
| Foreign key violations | HIGH | Line 211 | Referential integrity |
| File existence not verified | MEDIUM | Line 180-191 | App crashes |
| Race condition on reopen | MEDIUM | Line 206 | Database inconsistency |
| Audit logs in merge | LOW | Line 406 | Confusing audit trail |

