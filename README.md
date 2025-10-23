# CliniqFlow

A Flutter application for clinical visit management with offline support.

## Getting Started

### Prerequisites

- Flutter SDK (3.9.2 or higher)
- Firebase CLI
- Android Studio / Xcode (for mobile development)

### Firebase Configuration

**Important**: Firebase configuration files are not included in the repository for security reasons.

Run the automated setup script:

```bash
./scripts/setup_firebase.sh
```

This script will:
- Check for Firebase CLI installation
- Install Firebase CLI if necessary
- Authenticate with Firebase
- Download Android and iOS configuration files
- Verify the downloaded files

For detailed instructions, see [Firebase Setup Guide](./docs/firebase_setup.md).

### Installation

1. Clone the repository
2. Download Firebase configuration files (see above)
3. Install dependencies:
   ```bash
   flutter pub get
   ```
4. Run the app:
   ```bash
   flutter run
   ```

## Features

- **Patient Management**: Create and manage patient records
- **Appointment Scheduling**: Schedule and track appointments
- **Case Sheets**: Clinical visit documentation with attachments
- **Offline Support**: Works without internet connection
- **Firebase Authentication**: Email/password and Google Sign-In
- **Cloud Storage**: Secure file attachments with Firebase Storage

## Documentation

- [Firebase Setup](./docs/firebase_setup.md)
- [Offline Support](./docs/increment3_offline_support.md)
- [Validation Checklist](./docs/increment3_validation_checklist.md)

## Testing

Run tests:
```bash
flutter test
```

Run analysis:
```bash
flutter analyze
```

## Project Structure

```
lib/
├── core/              # Shared utilities and widgets
├── features/          # Feature modules
│   ├── appointments/  # Appointment scheduling
│   ├── auth/          # Authentication
│   ├── case_sheets/   # Clinical visit management
│   ├── home/          # Home navigation
│   ├── patients/      # Patient directory
│   └── settings/      # App settings
└── main.dart          # App entry point
```