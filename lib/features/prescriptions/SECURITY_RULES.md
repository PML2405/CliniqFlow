# Firestore Security Rules for Prescriptions

## Overview
This document outlines the Firestore security rules required for the prescription management feature.

## Rules

Add the following rules to your `firestore.rules` file:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Prescription Collection Rules
    match /prescriptions/{prescriptionId} {
      
      // Helper function to check if user is authenticated
      function isAuthenticated() {
        return request.auth != null;
      }
      
      // Helper function to check if user is the patient
      function isPatient() {
        return isAuthenticated() && 
               request.auth.uid == resource.data.patientUid;
      }
      
      // Helper function to check if user is a doctor/staff
      // Note: Implement based on your user role system
      function isDoctor() {
        return isAuthenticated() && 
               get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role in ['doctor', 'admin'];
      }
      
      // Helper function to validate prescription data
      function isValidPrescription() {
        return request.resource.data.keys().hasAll([
          'id', 'patientId', 'patientUid', 'patientName', 
          'doctorName', 'prescriptionDate', 'items', 
          'createdAt', 'updatedAt'
        ]) &&
        request.resource.data.id is string &&
        request.resource.data.patientId is string &&
        request.resource.data.patientUid is string &&
        request.resource.data.patientName is string &&
        request.resource.data.doctorName is string &&
        request.resource.data.prescriptionDate is timestamp &&
        request.resource.data.items is list &&
        request.resource.data.items.size() > 0 &&
        request.resource.data.items.size() <= 50 &&
        request.resource.data.createdAt is timestamp &&
        request.resource.data.updatedAt is timestamp;
      }
      
      // Helper function to validate prescription item
      function isValidPrescriptionItem(item) {
        return item.keys().hasAll(['id', 'drugName', 'dosage', 'frequency', 'duration']) &&
               item.id is string &&
               item.drugName is string &&
               item.drugName.size() >= 2 &&
               item.drugName.size() <= 200 &&
               item.dosage is string &&
               item.dosage.size() <= 50 &&
               item.frequency is string &&
               item.frequency.size() <= 100 &&
               item.duration is string &&
               item.duration.size() <= 50 &&
               (!item.keys().hasAny(['notes']) || item.notes is string) &&
               (!item.keys().hasAny(['notes']) || item.notes.size() <= 500);
      }
      
      // Helper function to validate all items
      function hasValidItems() {
        return request.resource.data.items.hasAll(
          request.resource.data.items.map(item => isValidPrescriptionItem(item))
        );
      }
      
      // Read: Allow if user is the patient or a doctor
      allow read: if isPatient() || isDoctor();
      
      // Create: Only doctors can create prescriptions
      allow create: if isDoctor() && 
                       isValidPrescription() &&
                       hasValidItems() &&
                       request.resource.data.createdAt == request.time &&
                       request.resource.data.updatedAt == request.time;
      
      // Update: Only doctors can update, and only the items field
      allow update: if isDoctor() &&
                       isValidPrescription() &&
                       hasValidItems() &&
                       request.resource.data.id == resource.data.id &&
                       request.resource.data.patientId == resource.data.patientId &&
                       request.resource.data.patientUid == resource.data.patientUid &&
                       request.resource.data.createdAt == resource.data.createdAt &&
                       request.resource.data.updatedAt == request.time;
      
      // Delete: Only doctors can delete prescriptions
      allow delete: if isDoctor();
    }
  }
}
```

## Rule Explanations

### Read Access
- **Patients**: Can read their own prescriptions
- **Doctors**: Can read all prescriptions
- **Implementation**: Check `patientUid` matches authenticated user or user has doctor role

### Create Access
- **Who**: Only authenticated doctors
- **Validation**:
  - All required fields present
  - At least 1 medication, max 50 medications
  - Drug name: 2-200 characters
  - Dosage: max 50 characters
  - Frequency: max 100 characters
  - Duration: max 50 characters
  - Notes: optional, max 500 characters
  - Timestamps set to current time

### Update Access
- **Who**: Only authenticated doctors
- **Restrictions**:
  - Cannot change: id, patientId, patientUid, createdAt
  - Can change: items, doctorName, prescriptionDate
  - updatedAt must be current time
  - All validation rules apply

### Delete Access
- **Who**: Only authenticated doctors
- **Use Case**: Remove incorrect or duplicate prescriptions

## Testing Security Rules

### Test Read Access
```javascript
// Test patient can read their own prescription
match /prescriptions/rx123 {
  allow read: if request.auth.uid == 'patient-uid-123';
}

// Test doctor can read any prescription
match /prescriptions/rx123 {
  allow read: if get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'doctor';
}
```

### Test Create Access
```javascript
// Test valid prescription creation
{
  "id": "rx-123",
  "patientId": "patient-123",
  "patientUid": "uid-123",
  "patientName": "John Doe",
  "caseSheetId": "case-123",
  "doctorName": "Dr. Smith",
  "prescriptionDate": Timestamp.now(),
  "items": [
    {
      "id": "item-1",
      "drugName": "Amoxicillin",
      "dosage": "500mg",
      "frequency": "Twice daily",
      "duration": "7 days",
      "notes": "Take with food"
    }
  ],
  "createdAt": Timestamp.now(),
  "updatedAt": Timestamp.now()
}
```

### Test Update Access
```javascript
// Test valid update (changing items)
{
  "items": [
    {
      "id": "item-1",
      "drugName": "Amoxicillin",
      "dosage": "250mg", // Changed dosage
      "frequency": "Three times daily", // Changed frequency
      "duration": "10 days", // Changed duration
      "notes": "Take with food"
    }
  ],
  "updatedAt": Timestamp.now()
}
```

## User Roles

Ensure your user documents have a `role` field:

```javascript
/users/{userId}
{
  "uid": "user-123",
  "email": "doctor@example.com",
  "role": "doctor", // or "admin", "patient", "staff"
  "name": "Dr. Smith",
  // ... other fields
}
```

## Indexes

Create the following composite indexes for optimal query performance:

### Index 1: Patient Prescriptions by Date
- **Collection**: `prescriptions`
- **Fields**:
  - `patientId` (Ascending)
  - `prescriptionDate` (Descending)
- **Query Scope**: Collection

### Index 2: Patient Prescriptions by Creation Date
- **Collection**: `prescriptions`
- **Fields**:
  - `patientUid` (Ascending)
  - `createdAt` (Descending)
- **Query Scope**: Collection

### Index 3: Case Sheet Prescriptions
- **Collection**: `prescriptions`
- **Fields**:
  - `caseSheetId` (Ascending)
  - `prescriptionDate` (Descending)
- **Query Scope**: Collection

## Deployment

1. Update `firestore.rules` file with the prescription rules
2. Deploy rules using Firebase CLI:
   ```bash
   firebase deploy --only firestore:rules
   ```
3. Verify rules in Firebase Console
4. Test with Firebase Emulator Suite before production

## Monitoring

Monitor security rule violations in Firebase Console:
1. Navigate to Firestore → Usage
2. Check for denied requests
3. Review audit logs for suspicious activity

## Best Practices

1. **Principle of Least Privilege**: Only grant necessary permissions
2. **Validate All Input**: Check data types, lengths, and formats
3. **Audit Trail**: Maintain createdAt/updatedAt timestamps
4. **Role-Based Access**: Use user roles for authorization
5. **Test Thoroughly**: Use Firebase Emulator for testing
6. **Monitor Usage**: Track denied requests and errors
7. **Regular Reviews**: Periodically review and update rules

## Troubleshooting

### Permission Denied Errors
- Verify user is authenticated
- Check user role in Firestore
- Validate data structure matches rules
- Check field types and lengths

### Index Errors
- Create required composite indexes
- Wait for index creation to complete
- Verify index configuration

### Validation Errors
- Check all required fields are present
- Verify data types match rules
- Ensure field lengths within limits
- Validate nested objects (items)
