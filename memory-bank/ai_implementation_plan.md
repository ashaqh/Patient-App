# AI Coding Agent — Phased Implementation Plan
*(Patient Companion App — MVP-first execution)*

---

## Phase 0 — System Setup

### Objective
Create a controlled development environment.

### Tasks
- Stack:
  - Flutter
  - SQLite (sqflite)
  - Riverpod / Provider
- Folder Structure:
```
/lib
  /core
  /features
  /data
  /domain
  /presentation
```

### Output
- Clean, runnable base app

---

## Phase 1 — Core Data Layer

### Objective
Build data models and local storage.

### Features
- Medicine model
- Prescription model
- Reminder log model

### Tasks
- Create models
- Setup SQLite schema
- Implement CRUD

### Output
- Working database layer

---

## Phase 2 — Reminder Engine

### Objective
Reliable notification system.

### Features
- Schedule notifications
- Multiple times/day
- Mark as taken/skipped

### Tasks
- Integrate local notifications
- Build scheduler
- Handle edge cases

### Output
- Functional reminder engine

---

## Phase 3 — Core UI

### Objective
Minimal usable interface.

### Screens
- Dashboard
- Add Medicine
- Medicine List

### Tasks
- Build UI
- Implement interactions

### Output
- Functional UI

---

## Phase 4 — Prescription Upload

### Objective
Document storage.

### Features
- Upload files
- Store locally

### Tasks
- File picker integration
- Storage handling

### Output
- Upload system

---

## Phase 5 — Follow-Up System

### Objective
Track appointments.

### Features
- Add follow-up
- Alerts

### Output
- Reminder system

---

## Phase 6 — Health Timeline

### Objective
History view.

### Features
- Combined timeline

### Output
- Timeline screen

---

## Phase 7 — Stability

### Objective
App reliability.

### Tasks
- Error handling
- Testing

### Output
- Stable app

---

## Phase 8 — Privacy & Security - COMPLETED ✅

### Objective
User trust.

### Features
- ✅ AES-256 encryption for sensitive data
- ✅ App lock with PIN, password, and biometric options
- ✅ Secure storage service for encrypted data
- ✅ Auto-lock timeout configuration
- ✅ Biometric authentication integration

### Output
- Secure app with comprehensive privacy features

---

## Phase 9 — Beta Release - COMPLETED ✅

### Objective
Launch MVP.

### Tasks
- ✅ Build APK - Debug APK successfully built
- ✅ Test - Ready for internal beta testing

### Output
- ✅ Beta version available at `build/app/outputs/flutter-apk/app-debug.apk`

---

## Timeline

| Phase | Duration |
|------|---------|
| Setup | 3–4 days |
| Data Layer | 3–4 days |
| Reminder Engine | 3–5 days |
| UI | 4–6 days |
| Upload + Follow-up | 3–4 days |
| Testing | 4–5 days |

---

## AI Prompt Template

```
You are a senior Flutter developer.

Task:
[ONE task]

Context:
- App: Patient Companion
- Architecture: Clean Architecture
- State: Riverpod
- Storage: SQLite

Constraints:
- Minimal code
- Follow structure

Output:
- Working code
```

---

## Notes

- Avoid feature creep
- Focus on simplicity
- Ship fast, iterate later
