# CliniqFlow Increment 1 Follow-up Actions

## Immediate
- **[Restart Flutter app]**: Stop any running `flutter run` session and launch again so the client reconnects to Firestore with the newly deployed development rules.
- **[Record dev rules usage]**: `firestore.rules` currently allows unrestricted access. Track that this is temporary and should never ship to production.

## Short Term
- **[Design secure Firestore rules]**: Replace `allow read, write: if true;` in `firestore.rules` with authentication-aware logic (for example, require `request.auth != null` and validate document structure for the `patients` collection).
- **[Add authentication flow]**: Update the Flutter app (see `lib/features/patients/data/patient_repository.dart` and associated UI) to sign users in before accessing Firestore, so the secure rules can rely on `request.auth`.
- **[Document setup steps]**: Capture the Firebase project ID (`cliniqflow-cd4a7`), Firestore region (`asia-south1`), and deployment commands (`firebase deploy --only firestore:rules`) in onboarding docs.

## Long Term
- **[Review security & privacy]**: As Increment 4 approaches, audit Firestore indexes, offline persistence, and access control to ensure compliance with clinic data regulations.
- **[Automate checks]**: Consider adding CI steps (e.g., `flutter analyze`, `firebase deploy --only firestore:rules --dry-run`) and integration tests covering the patient CRUD workflow.
