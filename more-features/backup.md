# Google Drive Backup \& Restore Feature — Detailed Implementation Prompt

## Objective

Create a complete Google Drive Backup \& Restore system for the patient medical records mobile app. The implementation must preserve all existing functionality, architecture, database behavior, authentication flow, realtime sync behavior, and UI/UX already present in the application.

The feature must allow users to securely back up and restore their complete app data using their own Google Drive account so that data remains recoverable even after app uninstall or device change.

\---

# Primary Objective

Implement a secure cloud backup and restore mechanism using Google Drive that:

* Lets users manually backup app data to their personal Google Drive
* Lets users restore app data after reinstalling the app
* Supports automatic scheduled backups
* Keeps medical data encrypted and secure
* Does not break existing app workflows
* Works reliably with realtime app updates
* Supports Android first (mandatory)
* iOS support should be architecture-ready if not implemented immediately

\---

# Core Functional Requirements

## 1\. Settings Screen

Create a dedicated Settings / Backup \& Restore screen.

Add the following sections:

### Google Account Section

Show:

* Connected Google account email
* Profile avatar
* Backup connection status

Buttons:

* Connect Google Drive
* Disconnect Google Drive
* Change Account

Behavior:

* Use Google Sign-In
* Request minimum required permissions
* Explain clearly what data is backed up

\---

## 2\. Backup Section

### Manual Backup

Add:

* Backup Now button
* Progress indicator
* Backup status
* Last backup date/time
* Backup size

Behavior:

* Compress and encrypt backup before upload
* Upload to app-specific folder in Google Drive
* Do not expose medical files publicly

Display statuses:

* Backup in progress
* Backup completed
* Backup failed
* No internet
* Google Drive unavailable

\---

## 3\. Automatic Backup

Add toggle:

* Enable Automatic Backup

Options:

* Daily
* Weekly
* Only on WiFi
* Only while charging

Requirements:

* Use background jobs/work manager
* Avoid battery drain
* Retry failed uploads intelligently

\---

## 4\. Restore Section

Add:

* Restore from Backup button
* List available backups
* Show:

  * Backup date
  * Device name
  * App version
  * Backup size

Before restore:

* Warn user existing local data may be overwritten
* Provide:

  * Merge option
  * Replace option

Restore process must:

* Download backup
* Verify integrity
* Decrypt
* Restore database
* Restore uploaded files
* Restore settings/preferences
* Restore followups/reminders

After restore:

* Restart app safely OR reload repositories cleanly

\---

# Data To Include In Backup

## Structured Data

* Patient profiles
* Prescriptions
* Medical reports
* Follow-ups
* Vital signs
* Medicines
* Doctor notes
* App preferences
* Reminder schedules
* Notification settings

\---

## File Data

Include:

* Images
* PDFs
* Attachments
* Scanned reports

Requirements:

* Preserve folder structure
* Maintain file references
* Prevent duplicate restoration

\---

# Technical Requirements

## Backup Format

Use:

* ZIP archive OR encrypted binary package

Recommended structure:

```plaintext
backup/
 ├── metadata.json
 ├── database.db
 ├── files/
 ├── settings.json
 └── checksum.sha256
```

\---

## Metadata

Store:

* App version
* Backup timestamp
* Device info
* Backup schema version
* File count
* Encryption version

\---

# Security Requirements

This part is critical. Weak implementation here is unacceptable.

## Mandatory Security Measures

* Encrypt backup before upload
* Use AES-256 encryption
* Never store plain medical data in Drive
* Use secure key handling
* Avoid hardcoded secrets
* Use Android Keystore for encryption key storage

\---

## Authentication

Use:

* Google Sign-In
* OAuth2
* Google Drive REST API OR Google Drive SDK

Use app-specific storage:

* appDataFolder

This is mandatory because:

* Backup files remain hidden from user’s normal Drive files
* More secure
* Prevent accidental deletion

\---

# Database Handling

The restore system must safely handle database replacement.

Requirements:

* Close DB before restore
* Validate schema compatibility
* Handle migration versions
* Prevent corruption
* Use transaction-safe restore

If backup schema differs:

* Attempt migration
* Show compatibility warning if impossible

\---

# Realtime Sync Compatibility

The app already supports realtime updates.

The backup system must NOT:

* Interrupt realtime listeners
* Cause duplicated entries
* Trigger infinite sync loops
* Corrupt in-memory state

After restore:

* Refresh repositories
* Reinitialize state providers/blocs/viewmodels safely
* Reconnect realtime streams

\---

# UI/UX Requirements

The experience must feel production-grade.

Requirements:

* Clean settings UI
* Material Design 3
* Proper loading indicators
* Snackbar/toast feedback
* Error dialogs
* Restore confirmation dialogs
* Empty states
* Internet connectivity handling

\---

# Error Handling

Handle all edge cases:

* No internet
* Google auth expired
* Storage quota exceeded
* Corrupted backup
* Partial uploads
* Interrupted restore
* App update incompatibility
* Large file uploads
* Duplicate backups

Provide meaningful user-facing messages.

\---

# Performance Requirements

The implementation must:

* Support large backups efficiently
* Use streaming upload/download
* Avoid blocking UI thread
* Use isolates/background workers where appropriate
* Compress files efficiently

\---

# Suggested Tech Stack (Flutter)

## Recommended Packages

* google\_sign\_in
* googleapis
* googleapis\_auth
* workmanager
* path\_provider
* archive
* crypto
* encrypt
* flutter\_secure\_storage

\---

# Architecture Requirements

Feature must follow existing architecture.

Requirements:

* Modular implementation
* Separate backup service layer
* Repository pattern
* Clean state management
* Dependency injection compatible

Suggested modules:

```plaintext
services/
  backup\\\_service.dart
  restore\\\_service.dart
  drive\\\_service.dart
  encryption\\\_service.dart

screens/
  settings/
    backup\\\_settings\\\_screen.dart

models/
  backup\\\_metadata.dart
```

\---

# Restore Safety Flow

Implement safe restore workflow:

1. Validate backup
2. Verify checksum
3. Decrypt
4. Create temporary restore area
5. Validate DB schema
6. Backup current local data temporarily
7. Restore new data
8. Reinitialize app state
9. Cleanup temp files

If restore fails:

* Rollback safely
* Restore previous local state

\---

# Backup Retention

Allow:

* Keep latest X backups
* Auto-delete old backups

Suggested default:

* Keep last 5 backups

\---

# Notifications

Optional but recommended:

* Notify when backup succeeds
* Notify when backup fails
* Notify if backup hasn’t happened for long time

\---

# Developer Expectations

The implementation must include:

* Complete production-ready code
* Proper architecture integration
* Null safety
* Error handling
* Comments/documentation
* Logging
* Unit-testable structure

Do NOT create mock implementations or placeholder logic.

\---

# Deliverables Expected

Generate:

1. Full implementation plan
2. Database backup strategy
3. Google Drive integration layer
4. Encryption workflow
5. Settings screen UI
6. Backup/restore services
7. Background task handling
8. Error handling strategy
9. Migration handling
10. Testing strategy
11. Security best practices
12. Example code snippets where needed

The feature must be implemented in a scalable, production-grade way suitable for handling sensitive medical records securely.

