# Backup & Restore Functionality Analysis

## Overview
The Patient App implements a comprehensive backup and restore system with Google Drive integration, encryption, and support for both merge and replace restore modes.

---

## Architecture

### Core Services

#### 1. **BackupService** (`backup_service.dart`)
- **Location**: `lib/core/services/backup/backup_service.dart`
- **Responsibility**: Orchestrates backup creation and upload to Google Drive
- **Key Methods**:
  - `createAndUploadBackup()` - Creates encrypted backup package and uploads to Drive
  - `getAvailableBackups()` - Lists backups from Google Drive
  - `downloadBackup()` - Downloads backup file from Drive
  - `getSettings()` / `saveSettings()` - Manages backup preferences
  - `connectGoogleDrive()` / `disconnectGoogleDrive()` - Account management

#### 2. **RestoreService** (`restore_service.dart`)
- **Location**: `lib/core/services/backup/restore_service.dart`
- **Responsibility**: Handles backup restoration with two modes
- **Key Methods**:
  - `restoreFromDriveBackup(driveFileId, mode)` - Main restore entry point
  - `_restoreArchive()` - Orchestrates restore process
  - `_replaceDatabase()` - Replace mode implementation (line 199)
  - `_mergeDatabase()` - Merge mode implementation (line 209)
  - `_rewriteFileReferences()` - Updates file paths in database
  - `_createRollbackSnapshot()` - Creates backup before restore
  - `_rollback()` - Restores previous state on failure

#### 3. **BackupPackageService** (`backup_package_service.dart`)
- **Location**: `lib/core/services/backup/backup_package_service.dart`
- **Responsibility**: Handles encryption, packaging, and validation
- **Key Methods**:
  - `createEncryptedPackage()` - Creates encrypted ZIP archive
  - `decryptPackage()` - Decrypts and validates backup
  - `readMetadata()` - Extracts backup metadata
  - `readFileManifest()` - Reads file path mappings
  - `validateArchive()` - Verifies backup integrity

#### 4. **BackupCryptoService** (`backup_crypto_service.dart`)
- **Location**: `lib/core/services/backup/backup_crypto_service.dart`
- **Responsibility**: Encryption/decryption with AES-256
- **Key Methods**:
  - `encryptBytes()` - Encrypts with AES-256-CBC + HMAC
  - `decryptBytes()` - Decrypts and verifies integrity
  - Uses secure key storage via `FlutterSecureStorage`

#### 5. **BackupDriveService** (`backup_drive_service.dart`)
- **Location**: `lib/core/services/backup/backup_drive_service.dart`
- **Responsibility**: Google Drive API integration
- **Key Methods**:
  - `signIn()` / `signOut()` - OAuth authentication
  - `uploadBackup()` - Uploads encrypted package to Drive
  - `downloadBackup()` - Downloads backup file
  - `listBackups()` - Lists available backups

---

## Database Structure

### Tables Involved in Restore
Located in `lib/data/datasources/database_constants.dart`:

```dart
static const String tableMedicines = 'medicines';
static const String tablePrescriptions = 'prescriptions';
static const String tableTestReports = 'test_reports';
static const String tableReminderLogs = 'reminder_logs';
static const String tableFollowUps = 'follow_ups';
static const String tableVitalSigns = 'vital_signs';
static const String tableAuditLogs = 'audit_logs';
static const String tableDatabaseChanges = 'database_changes';
```

### Merge Tables (RestoreService line 398-406)
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

**Note**: `tableDatabaseChanges` is NOT included in merge operations.

---

## Restore Flow

### RestoreMode Enum
```dart
enum RestoreMode { merge, replace }
```

### Replace Mode Flow (Line 90-100)
```dart
case RestoreMode.replace:
  await _replaceDatabase(backupDb.path);
  await _rewriteFileReferences(
    databasePath: path.join(
      await getDatabasesPath(),
      DatabaseConstants.databaseName,
    ),
    manifest: pathMap,
    alreadyResolved: true,
  );
  break;
```

**Steps**:
1. Close current database
2. Copy backup database to current location
3. Reopen database
4. Rewrite file references with resolved paths

### Merge Mode Flow (Line 101-104)
```dart
case RestoreMode.merge:
  await _mergeDatabase(backupDb.path);
  break;
```

**Steps**:
1. Attach backup database as "backup" schema
2. For each table in `_mergeTables`:
   - Get column intersection between current and backup
   - Execute `INSERT OR REPLACE` to merge records
3. Detach backup database

---

## Key Implementation Details

### 1. Replace Database (Line 199-207)
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

**Issues Identified**:
- ✅ Closes database before replacement
- ✅ Uses `File.copy()` for atomic operation
- ✅ Reopens database after copy
- ⚠️ No explicit error handling for file copy failures
- ⚠️ No verification that copy succeeded before reopening

### 2. Merge Database (Line 209-233)
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

**Features**:
- ✅ Disables foreign key constraints during merge
- ✅ Uses transaction for atomicity
- ✅ Handles schema differences (column intersection)
- ✅ Uses `INSERT OR REPLACE` for conflict resolution
- ✅ Properly detaches database in finally block
- ✅ Re-enables foreign keys after merge

### 3. File Reference Rewriting (Line 150-197)
```dart
Future<List<Map<String, String>>> _rewriteFileReferences({
  required String databasePath,
  required List<Map<String, String>> manifest,
  bool alreadyResolved = false,
}) async {
  // Maps old file paths to new restored paths
  // Updates prescriptions and test_reports tables
  // Returns resolved manifest for next phase
}
```

**Updates**:
- `prescriptions.file_path`
- `test_reports.file_path`

### 4. Rollback Mechanism (Line 273-335)
```dart
Future<Directory> _createRollbackSnapshot() async {
  // Creates temp directory with:
  // - Current database copy
  // - Copies of: prescriptions/, reports/, images/ directories
}

Future<void> _rollback(Directory rollbackDir) async {
  // Restores database and directories from snapshot
}
```

**Directories Backed Up**:
- `AppConstants.prescriptionsDirectory`
- `AppConstants.reportsDirectory`
- `AppConstants.imagesDirectory`

---

## Backup Package Structure

### Archive Contents
Created by `BackupPackageService.createEncryptedPackage()`:

```
backup.cvbackup (encrypted ZIP)
├── metadata.json          # Backup metadata
├── database.db            # SQLite database
├── settings.json          # App settings
├── file_manifest.json     # File path mappings
├── checksum.sha256        # Archive integrity hash
└── files/
    ├── prescriptions/     # Prescription files
    ├── reports/           # Test report files
    └── images/            # Image files
```

### Metadata Structure
```dart
class BackupMetadata {
  final String id;
  final String appVersion;
  final DateTime backupTimestamp;
  final String deviceInfo;
  final int schemaVersion;
  final int fileCount;
  final int encryptionVersion;
  final int backupSize;
  final String? deviceName;
  final String? notes;
}
```

### Encryption Details
- **Algorithm**: AES-256-CBC
- **Key Derivation**: SHA-256 based
- **Integrity**: HMAC-SHA256
- **Format**: `[MAGIC(4)] [IV(16)] [CIPHERTEXT] [MAC(32)]`
- **Magic**: `0x43 0x56 0x42 0x31` (CVB1)

---

## UI Integration

### BackupSettingsScreen (`backup_settings_screen.dart`)
- **Location**: `lib/presentation/screens/backup_settings_screen.dart`
- **Restore Trigger**: Line 441
  ```dart
  final result = await _restoreService.restoreFromDriveBackup(
    backup.id,
    mode: mode,
  );
  ```

### Restore Mode Selection (Line 414-437)
User chooses between:
- **Merge**: Combines records by ID
- **Replace**: Overwrites local data completely

### State Refresh After Restore (Line 453-474)
Invalidates all Riverpod providers:
- `medicineListProvider`
- `prescriptionListProvider`
- `testReportListProvider`
- `followUpListProvider`
- `vitalSignListProvider`
- `reminderProvider`
- `timelineListProvider`

---

## Error Handling

### RestoreResult
```dart
class RestoreResult {
  final bool success;
  final String message;
}
```

### Error Messages (Line 346-360)
```dart
String _friendlyRestoreError(Object error) {
  if (message.contains('integrity') || 
      message.contains('checksum') || 
      message.contains('format')) {
    return 'This backup is corrupted or was modified.';
  }
  if (message.contains('schema')) {
    return 'This backup was created by a newer app version...';
  }
  if (message.contains('sign') || message.contains('auth')) {
    return 'Google Drive authorization expired...';
  }
  return 'Restore failed. Your previous local data was kept.';
}
```

### Validation (Line 157-184)
```dart
void validateArchive(Archive archive) {
  // Checks for required files
  // Verifies checksum integrity
  // Throws FormatException on failure
}
```

---

## Potential Issues & Recommendations

### 1. **Replace Mode - File Copy Verification**
**Issue**: No verification that file copy succeeded
**Location**: Line 205
```dart
await File(backupDatabasePath).copy(currentPath);
```
**Recommendation**: Add file size verification
```dart
final copiedFile = await File(backupDatabasePath).copy(currentPath);
final originalSize = await File(backupDatabasePath).length();
final copiedSize = await copiedFile.length();
if (originalSize != copiedSize) {
  throw StateError('Database copy verification failed');
}
```

### 2. **Merge Mode - Missing Tables**
**Issue**: `tableAuditLogs` is in `_mergeTables` but may not exist in older backups
**Location**: Line 398-406
**Recommendation**: Add try-catch for each table merge

### 3. **Database Connection State**
**Issue**: Database reopened immediately after copy in replace mode
**Location**: Line 206
```dart
await _databaseHelper.database;
```
**Recommendation**: Add small delay or explicit connection verification

### 4. **File Path Resolution**
**Issue**: Assumes all files exist in manifest
**Location**: Line 143-145
**Recommendation**: Add existence check before updating database

### 5. **Rollback Cleanup**
**Issue**: Rollback directory deleted even if restore succeeds
**Location**: Line 71-72
**Recommendation**: Only delete on success, preserve on failure for debugging

---

## Testing Coverage

### Test Files
- `test/backup_drive_service_test.dart` - Drive service tests
- `test/backup_package_service_test.dart` - Package encryption tests
- `test/backup_metadata_test.dart` - Metadata tests

### Test Gaps
- ❌ No restore mode tests (merge vs replace)
- ❌ No file reference rewriting tests
- ❌ No rollback mechanism tests
- ❌ No database corruption recovery tests

---

## Security Considerations

### ✅ Implemented
- AES-256 encryption for backups
- HMAC integrity verification
- Secure key storage via `FlutterSecureStorage`
- Constant-time comparison for MAC verification
- Foreign key constraint management during merge

### ⚠️ Recommendations
- Add backup file size limits
- Implement backup expiration policy
- Add audit logging for restore operations
- Verify backup schema version compatibility
- Add rate limiting for restore attempts

---

## File Locations Summary

| Component | Path |
|-----------|------|
| Backup Service | `lib/core/services/backup/backup_service.dart` |
| Restore Service | `lib/core/services/backup/restore_service.dart` |
| Package Service | `lib/core/services/backup/backup_package_service.dart` |
| Crypto Service | `lib/core/services/backup/backup_crypto_service.dart` |
| Drive Service | `lib/core/services/backup/backup_drive_service.dart` |
| Database Helper | `lib/data/datasources/database_helper.dart` |
| Database Constants | `lib/data/datasources/database_constants.dart` |
| UI Screen | `lib/presentation/screens/backup_settings_screen.dart` |
| Metadata Model | `lib/core/models/backup_metadata.dart` |

---

## Key Methods Reference

### RestoreService Critical Methods
| Method | Line | Purpose |
|--------|------|---------|
| `restoreFromDriveBackup()` | 40 | Main entry point |
| `_restoreArchive()` | 77 | Orchestrates restore |
| `_replaceDatabase()` | 199 | Replace mode |
| `_mergeDatabase()` | 209 | Merge mode |
| `_rewriteFileReferences()` | 150 | Update file paths |
| `_createRollbackSnapshot()` | 273 | Backup current state |
| `_rollback()` | 310 | Restore on failure |

---

## Database Version
Current: **7** (from `database_constants.dart` line 4)

Schema validation ensures backups from newer app versions are rejected.
