# Increment 3: Offline Support & Security Configuration

## Offline Persistence

### Firestore Offline Persistence
**Status**: ✅ Enabled

Firestore offline persistence is enabled in `lib/main.dart`:

```dart
final firestore = FirebaseFirestore.instance;
firestore.settings = const Settings(persistenceEnabled: true);
```

**What this provides**:
- Automatic caching of all Firestore documents accessed by the app
- Read operations work offline using cached data
- Write operations are queued and synced when connectivity returns
- Applies to all collections: `patients`, `appointments`, and `case_sheets`

### Firebase Storage Offline Behavior
**Status**: ⚠️ Limited (by design)

Firebase Storage does **not** provide automatic offline persistence like Firestore. Attachments uploaded to Storage:
- **Uploads**: Queued locally and uploaded when connectivity returns (handled by Firebase SDK)
- **Downloads**: Not cached automatically; require network access

**Recommendation for future enhancement**:
- Implement local caching layer for frequently accessed attachments
- Store attachment metadata in Firestore (already done via `CaseSheetAttachment`)
- Consider using Flutter's `path_provider` + `sqflite` for local file caching if offline attachment viewing becomes critical

### Case Sheet Repository Offline Behavior
The `FirestoreCaseSheetRepository` leverages Firestore's built-in offline support:

1. **Reading case sheets**: Works offline using cached data from `watchByPatient()` stream
2. **Creating case sheets**: Queued locally, synced on reconnection
3. **Recording consent**: Queued as Firestore update, synced on reconnection
4. **Uploading attachments**: 
   - File bytes uploaded to Storage (queued by Firebase SDK)
   - Attachment metadata written to Firestore (queued and synced)

## Security Rules

### Firestore Security Rules
**File**: `firestore.rules`

```firestore
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {
    // Patients collection
    match /patients/{patientId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }

    // Appointments collection
    match /appointments/{appointmentId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }

    // Case sheets collection
    match /case_sheets/{caseSheetId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null
                    && request.resource.data.patientId is string
                    && request.resource.data.appointmentId is string
                    && request.resource.data.doctorInCharge is string;
      allow update: if request.auth != null
                    && resource.data.patientId == request.resource.data.patientId;
      allow delete: if false; // Case sheets should not be deleted
    }

    // Deny all other collections by default
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

**Key security features**:
- All operations require authentication (`request.auth != null`)
- Case sheet creation validates required fields
- Case sheet updates prevent changing `patientId` (immutable link)
- Case sheet deletion is explicitly blocked (audit trail preservation)
- Default deny for unlisted collections

### Firebase Storage Security Rules
**File**: `storage.rules`

```storage
rules_version = '2';

service firebase.storage {
  match /b/{bucket}/o {
    // Case sheet attachments: /case_sheets/{caseSheetId}/{fileName}
    match /case_sheets/{caseSheetId}/{fileName} {
      allow read: if request.auth != null;
      allow write: if request.auth != null
                   && request.resource.size < 10 * 1024 * 1024
                   && request.resource.contentType.matches('image/.*|application/pdf|text/.*');
    }
    
    // Deny all other paths by default
    match /{allPaths=**} {
      allow read, write: if false;
    }
  }
}
```

**Key security features**:
- All operations require authentication
- File size limited to 10MB per attachment
- Content type restricted to images, PDFs, and text files
- Storage path structure enforced: `/case_sheets/{caseSheetId}/{fileName}`
- Default deny for unlisted paths

## Deployment Instructions

### Deploy Firestore Rules
```bash
firebase deploy --only firestore:rules
```

### Deploy Storage Rules
```bash
firebase deploy --only storage
```

### Deploy Both
```bash
firebase deploy --only firestore:rules,storage
```

## Testing Offline Behavior

### Manual Testing Steps
1. **Enable offline mode**:
   - Disconnect network or enable airplane mode
   
2. **Test read operations**:
   - Navigate to patient directory → should display cached patients
   - Open case sheets for a patient → should display cached case sheets
   - View appointment details → should display cached appointments

3. **Test write operations**:
   - Create a new case sheet → should queue locally
   - Record consent → should queue locally
   - Upload attachment → should queue locally
   
4. **Re-enable connectivity**:
   - Reconnect network
   - Verify queued operations sync automatically
   - Check Firebase Console to confirm data arrived

### Automated Testing
Current test suite (`flutter test`) uses mock repositories and does not exercise actual Firebase offline behavior. For integration testing with real Firebase offline persistence:
- Use `firebase_emulator_suite` for local testing
- Write integration tests with `flutter_test` + `firebase_core`
- Test scenarios: offline writes, reconnection sync, conflict resolution

## Known Limitations

1. **Attachment downloads**: Require network connectivity; no automatic caching
2. **Large attachments**: 10MB limit enforced by Storage rules
3. **Conflict resolution**: Firestore uses last-write-wins; no custom merge logic
4. **Storage quota**: Offline persistence uses device storage; monitor cache size in production

## Future Enhancements

1. **Attachment caching**: Implement local file cache for viewed attachments
2. **Sync indicators**: Add UI feedback for pending offline operations
3. **Conflict UI**: Notify users of sync conflicts and allow manual resolution
4. **Selective sync**: Allow users to control which case sheets are cached offline
5. **Attachment compression**: Reduce upload size for images before Storage upload
