# CliniqFlow Increment 1 Follow-up Actions

## Long Term
- **[Review security & privacy]**: As Increment 4 approaches, audit Firestore indexes, offline persistence, and access control to ensure compliance with clinic data regulations.
- **[Automate checks]**: Consider adding CI steps (e.g., `flutter analyze`, `firebase deploy --only firestore:rules --dry-run`) and integration tests covering the patient CRUD workflow.

## Increment 2 – Scheduling Follow-ups
- **[Hook up status filter UI]**: Expose the new `AppointmentScheduleController.setStatusFilter()` capability in `appointment_schedule_page.dart` so users can view scheduled/completed/canceled subsets.
- **[Extend controller tests]**: Add coverage for `nextFilteredAppointment`, cancellation pathways, and conflict detection to solidify the TDD baseline.
- **[Add widget tests]**: Introduce widget-level tests for `_DailySummary` and `_ScheduleSliver` to ensure Material 3 UI reacts correctly to controller state.
- **[Enhance filtering UX]**: Provide quick chips or segmented controls for common filters to reduce taps on mobile.
- **[Persist filter selection]**: Consider storing `statusFilter` in `SharedPreferences` so clinicians resume the same view next launch.
