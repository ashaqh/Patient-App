# Patient Companion App — Product Requirements Document (PRD)

## 1. Product Overview

### 1.1 Product Name (Working)
CareVault (placeholder)

### 1.2 Vision
To provide a simple, secure, and trustworthy mobile application that helps patients and caregivers manage prescriptions, medications, and follow-ups without confusion or complexity.

### 1.3 Mission
Eliminate missed doses, lost prescriptions, and forgotten follow-ups through a minimal, elderly-friendly digital health companion.

---

## 2. Problem Statement

Patients—especially elderly and chronic care patients—face:
- Missed medication doses due to lack of reminders
- Scattered prescriptions (paper, WhatsApp, files)
- No centralized medical history
- Missed follow-up visits
- Difficulty using complex health apps

---

## 3. Goals & Objectives

### 3.1 Primary Goals
- Improve medication adherence
- Provide centralized access to medical records
- Ensure timely follow-ups

### 3.2 Success Metrics (KPIs)
- Daily Active Users (DAU)
- Reminder adherence rate (% of reminders acknowledged)
- 7-day & 30-day retention
- Number of prescriptions uploaded per user
- Follow-up reminders completed

---

## 4. Target Users

### 4.1 Primary Users
- Elderly patients (50+)
- Chronic disease patients (diabetes, BP, heart)

### 4.2 Secondary Users
- Caregivers (family members managing patient health)

---

## 5. Core Principles (Non-Negotiable)

- Simplicity over features
- Privacy-first (no ads, no data selling)
- Offline-first functionality
- Minimal input, maximum clarity
- Large, readable UI for elderly users

---

## 6. MVP Scope

### 6.1 Must-Have Features

#### 6.1.1 Prescription Upload
- Upload via camera or file (PDF/image)
- Tag with:
  - Doctor name (optional)
  - Date
  - Notes

#### 6.1.2 Medicine Reminder System
- Add medicine manually:
  - Name
  - Dosage
  - Frequency (once, twice, custom)
  - Time(s)
- Reminder notifications:
  - Persistent alerts
  - Snooze option
- Mark as:
  - Taken
  - Skipped

#### 6.1.3 Daily Dashboard
- “Today’s Medicines” list
- Clear visual indicators:
  - Pending
  - Taken
  - Missed

#### 6.1.4 Follow-Up Reminder
- Add follow-up date
- Notification 1 day before + same day

#### 6.1.5 Health Timeline
- Chronological view:
  - Prescriptions
  - Medicines
  - Follow-ups

---

## 7. User Experience (UX)

### 7.1 Design Principles
- Large buttons
- High contrast UI
- Minimal text per screen
- No clutter
- One action per screen

---

## 8. Functional Requirements

### 8.1 Authentication
- Optional login (phone/email)
- Allow guest mode (local storage)

### 8.2 Notifications
- Local notifications (offline support)
- Reliable scheduling

### 8.3 Data Storage
- Local database (primary)
- Optional cloud sync (future)

### 8.4 Security
- Data encryption (at rest)
- Secure storage APIs
- No third-party data sharing

---

## 9. Non-Functional Requirements

- Performance: App load < 2 seconds
- Reliability: Reminders must not fail
- Usability: Elderly-friendly UI
- Security: Encrypted local storage
- Offline Support: Full functionality without internet

---

## 10. Technical Architecture (Suggested)

### 10.1 Frontend
- Flutter / React Native

### 10.2 Backend (Optional for MVP)
- None (local-first)

### 10.3 Storage
- SQLite / Room DB

---

## 11. Data Model (Simplified)

### Medicine
- id
- name
- dosage
- frequency
- time[]
- start_date
- end_date

### Prescription
- id
- file_path
- date
- notes

### Reminder Log
- id
- medicine_id
- status (taken/skipped)
- timestamp

---

## 12. Privacy & Compliance

- No data selling
- No ads in MVP
- Clear privacy policy
- User data ownership

---

## 13. Risks & Mitigation

- Low retention → Keep UX simple
- Notification failure → Use reliable schedulers
- Trust issues → Transparent privacy messaging
- Feature creep → Strict MVP scope

---

## 14. Roadmap (30-Day Execution)

### Week 1
- UI wireframes
- Data model design

### Week 2
- Core features:
  - Medicine reminders
  - Dashboard

### Week 3
- Prescription upload
- Follow-up reminders

### Week 4
- Testing
- Bug fixing
- Beta release

---

## 15. Future Expansion

- Family/caregiver access
- Doctor integration
- Health analytics
- AI prescription parsing

---

## 16. Final Notes

This product will succeed only if:
- It remains simple
- It avoids feature bloat
- It builds trust through privacy
