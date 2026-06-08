# Findings

## Bug 1 - Backup encryption flaw
- Current V2 encryption uses a constant portable key in `backup_crypto_service.dart`.
- `BackupService` creates automatic backups via `backup_scheduler_service.dart`, so passphrase-based encryption will require handling the no-passphrase background case.
- Existing tests currently assume backups decrypt across installs without user-supplied key material.
- `aes_encryption_service.dart` already contains PBKDF2 helpers that can be reused or mirrored for backup passphrase derivation.
- Need to preserve legacy decryption for existing V1/V2 backups if feasible.
