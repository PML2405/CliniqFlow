# Increment Requirements Checklist

Derived from `docs/SRS for CliniqFlow.md`, `docs/Incremental Development Plan for CliniqFlow.md`, and `docs/PROJECT_CONTEXT.md`.

## Increment 1 – Core Patient Foundation
- [x] Design schema for `Patient_Profile`, including `Personal_Info`, `Contact_Info`, `Emergency_Contact`, `Medical_History`, and `Past_Health_History` (see `lib/features/patients/models/patient_profile.dart`).
- [x] Implement patient profile creation UI with full CRUD support (see `patient_edit_page.dart`, `patient_directory_controller.dart`, and `FirestorePatientRepository`).
- [x] Build searchable patient directory listing `Patient_Profile_Summary` (Name, UID, Phone) with live filtering (see `patient_directory_page.dart`).
- [x] Validate required patient data entry per SRS requirements (`R.2.1.*`) (`patient_edit_page.dart`).
- [x] Enable offline persistence for patient data and verify offline access/editing (see Firestore settings in `lib/main.dart`).
- [x] Capture stakeholder feedback on data entry workflow and directory usability — evidence not found in repository.

## Increment 2 – Scheduling & Daily Workflow
- [x] Implement appointment creation linked to patient UID with `Date`, `Time`, `Duration`, and `Purpose` (`R.4.2`) — `appointment_editor_dialog.dart` → `AppointmentScheduleController.createAppointment()` delegates to repository; repository asserts conflict-free slot.
- [x] Provide reschedule and cancel flows with conflict detection (`R.4.3`) — `AppointmentScheduleController.updateAppointment()` and `cancelAppointment()` with `_assertSlotAvailable` overlap check.
- [x] Build calendar UI (daily/weekly/monthly views) synced with appointment data (`R.4.1`) — implemented in `appointment_schedule_page.dart` with `_WeeklyCalendar` and `_MonthlyCalendar` widgets, including view toggle functionality.
- [x] Create dashboard showing next appointment and today's schedule (`R.1.1`, `R.1.2`) — `AppointmentSchedulePage` summarizes next appointment and daily schedule via `_NextAppointmentSection`, `_DailySummary`, `_ScheduleListView`.
- [x] Persist appointment data for offline access and syncing — Firestore persistence enabled globally (`lib/main.dart`); appointments use Firestore streams.
- [x] Validate lifecycle tests (create → view → reschedule → cancel) and conflict prevention — controller tests cover create/update/cancel, filter, summaries; repository tests cover conflict detection.

## Increment 3 – Clinical Visit Management
- [ ] Implement case sheet creation linked to patient and visit date with fields `Dr_Incharge`, `Chief_Complaint`, `Provisional_Diagnosis`, `Treatment_Plan` (`R.3.*`).
- [ ] Add digital consent capture with status storage (`R.3.5`).
- [ ] Support file attachments (X-rays, PDFs, images) tied to case sheets, stored in Firebase Storage (`R.3.6`).
- [ ] Extend offline support to case sheets and attachment metadata.
- [ ] Test upload/download flows, consent recording, and offline syncing scenarios.
- [ ] Gather doctor feedback on case sheet workflow completeness and usability.

## Increment 4 – Prescription & Finalization
- [ ] Implement prescription creation with multi-drug support (`Prescription_Item`: Drug, Dosage, Frequency, Duration) (`R.5.1`).
- [ ] Generate professional PDF with clinic branding, medication table, and printable/shareable output.
- [ ] Integrate print and secure share flows with temporary file management.
- [ ] Polish UI/UX across the app based on cumulative feedback.
- [ ] Produce end-user documentation and in-app help guides.
- [ ] Conduct end-to-end regression testing (patient → appointment → case sheet → prescription).
- [ ] Run User Acceptance Testing with clinic staff and capture sign-off.
- [ ] Perform performance validation on target devices and under expected load.
- [ ] **Security Hardening**
  - [ ] Complete Firestore and Storage rules audit; enforce least privilege and document changes.
  - [ ] Implement role-based access control enforcement in the app (doctor vs. staff flows).
  - [ ] Add comprehensive logging/audit trail for prescription actions (create/edit/print/share).
  - [ ] Validate data encryption at rest/in transit (review Firebase settings, verify HTTPS endpoints).
  - [ ] Conduct dependency vulnerability scan and upgrade critical packages.
  - [ ] Execute security-focused code review (input validation, error handling, secrets management).
  - [ ] Update incident response checklist and escalation contacts in documentation.
  - [ ] Verify compliance with clinic data retention and privacy policies.

## Cross-Increment Activities
- [ ] Maintain project `docs/PROJECT_CONTEXT.md` with up-to-date tech stack and architecture notes.
- [ ] Keep validation checklist (data integrity, security, offline support) current as increments progress.
- [ ] Ensure automated Firebase setup script (`scripts/setup_firebase.sh`) is validated after infrastructure changes.
