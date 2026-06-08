# Backup & Restore - Quick Reference & Implementation Guide

## Executive Summary

The Patient App's backup and restore system is well-architected with encryption, Google Drive integration, and rollback capabilities. However, there are **5 critical issues** that could lead to data corruption or loss if not addressed.

**Status**: Ready for implementation
**Estimated Fix Time**: 4-6 hours
**Risk Level**: HIGH (without fixes)

---

## Critical Issues at a Glance

| # | Issue | File | Line | Risk | Fix Time |
|---|-------|------|------|------|----------|
| 1 | No copy verification | restore_service.dart | 205 | 🔴 CRITICAL | 30 min |
| 2 | No disk space check | restore_service.dart | 273 | 🔴 CRITICAL | 45 min |
| 3 | File existence not verified | restore_service.dart | 180 | 🟠 HIGH | 20 min |
| 4 | Column type mismatch | restore_service.dart | 215 | 🟠 HIGH | 30 min |
| 5 | Foreign key violations | restore_service.dart | 211 | 🟠 HIGH | 25 min |

**Total Implementation Time**: ~2.5 hours

---

## File Structure Reference

```
lib/core/services/backup/
├── backup_service.dart              # Main backup orchestration
├── restore_service.dart             # Main restore orchestration ⚠️ FOCUS HERE
├── backup_package_service.dart      # Encryption/packaging
├── backup_crypto_service.dart       # AES-256 encryption
├── backup_drive_service.dart        # Google Drive API
└── backup_scheduler_service.dart    # Scheduled backups

lib/data/datasources/
├── database_helper.dart             # Database connection management
├── database_constants.dart          # Schema definitions
└── migration_manager.dart           # Schema migrations

lib/presentation/screens/
└── backup_settings_screen.dart      # UI for backup/restore
```

---

## Quick Fix Guide

### Fix 1: Database Copy Verification (30 min)

**What**: Verify backup file copy succeeded before reopening database
**Why**: Prevents corrupted database from being used
**Where**: `restore_service.dart`, line 205

**Before**:
```dart
await File(backupDatabasePath).copy(currentPath);
await _databaseHelper.database;
```

**After**:
```dart
final sourceFile = File(backupDatabasePath);
final sourceSize = await sourceFile.length();
final copiedFile = await sourceFile.copy(currentPath);
final copiedSize = await copiedFile.length();

if (sourceSize != copiedSize) {
  throw StateError('Copy verification failed');
}

// Test database integrity
final testDb = await openDatabase(currentPath);
await testDb.rawQuery('SELECT 1');
await testDb.close();

await _databaseHelper.database;
```

**Testing**:
```bash
# Test with corrupted backup
# Test with insufficient permissions
# Test with disk full scenario
```

---

### Fix 2: Disk Space Validation (45 min)

**What**: Check available disk space before creating rollback snapshot
**Why**: Prevents restore failure mid-operation
**Where**: `restore_service.dart`, line 273 (before `_createRollbackSnapshot`)

**Add**:
```dart
// In restoreFromDriveBackup, before _createRollbackSnapshot
final tempDir = await getTemporaryDirectory();
final stat = await tempDir.stat();
final availableSpace = stat.size;

// Calculate needed space
int neededSpace = 0;
final dbFile = File(path.join(await getDatabasesPath(), 'carevault.db'));
if (await dbFile.exists()) {
  neededSpace += await dbFile.length();
}

// Add attachment directories
final appDir = await getApplicationDocumentsDirectory();
for (final dirName in ['prescriptions', 'reports', 'images']) {
  final dir = Directory(path.join(appDir.path, dirName));
  if (await dir.exists()) {
    neededSpace += await _getDirectorySize(dir);
  }
}

// Check with 1.5x safety margin
if (availableSpace < neededSpace * 1.5) {
  throw StateError(
    'Insufficient disk space: need ${neededSpace * 1.5 / 1024 / 1024} MB, '
    'have ${availableSpace / 1024 / 1024} MB'
  );
}
```

**Testing**:
```bash
# Simulate low disk space
# Test with exactly needed space
# Test with 0 free space
```

---

### Fix 3: File Existence Verification (20 min)

**What**: Verify restored files exist before updating database
**Why**: Prevents app crashes when opening non-existent files
**Where**: `restore_service.dart`, lines 180-191

**Before**:
```dart
for (final entry in resolved) {
  final originalPath = entry['originalPath']!;
  final restoredPath = entry['restoredPath']!;
  await db.update(
    DatabaseConstants.tablePrescriptions,
    {DatabaseConstants.columnPrescriptionFilePath: restoredPath},
    where: '${DatabaseConstants.columnPrescriptionFilePath} = ?',
    whereArgs: [originalPath],
  );
}
```

**After**:
```dart
for (final entry in resolved) {
  final originalPath = entry['originalPath']!;
  final restoredPath = entry['restoredPath']!;
  
  // Verify file exists
  if (!await File(restoredPath).exists()) {
    ErrorUtils.logWarning(
      'Restored file not found: $restoredPath',
      tag: 'Restore',
    );
    continue;
  }
  
  await db.update(
    DatabaseConstants.tablePrescriptions,
    {DatabaseConstants.columnPrescriptionFilePath: restoredPath},
    where: '${DatabaseConstants.columnPrescriptionFilePath} = ?',
    whereArgs: [originalPath],
  );
}
```

**Testing**:
```bash
# Test with missing prescription files
# Test with missing report files
# Test with partial file restoration
```

---

### Fix 4: Column Type Validation (30 min)

**What**: Validate column types match before merging
**Why**: Prevents data corruption from type mismatches
**Where**: `restore_service.dart`, lines 215-220

**Add Helper**:
```dart
Future<Map<String, String>> _getColumnTypes(
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
      row['name'] as String: (row['type'] as String).toUpperCase(),
  };
}
```

**Update Merge**:
```dart
final currentTypes = await _getColumnTypes(txn, table);
final backupTypes = await _getColumnTypes(txn, table, schema: 'backup');

final columns = currentColumns
    .where((col) =>
      backupColumns.contains(col) &&
      currentTypes[col] == backupTypes[col]  // Type check added
    )
    .toList(growable: false);
```

**Testing**:
```bash
# Test with schema version mismatch
# Test with column type changes
# Test with new columns in backup
```

---

### Fix 5: Referential Integrity Check (25 min)

**What**: Remove orphaned records after merge
**Why**: Prevents foreign key constraint violations
**Where**: `restore_service.dart`, after `_mergeDatabase`

**Add Method**:
```dart
Future<void> _verifyReferentialIntegrity(Database db) async {
  try {
    // Check for orphaned prescriptions
    final orphaned = await db.rawQuery('''
      SELECT COUNT(*) as count FROM prescriptions p
      WHERE p.medicine_id IS NOT NULL 
      AND NOT EXISTS (SELECT 1 FROM medicines m WHERE m.id = p.medicine_id)
    ''');
    
    final count = Sqflite.firstIntValue(orphaned) ?? 0;
    if (count > 0) {
      await db.delete(
        DatabaseConstants.tablePrescriptions,
        where: 'medicine_id IS NOT NULL AND medicine_id NOT IN '
            '(SELECT id FROM medicines)',
      );
      ErrorUtils.logInfo('Deleted $count orphaned prescriptions', tag: 'Restore');
    }
  } catch (e) {
    ErrorUtils.logWarning('Referential integrity check failed: $e', tag: 'Restore');
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

**Testing**:
```bash
# Test with orphaned prescriptions
# Test with orphaned reminder logs
# Test with mixed valid/invalid records
```

---

## Implementation Workflow

### Step 1: Preparation (15 min)
```bash
# Create feature branch
git checkout -b fix/backup-restore-critical-issues

# Create backup of current file
cp lib/core/services/backup/restore_service.dart \
   lib/core/services/backup/restore_service.dart.backup
```

### Step 2: Implement Fixes (2.5 hours)
1. Fix 1: Database copy verification
2. Fix 2: Disk space validation
3. Fix 3: File existence verification
4. Fix 4: Column type validation
5. Fix 5: Referential integrity check

### Step 3: Testing (1 hour)
```bash
# Run existing tests
flutter test test/backup_package_service_test.dart
flutter test test/backup_drive_service_test.dart

# Run new tests
flutter test test/restore_service_test.dart
```

### Step 4: Integration Testing (1 hour)
- Test with real Google Drive backups
- Test with corrupted backups
- Test with low disk space
- Test with missing files
- Test with schema mismatches

### Step 5: Code Review & Merge (30 min)
```bash
# Create pull request
git push origin fix/backup-restore-critical-issues

# After review and approval
git merge fix/backup-restore-critical-issues
```

---

## Testing Checklist

### Unit Tests
- [ ] Database copy verification works
- [ ] Disk space check prevents restore
- [ ] File existence check skips missing files
- [ ] Column type validation filters incompatible columns
- [ ] Referential integrity removes orphaned records

### Integration Tests
- [ ] Replace mode works with valid backup
- [ ] Merge mode works with valid backup
- [ ] Rollback restores previous state on failure
- [ ] Error messages are user-friendly
- [ ] Restore completes successfully

### Edge Cases
- [ ] Backup with corrupted database
- [ ] Backup with missing files
- [ ] Backup with schema version mismatch
- [ ] Restore with insufficient disk space
- [ ] Restore with permission errors
- [ ] Restore with network interruption
- [ ] Restore with concurrent app usage

### Performance Tests
- [ ] Restore completes in reasonable time
- [ ] Memory usage stays within limits
- [ ] Disk I/O is efficient
- [ ] Database queries are optimized

---

## Error Messages to Update

### Current Messages
```dart
'Restore failed. Your previous local data was kept.'
```

### Improved Messages
```dart
// Specific errors
'Database copy verification failed: file size mismatch'
'Insufficient disk space for restore'
'Restored file not found: /path/to/file'
'Column type mismatch in backup'
'Referential integrity violation detected'

// User-friendly
'Restore failed: Not enough storage space. Free up at least 500 MB and try again.'
'Restore failed: Some files could not be restored. Your data has been preserved.'
'Restore failed: Backup is corrupted. Please try a different backup.'
```

---

## Monitoring & Logging

### Add Logging Points
```dart
// Before restore
ErrorUtils.logInfo('Starting restore: mode=$mode', tag: 'Restore');

// During restore
ErrorUtils.logInfo('Step 1: Downloading backup...', tag: 'Restore');
ErrorUtils.logInfo('Step 2: Decrypting backup...', tag: 'Restore');
ErrorUtils.logInfo('Step 3: Creating rollback snapshot...', tag: 'Restore');
ErrorUtils.logInfo('Step 4: Restoring data...', tag: 'Restore');
ErrorUtils.logInfo('Step 5: Verifying restore...', tag: 'Restore');

// After restore
ErrorUtils.logInfo('Restore completed successfully', tag: 'Restore');
```

### Metrics to Track
- Restore success rate
- Average restore time
- Common failure reasons
- Disk space issues
- File corruption incidents

---

## Deployment Strategy

### Phase 1: Internal Testing (1 week)
- Deploy to internal test devices
- Test all edge cases
- Verify error messages
- Monitor logs

### Phase 2: Beta Release (1 week)
- Deploy to beta testers
- Collect feedback
- Monitor crash reports
- Verify performance

### Phase 3: Production Release (1 week)
- Deploy to production
- Monitor restore operations
- Track error rates
- Be ready to rollback

### Rollback Plan
```bash
# If critical issues found
git revert <commit-hash>
flutter build apk --release
# Deploy previous version
```

---

## Documentation Updates

### User Guide
- [ ] Update restore instructions
- [ ] Add troubleshooting section
- [ ] Document merge vs replace modes
- [ ] Add disk space requirements

### Developer Guide
- [ ] Document restore architecture
- [ ] Add code comments
- [ ] Create restore flow diagram
- [ ] Document error handling

### Release Notes
- [ ] List all fixes
- [ ] Explain improvements
- [ ] Note any behavior changes
- [ ] Provide migration guide

---

## Success Criteria

✅ All 5 critical issues fixed
✅ All unit tests passing
✅ All integration tests passing
✅ No new crashes reported
✅ Restore success rate > 99%
✅ User-friendly error messages
✅ Comprehensive logging
✅ Documentation updated

---

## Timeline

| Phase | Duration | Status |
|-------|----------|--------|
| Analysis | ✅ Complete | Done |
| Fix Implementation | 2.5 hours | Ready |
| Testing | 2 hours | Ready |
| Code Review | 1 hour | Ready |
| Beta Release | 1 week | Planned |
| Production Release | 1 week | Planned |

---

## Contact & Support

**Questions about fixes?**
- Review `BACKUP_RESTORE_TECHNICAL_DEEP_DIVE.md` for detailed analysis
- Review `BACKUP_RESTORE_FIXES.md` for code examples
- Check `BACKUP_RESTORE_ANALYSIS.md` for architecture overview

**Need help implementing?**
- Start with Fix 1 (simplest)
- Follow the code examples provided
- Run tests after each fix
- Commit frequently

**Found issues?**
- Document the issue
- Create test case
- Report with logs
- Provide reproduction steps

---

## Related Files

- `lib/core/services/backup/restore_service.dart` - Main file to modify
- `lib/core/services/backup/backup_service.dart` - Related backup logic
- `lib/data/datasources/database_helper.dart` - Database operations
- `lib/core/utils/error_utils.dart` - Error logging
- `test/backup_package_service_test.dart` - Test reference

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-05-09 | Initial analysis and recommendations |
| 1.1 | TBD | Fixes implemented |
| 1.2 | TBD | Beta testing complete |
| 1.3 | TBD | Production release |

---

## Appendix: Database Schema

### Tables Involved in Restore
- `medicines` - Medicine records
- `prescriptions` - Prescription files
- `test_reports` - Test report files
- `reminder_logs` - Reminder history
- `follow_ups` - Follow-up appointments
- `vital_signs` - Vital sign readings
- `audit_logs` - Audit trail

### Key Columns
- `prescriptions.file_path` - Path to prescription file
- `test_reports.file_path` - Path to test report file
- `medicines.id` - Foreign key reference
- `reminder_logs.medicine_id` - Foreign key reference

---

## Appendix: Encryption Details

**Algorithm**: AES-256-CBC
**Key Size**: 256 bits (32 bytes)
**IV Size**: 128 bits (16 bytes)
**MAC**: HMAC-SHA256 (32 bytes)
**Format**: `[MAGIC(4)] [IV(16)] [CIPHERTEXT] [MAC(32)]`

---

**Document Generated**: 2026-05-09
**Status**: Ready for Implementation
**Priority**: CRITICAL

