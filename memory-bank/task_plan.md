# Task Plan

## Goal
Remediate the backup/restore bugs listed in `memory-bank/bugs.md` in sequential order, verifying each fix before moving to the next and updating `memory-bank/progress.md` after each completed bug.

## Current Phase
- Bug 1: Replace hardcoded portable backup key with passphrase-based encryption

## Steps
1. Implement passphrase-based backup encryption while preserving legacy decryption for existing backups.
2. Add/adjust tests for new encryption behavior and restore failure modes.
3. Verify the bug is resolved.
4. Update `memory-bank/progress.md`.
5. Move to Bug 2 and repeat.

## Notes
- User selected Option A: passphrase-based backup encryption.
- Automatic backups must fail gracefully when a passphrase is not configured.
- Legacy V1/V2 backups should remain decryptable where possible.

## Status
- [in_progress] Bug 1
- [pending] Bug 2
- [pending] Bug 3
- [pending] Bug 4
- [pending] Bug 5
- [pending] Bug 6
- [pending] Bug 7
- [pending] Bug 8
- [pending] Bug 9
- [pending] Bug 10
