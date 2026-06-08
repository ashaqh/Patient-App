# Backup/Restore Remediation Plan

## Goal
Address all identified backup, restore, privacy, and data-integrity flaws with a staged remediation plan that improves confidentiality, prevents partial restores and data loss, restores settings consistently, and strengthens verification coverage.

## Scope
This plan covers the issues identified in the review for:
- `lib/core/services/backup/backup_crypto_service.dart`
- `lib/core/services/backup/backup_drive_service.dart`
- `lib/core/services/backup/backup_package_service.dart`
- `lib/core/services/backup/backup_service.dart`
- `lib/core/services/backup/restore_service.dart`
- `lib/data/datasources/database_helper.dart`
- related tests and `pubspec.yaml`

---

## 1. Immediate Prioritization

### P0 - Must fix before any production rollout
1. Replace the hardcoded portable backup key design.
2. Prevent partial restore side effects by staging file restore work.
3. Fix merge restore so file references are rewritten in the live database.
4. Make database replacement and rollback atomic.

### P1 - Fix in the same release if possible
5. Restore all backup settings including retention count.
6. Reduce metadata privacy exposure in Drive app properties.
7. Ensure foreign keys are always re-enabled after merge attempts.

### P2 - Cleanup and hardening
8. Move test-only packages out of runtime dependencies.
9. Expand automated regression coverage for backup/restore workflows.
10. Review legacy helper methods marked as simplified implementations.

---

## 2. Root Cause Summary

### 2.1 Backup encryption flaw
**Problem:** Version 2 backup encryption uses a deterministic key derived from a constant string, which makes every backup decryptable by anyone who can reverse engineer the app.

**Root cause:** Security design optimized for portability by removing per-user secret material.

### 2.2 Restore side effects on failure
**Problem:** Restore writes files directly into the live application documents directory before database replacement or merge is confirmed.

**Root cause:** Restore workflow lacks isolation/staging and performs side effects too early.

### 2.3 Merge restore path corruption
**Problem:** Merge mode rewrites file paths only in the extracted backup database, then merges into the live database without a second rewrite pass.

**Root cause:** The merge path does not complete the same path-resolution lifecycle as replace mode.

### 2.4 Non-atomic database replacement
**Problem:** Current restore and rollback delete the active database before copying the replacement file.

**Root cause:** File replacement strategy is destructive instead of transactional.

### 2.5 Incomplete settings restore
**Problem:** `retentionCount` is backed up but not restored.

**Root cause:** Settings restore logic is not aligned with settings serialization logic.

### 2.6 Privacy leakage through Drive metadata
**Problem:** Device info, device name, and notes are stored in Drive app properties outside the encrypted payload.

**Root cause:** Sensitive metadata was treated as operational metadata instead of protected content.

### 2.7 Foreign key integrity risk
**Problem:** Foreign keys are disabled for merge and may remain off if execution exits abnormally.

**Root cause:** Integrity toggling is not protected by `try/finally`.

---

## 3. Remediation Workstreams

## Workstream A - Redesign backup key management

### Objective
Restore real confidentiality for backup files while preserving a usable recovery story.

### Required design decision
Choose one supported key model and document it before implementation:

#### Option A - User passphrase based backups
- Derive the encryption key from a user-supplied passphrase.
- Store only salt, IV, algorithm version, and KDF parameters with the backup.
- Best for portability and zero-knowledge backup confidentiality.
- Requires UX for passphrase setup, confirmation, and recovery warnings.

#### Option B - Random per-user master key with wrapped recovery
- Generate a random master key and store it in secure storage locally.
- For cross-device restore, wrap or escrow the key using a secure recovery flow.
- More convenient than passphrase-only, but requires secure key transport design.

#### Option C - Hybrid model
- Support both local convenience and optional passphrase export/recovery.
- Highest implementation complexity, strongest long-term product fit.

### Recommendation
Adopt **Option A** first for correctness and security clarity:
- easiest model to reason about
- no hidden server-side trust assumptions
- portable across installations
- avoids reintroducing hardcoded or account-derived secrets

### Implementation tasks
- Replace `_portableMasterKey()` with passphrase-based derivation.
- Introduce backup header fields for:
  - encryption version
  - random salt
  - random IV
  - KDF parameters
  - MAC or authenticated mode metadata
- Prefer authenticated encryption such as AES-GCM if the crypto stack supports it safely; otherwise keep encrypt-then-MAC with a strong KDF-derived key split.
- Keep backward compatibility for older backups where feasible:
  - continue decrypt support for existing V1/V2 payloads
  - mark old format as legacy and stop producing it
- Add explicit migration notes for users with old backups.

### Verification
- New backups created on one install cannot be decrypted without the passphrase.
- Same passphrase decrypts backup on another install/device.
- Wrong passphrase fails with a clean, user-safe error.
- Legacy backups continue to decrypt only if backward compatibility is intentionally supported.

---

## Workstream B - Isolate restore into a staging pipeline

### Objective
Ensure a failed restore leaves no partial file system mutations in the live app directory.

### Implementation tasks
- Change `_restoreFiles()` to extract all backup files into a unique staging directory, not the live documents directory.
- Validate file paths while still in staging.
- After database restore/merge and path rewriting succeed, promote staged files into the live documents directory.
- Define promotion behavior explicitly:
  - replace mode: overwrite live files with staged files
  - merge mode: copy only missing files or use deterministic conflict rules
- Track all files introduced during the operation so rollback can delete them if promotion partially completes.
- Delete staging directories after success and after rollback.

### Additional hardening
- Remove the current `if (!await destination.exists())` write guard for replace mode.
- Define merge conflict rules for files with identical target paths.
- Add unique per-run restore temp folders to avoid collisions.

### Verification
- Inject failure after staging but before DB replace: no live files changed.
- Inject failure after some file promotion: rollback restores prior state and removes new files.
- Successful replace restore results in live files matching backup contents exactly.

---

## Workstream C - Correct merge restore file reference handling

### Objective
Ensure merged rows point to valid local file paths after restore.

### Implementation tasks
- Keep the first rewrite pass on the extracted backup DB if it simplifies merge inputs.
- After `_mergeDatabase(...)`, run a second rewrite pass against the live database using the resolved path map.
- Confirm all tables containing file path columns are covered, not just the currently known two, if schema expands later.
- Add assertions or logging for zero-row updates where rows were expected.

### Verification
- Merge a backup created on another device with different original file paths.
- Confirm merged prescription and test report rows resolve to current-device file paths.
- Open restored attachments through UI or integration tests.

---

## Workstream D - Make database replacement and rollback atomic

### Objective
Prevent database loss if restore is interrupted or the process crashes mid-operation.

### Implementation tasks
- Replace delete-then-copy with a safe replace strategy:
  1. close database connection
  2. copy replacement DB to a temporary sibling file
  3. validate temp DB opens successfully
  4. rename current DB to a backup name if present
  5. rename temp DB into place atomically where supported
  6. reopen DB
  7. delete prior backup only after success
- Apply the same strategy to rollback.
- Evaluate handling for SQLite sidecar files (`-wal`, `-shm`, `-journal`) and ensure restore strategy is consistent with the journal mode in use.
- Add low-storage and interrupted-operation safeguards where practical.

### Verification
- Simulate failure between temp copy and final swap: original DB remains intact.
- Simulate failure after backup rename but before reopen: rollback path remains recoverable.
- Reopened database uses the restored content, not a stale handle.

---

## Workstream E - Restore settings completely and consistently

### Objective
Ensure restore preserves the same user-configured backup behavior.

### Implementation tasks
- Add `backup_retention_count` restoration to `_restoreSettings()`.
- Validate numeric bounds for retention count before writing.
- Audit all values in `BackupSettings.toJson()` and confirm each has a matching restore branch.
- Consider centralizing backup settings serialization/deserialization to avoid drift.

### Verification
- Create backup with non-default retention count.
- Restore backup and confirm settings UI shows exact restored values.
- Confirm invalid values are sanitized to safe defaults.

---

## Workstream F - Reduce privacy leakage in Drive metadata

### Objective
Keep sensitive metadata inside the encrypted backup package whenever possible.

### Implementation tasks
- Remove or minimize `deviceInfo` from Drive `appProperties`.
- Remove or minimize `deviceName` from Drive `appProperties`.
- Do not store free-form `notes` in Drive app properties unless there is a documented product requirement and explicit user consent.
- Keep operational metadata in app properties only if needed for listing and selection, for example:
  - backup ID
  - timestamp
  - schema version
  - app version
  - encrypted size
  - encryption version
- Keep sensitive details only in `metadata.json` inside the encrypted payload.
- Update any UI relying on Drive metadata to read sensitive fields after decrypting the selected package.

### Verification
- List Drive backups and inspect stored app properties.
- Confirm no unnecessary personal/device data is exposed there.
- Confirm backup listing UI still works with reduced metadata.

---

## Workstream G - Guarantee foreign key re-enablement

### Objective
Preserve relational integrity even if merge restore fails.

### Implementation tasks
- Wrap the entire foreign-key toggle lifecycle in `try/finally`.
- Re-enable foreign keys in `finally` no matter how merge exits.
- Add a post-merge integrity check if feasible, such as `PRAGMA foreign_key_check` in test environments.

### Verification
- Force a merge failure after foreign keys are disabled.
- Confirm `PRAGMA foreign_keys` returns enabled afterward.
- Confirm subsequent writes still enforce constraints.

---

## Workstream H - Dependency and hygiene cleanup

### Objective
Reduce production dependency surface and align package roles correctly.

### Implementation tasks
- Move `flutter_test`, `flutter_lints`, and `mocktail` under `dev_dependencies`.
- Review whether any other test-only packages are incorrectly declared.
- Run dependency resolution and ensure production builds still succeed.

### Verification
- `flutter pub get` succeeds.
- `flutter analyze` succeeds.
- Tests still run.
- Release build dependency graph no longer includes test packages.

---

## 4. Test Strategy

## 4.1 Regression tests to add

### Crypto tests
- New backup format requires correct passphrase/key material.
- Wrong passphrase fails cleanly.
- Salt/IV differ between two backups of identical content.
- Legacy format decryption behavior is explicitly covered.

### Restore staging tests
- Failure before promotion leaves live files untouched.
- Failure after partial promotion triggers cleanup.
- Replace restore overwrites expected files.
- Merge restore preserves or resolves file conflicts according to policy.

### Path rewrite tests
- Replace mode rewrites live DB file references correctly.
- Merge mode rewrites live DB file references correctly.
- Attachments open from restored rows.

### Atomic replacement tests
- Simulated interruption does not delete the original DB.
- Rollback restores a working database handle.
- Reopen logic points to the new database after success.

### Settings tests
- All serialized backup settings round-trip through backup and restore.
- Invalid retention values are clamped or defaulted.

### Privacy tests
- Drive metadata property map excludes sensitive fields.
- Encrypted package still retains full metadata internally.

### Integrity tests
- Foreign keys are re-enabled after successful merge.
- Foreign keys are re-enabled after failed merge.

## 4.2 Manual verification checklist
- Create backup on device A.
- Restore on fresh install or device B.
- Verify DB records, attachments, and settings.
- Verify merge mode with overlapping data.
- Verify replace mode with existing local files.
- Verify backup listing still works with minimized metadata.
- Verify recovery and rollback behavior under forced failures.

---

## 5. Implementation Order

### Phase 1 - Security and integrity foundation
1. Finalize key-management design decision.
2. Implement secure backup encryption format.
3. Add crypto regression tests.

### Phase 2 - Restore safety
4. Implement staging-based restore pipeline.
5. Implement atomic DB swap and rollback.
6. Add restore failure-path tests.

### Phase 3 - Functional correctness
7. Fix merge path rewriting in the live DB.
8. Restore missing settings fields.
9. Add end-to-end backup/restore tests.

### Phase 4 - Privacy and hygiene
10. Minimize Drive app properties.
11. Move test dependencies to `dev_dependencies`.
12. Update documentation and migration notes.

---

## 6. Documentation Updates Required
- Document the new backup encryption model and its recovery implications.
- Document whether old backups remain supported and for how long.
- Document merge vs replace file conflict behavior.
- Document what metadata is stored in Drive versus only inside the encrypted payload.
- Update user-facing backup/restore help text and warning dialogs.

---

## 7. Release Readiness Criteria
Do not ship the remediation until all of the following are true:
- No hardcoded global backup key remains in active backup creation.
- Failed restores leave no live DB or file system corruption.
- Replace and merge restores both produce valid file references.
- Database replacement and rollback are crash-safe.
- Backup settings restore completely.
- Drive metadata no longer exposes unnecessary sensitive data.
- Foreign keys are always re-enabled after merge attempts.
- Automated tests cover success, failure, rollback, and legacy scenarios.
- `flutter analyze` and targeted restore/backup tests pass.

---

## 8. Recommended Deliverables
- Code changes across backup/restore services and helpers
- New/updated unit and integration tests
- Migration/compatibility note for legacy backups
- Updated internal docs in `memory-bank/`
- Short release checklist for QA covering backup, restore, merge, replace, and rollback scenarios