# Patient Companion App — Tech Stack

## 1. Overview
This document defines the complete technology stack for building a simple, secure, and scalable Patient Companion mobile application.

---

## 2. Frontend (Mobile App)

### Framework
- Flutter (Dart)

### Reasons
- Cross-platform (Android + iOS)
- Fast development
- Strong community support
- Native-like performance

---

## 3. State Management

### Recommended
- Riverpod

### Alternative
- Provider

### Reason
- Scalable and testable state management
- Separation of concerns

---

## 4. Local Database

### Primary Choice
- SQLite (sqflite plugin)

### Reason
- Offline-first capability
- Lightweight and reliable
- Structured data storage

---

## 5. Notifications

### Library
- flutter_local_notifications

### Purpose
- Medicine reminders
- Follow-up alerts

---

## 6. File Handling

### Libraries
- image_picker (camera/gallery)
- file_picker (documents)

### Purpose
- Upload prescriptions and reports

---

## 7. Architecture

### Pattern
- Clean Architecture

### Layers
- Presentation
- Domain
- Data

### Folder Structure
```
/lib
  /core
  /features
  /data
  /domain
  /presentation
```

---

## 8. Security

### Tools
- flutter_secure_storage
- AES encryption (optional layer)

### Purpose
- Secure local data storage
- Protect sensitive medical data

---

## 9. Authentication (Optional for MVP)

### Options
- Firebase Auth (future)
- Phone/Email login

### MVP Approach
- Guest mode (local storage only)

---

## 10. Backend (Post-MVP)

### Recommended Stack
- Node.js (Express) OR Firebase

### Database
- Firestore OR PostgreSQL

### Purpose
- Cloud sync
- Backup & restore
- Multi-device access

---

## 11. Testing

### Tools
- flutter_test
- mocktail

### Types
- Unit tests
- Widget tests

---

## 12. DevOps & Tools

### Version Control
- Git + GitHub

### CI/CD (Optional)
- GitHub Actions

### Build
- Android Studio / VS Code

---

## 13. Performance Considerations

- Lazy loading of data
- Efficient notification scheduling
- Optimized database queries

---

## 14. Scalability Plan

### Phase 1 (MVP)
- Local-only architecture

### Phase 2
- Add backend sync

### Phase 3
- Multi-user & caregiver sharing

---

## 15. Final Notes

- Keep dependencies minimal
- Avoid unnecessary SDKs
- Prioritize reliability over features
