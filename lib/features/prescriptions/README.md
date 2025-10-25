# Prescription Management Feature

## Overview
The Prescription Management feature enables healthcare providers to create, manage, and share digital prescriptions for patients. This feature integrates seamlessly with the Case Sheet system and provides professional PDF generation capabilities.

## Architecture

### Data Layer
- **Models**: `Prescription` and `PrescriptionItem` with Firestore serialization
- **Repository**: `PrescriptionRepository` interface with `FirestorePrescriptionRepository` implementation
- **Firestore Collection**: `prescriptions`

### Business Logic Layer
- **Controller**: `PrescriptionController` manages state and coordinates data operations
- **PDF Service**: `PrescriptionPdfService` generates professional PDF documents

### Presentation Layer
- **PrescriptionFormPage**: Create and edit prescriptions
- **PrescriptionListPage**: View prescription history
- **Integration**: "Create Prescription" button in Case Sheet details

## Features

### 1. Prescription Creation
- Multi-drug prescription support
- Dynamic form with add/remove medications
- Required fields: Doctor name, prescription date, drug details
- Optional fields: Notes for each medication
- Link to case sheet (optional)

### 2. Prescription Management
- View all prescriptions for a patient
- Edit existing prescriptions
- Delete prescriptions with confirmation
- Search and filter capabilities

### 3. PDF Generation
- Professional clinic header
- Patient information section
- Medication table with dosage, frequency, duration
- Doctor signature area
- Generation timestamp

### 4. Print & Share
- Direct printing from app
- Share as PDF via native share sheet
- Temporary file management

## Data Model

### Prescription
```dart
class Prescription {
  final String id;
  final String patientId;
  final String patientUid;
  final String patientName;
  final String? caseSheetId;
  final String doctorName;
  final DateTime prescriptionDate;
  final List<PrescriptionItem> items;
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

### PrescriptionItem
```dart
class PrescriptionItem {
  final String id;
  final String drugName;
  final String dosage;
  final String frequency;
  final String duration;
  final String? notes;
}
```

## Validation Rules

### Doctor Name
- Required
- Minimum: 3 characters
- Maximum: 100 characters

### Drug Name
- Required
- Minimum: 2 characters
- Maximum: 200 characters
- Auto-capitalized

### Dosage
- Required
- Maximum: 50 characters

### Frequency
- Required
- Maximum: 100 characters
- Sentence case

### Duration
- Required
- Maximum: 50 characters

### Notes
- Optional
- Maximum: 500 characters
- Multi-line (3 lines)
- Sentence case

## Usage

### Creating a Prescription from Case Sheet
```dart
// Navigate to prescription form from case sheet
Navigator.of(context).push(
  MaterialPageRoute(
    builder: (context) => PrescriptionFormPage(
      controller: prescriptionController,
      patient: patient,
      caseSheetId: caseSheet.id,
    ),
  ),
);
```

### Viewing Prescription History
```dart
// Navigate to prescription list
Navigator.of(context).push(
  MaterialPageRoute(
    builder: (context) => PrescriptionListPage(
      controller: prescriptionController,
      patient: patient,
    ),
  ),
);
```

### Generating PDF
```dart
final pdfService = PrescriptionPdfService();
final pdfBytes = await pdfService.generatePrescriptionPdf(prescription);
```

### Printing
```dart
await Printing.layoutPdf(
  onLayout: (format) async => pdfBytes,
);
```

### Sharing
```dart
final tempDir = await getTemporaryDirectory();
final file = File('${tempDir.path}/prescription.pdf');
await file.writeAsBytes(pdfBytes);

await Share.shareXFiles(
  [XFile(file.path)],
  subject: 'Prescription for ${prescription.patientName}',
);
```

## Dependencies

### Production
- `pdf: ^3.11.1` - PDF generation
- `printing: ^5.13.1` - Print functionality
- `share_plus: ^10.0.0` - Share functionality
- `intl: ^0.20.2` - Date formatting
- `uuid: ^4.5.1` - Unique ID generation
- `path_provider: ^2.1.5` - Temporary file storage

### Development
- `fake_cloud_firestore: ^2.5.2` - Firestore mocking for tests

## Testing

### Unit Tests
- Model serialization/deserialization
- Repository CRUD operations
- Controller state management

### Widget Tests
- Form validation
- List rendering
- Empty/error states
- User interactions

### Integration Tests
- End-to-end prescription creation
- PDF generation workflow
- Print and share operations

## Security Considerations

### Input Validation
- All fields have length constraints
- Required field validation
- Sanitized user input

### Data Access
- Firestore security rules enforce patient-doctor relationships
- Only authorized users can create/modify prescriptions
- Audit trail with createdAt/updatedAt timestamps

### PDF Security
- Temporary files cleaned up after sharing
- No sensitive data in file names
- Secure file storage paths

## Error Handling

### Network Errors
- Graceful degradation with error messages
- Retry mechanisms for failed operations
- User-friendly error feedback

### Validation Errors
- Real-time form validation
- Clear error messages
- Field-level error display

### PDF Generation Errors
- Loading states during generation
- Error messages for failures
- Fallback mechanisms

## Performance Optimizations

### Lazy Loading
- Prescriptions loaded on-demand
- Pagination support in repository

### Caching
- Controller maintains in-memory cache
- Reduces Firestore reads

### PDF Generation
- Async generation with loading indicator
- Efficient memory management
- Temporary file cleanup

## Future Enhancements

### Planned Features
1. E-prescription integration
2. Drug interaction warnings
3. Prescription templates
4. Medication reminders
5. Prescription analytics
6. Multi-language support
7. Digital signatures
8. QR code for verification

### Technical Improvements
1. Offline support
2. Background PDF generation
3. Batch operations
4. Advanced search/filter
5. Export to other formats
6. Cloud storage integration

## Troubleshooting

### Common Issues

**Issue**: PDF generation fails
- **Solution**: Check printing package permissions, verify PDF service initialization

**Issue**: Share not working
- **Solution**: Verify path_provider permissions, check temporary directory access

**Issue**: Prescriptions not loading
- **Solution**: Check Firestore connection, verify security rules, check patient ID

**Issue**: Form validation errors
- **Solution**: Verify all required fields, check character limits

## Contributing

When contributing to this feature:
1. Follow existing code patterns
2. Add tests for new functionality
3. Update documentation
4. Run `flutter analyze` and `flutter test`
5. Test on multiple devices/screen sizes

## License
Part of CliniqFlow - Dental Clinic Management System
