# Patient Companion App - Architecture Document

## Current Architecture (Phase 1 - Core Data Layer)

### Technology Stack
- **Frontend**: Flutter (Dart)
- **State Management**: Riverpod
- **Local Database**: SQLite (sqflite plugin)
- **File Handling**: image_picker, file_picker
- **Notifications**: flutter_local_notifications (to be implemented in Phase 2)
- **Security**: flutter_secure_storage, custom encryption

### Project Structure
```
lib/
├── core/
│   ├── constants/          # App-wide constants
│   ├── themes/            # Light/dark theme definitions
│   ├── utils/             # Utility classes
│   │   ├── date_time_utils.dart
│   │   ├── encryption_service.dart
│   │   ├── file_utils.dart
│   │   └── validation_utils.dart
│   └── widgets/           # Reusable UI components
│       └── elderly_friendly_button.dart
├── data/
│   ├── datasources/       # Data access layer
│   │   ├── database_constants.dart
│   │   ├── database_helper.dart
│   │   ├── medicine_data_source.dart
│   │   ├── prescription_data_source.dart
│   │   ├── reminder_log_data_source.dart
│   │   ├── follow_up_data_source.dart
│   │   ├── migration_manager.dart
│   │   └── secure_storage_service.dart
│   └── repositories/      # Repository implementations
│       ├── medicine_repository_impl.dart
│       ├── prescription_repository_impl.dart
│       ├── reminder_log_repository_impl.dart
│       └── follow_up_repository_impl.dart
├── domain/
│   ├── entities/          # Business entities
│   │   ├── medicine.dart
│   │   ├── prescription.dart
│   │   ├── reminder_log.dart
│   │   └── follow_up.dart
│   └── repositories/      # Repository interfaces
│       ├── medicine_repository.dart
│       ├── prescription_repository.dart
│       ├── reminder_log_repository.dart
│       └── follow_up_repository.dart
└── presentation/
    ├── providers/         # Riverpod providers
    │   ├── app_provider.dart
    │   └── medicine_provider.dart
    └── screens/          # UI screens
        ├── app.dart
        ├── dashboard_screen.dart
        └── add_medicine_screen.dart
```

### Architecture Principles

#### 1. Clean Architecture
- **Presentation Layer**: UI components, screens, providers
- **Domain Layer**: Business logic, entities, repository interfaces
- **Data Layer**: Data sources, repository implementations, database

#### 2. Dependency Rule
- Outer layers can depend on inner layers
- Inner layers cannot depend on outer layers
- Dependency injection via Riverpod providers

#### 3. Single Responsibility
- Each class has one primary responsibility
- Separation of concerns between data access, business logic, and UI

### Data Flow

```
UI Event → Provider → Repository → Data Source → Database
        ↑          ↓          ↓            ↓
UI Update ← Provider ← Repository ← Data Source
```

### Database Design

#### Medicines Table
```sql
CREATE TABLE medicines (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  dosage TEXT NOT NULL,
  frequency TEXT NOT NULL,
  times TEXT NOT NULL,          -- Comma-separated times (e.g., "08:00,20:00")
  start_date TEXT NOT NULL,
  end_date TEXT,
  notes TEXT,
  instructions TEXT,
  is_active INTEGER NOT NULL DEFAULT 1,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
)
```

#### Prescriptions Table
```sql
CREATE TABLE prescriptions (
  id TEXT PRIMARY KEY,
  file_path TEXT NOT NULL,
  file_name TEXT NOT NULL,
  file_type TEXT NOT NULL,
  date TEXT NOT NULL,
  notes TEXT,
  doctor_name TEXT,
  clinic_name TEXT,
  file_size REAL,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
)
```

#### Reminder Logs Table
```sql
CREATE TABLE reminder_logs (
  id TEXT PRIMARY KEY,
  medicine_id TEXT NOT NULL,
  medicine_name TEXT NOT NULL,
  dosage TEXT NOT NULL,
  scheduled_time TEXT NOT NULL,
  actual_time TEXT,
  status INTEGER NOT NULL,      -- 0: taken, 1: skipped, 2: missed, 3: snoozed, 4: pending
  notes TEXT,
  created_at TEXT NOT NULL
)
```

#### Follow-ups Table
```sql
CREATE TABLE follow_ups (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  date TEXT NOT NULL,
  notes TEXT,
  doctor_name TEXT,
  clinic_name TEXT,
  location TEXT,
  status INTEGER NOT NULL DEFAULT 0,  -- 0: scheduled, 1: completed, 2: cancelled, 3: rescheduled
  completed_at TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
)
```

### State Management with Riverpod

#### Provider Hierarchy
```
databaseHelperProvider
    ↓
medicineRepositoryProvider
    ↓
medicineListProvider (StateNotifierProvider)
    ├── todaysMedicinesProvider (FutureProvider)
    ├── activeMedicinesProvider (FutureProvider)
    └── medicineCountProvider (FutureProvider)
```

#### Provider Types
- **StateNotifierProvider**: For state that changes over time (medicine list)
- **FutureProvider**: For async operations (today's medicines)
- **Provider**: For dependencies and simple values

### Security Considerations

#### 1. Data Encryption
- AES encryption for sensitive data
- Secure key storage using flutter_secure_storage
- Separate encryption keys per data category

#### 2. Database Security
- Local SQLite database (no external access)
- Input validation to prevent SQL injection
- Parameterized queries

#### 3. File Security
- Local file storage only (no cloud upload in MVP)
- File type validation
- Size limits for uploads

### Performance Optimizations

#### 1. Database
- Indexes on frequently queried columns
- Batch operations for multiple inserts/updates
- Lazy loading for large datasets

#### 2. UI
- List virtualization for long lists
- Image caching
- Efficient rebuilds with Consumer widgets

#### 3. Memory
- Dispose controllers and streams properly
- Limit concurrent operations
- Clean up unused resources

### Error Handling Strategy

#### 1. Database Errors
- Transaction rollback on failure
- Migration backup/restore
- Graceful degradation when database unavailable

#### 2. Network Errors (Future)
- Offline-first approach
- Sync queue for pending operations
- Conflict resolution strategies

#### 3. User Input Errors
- Form validation before submission
- Clear error messages
- Input constraints and limits

### Testing Strategy

#### 1. Unit Tests
- Domain entities and business logic
- Repository implementations
- Utility functions

#### 2. Widget Tests
- UI component behavior
- User interactions
- State changes

#### 3. Integration Tests
- End-to-end user flows
- Database operations
- Provider state management

### Scalability Considerations

#### 1. Current (Phase 1 - MVP)
- Local-only architecture
- Single user per device
- Basic CRUD operations

#### 2. Future (Phase 2+)
- Cloud sync for multi-device access
- Family/caregiver sharing
- Analytics and reporting
- AI prescription parsing

### Deployment Considerations

#### 1. Platform Support
- Android (primary target)
- iOS (secondary target)
- Web/Desktop (optional)

#### 2. App Store Requirements
- Privacy policy
- Data usage disclosure
- Accessibility features
- Minimum OS version support

#### 3. Update Strategy
- Database migration scripts
- Backward compatibility
- User data preservation

This architecture provides a solid foundation for the Patient Companion App with clear separation of concerns, robust data management, and scalability for future features.