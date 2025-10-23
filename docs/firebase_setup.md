# Firebase Configuration Setup

This document explains how to set up Firebase configuration files for the CliniqFlow application.

## Overview

The Firebase configuration files (`google-services.json` for Android and `GoogleService-Info.plist` for iOS) are **not committed to the repository** for security reasons. You need to download them using the Firebase CLI.

## Prerequisites

1. **Firebase CLI installed**: Ensure you have the Firebase CLI installed
   ```bash
   npm install -g firebase-tools
   ```

2. **Authenticated with Firebase**: Log in to Firebase
   ```bash
   firebase login
   ```

3. **Project access**: Ensure you have access to the `cliniqflow-cd4a7` Firebase project

## Download Configuration Files

### Option 0: Using Automated Setup Script (Easiest)

We provide an automated bash script that handles the entire setup process:

```bash
./scripts/setup_firebase.sh
```

**What the script does:**
1. Checks if Firebase CLI is installed
2. Installs Firebase CLI if needed (requires npm)
3. Prompts you to log in to Firebase
4. Downloads Android configuration
5. Downloads iOS configuration
6. Verifies both files

**Requirements:**
- Bash shell (macOS, Linux, or WSL on Windows)
- npm (for Firebase CLI installation)
- Firebase project access

**Usage:**
```bash
# Make the script executable (first time only)
chmod +x scripts/setup_firebase.sh

# Run the script
./scripts/setup_firebase.sh
```

The script is interactive and will guide you through each step with clear prompts and colored output.

### Option 1: Using Firebase CLI (Recommended)

Run these commands from the project root directory:

#### For Android:
```bash
firebase apps:sdkconfig android > android/app/google-services.json
```

#### For iOS:
```bash
firebase apps:sdkconfig ios > ios/Runner/GoogleService-Info.plist
```

### Option 2: Download from Firebase Console

#### For Android:
1. Go to [Firebase Console](https://console.firebase.google.com/project/cliniqflow-cd4a7/settings/general)
2. Scroll to **"Your apps"** section
3. Find the **Android app** (`com.example.cliniqflow`)
4. Click the **gear icon** → **Download google-services.json**
5. Save it to: `android/app/google-services.json`

#### For iOS:
1. Go to [Firebase Console](https://console.firebase.google.com/project/cliniqflow-cd4a7/settings/general)
2. Scroll to **"Your apps"** section
3. Find the **iOS app** (`com.example.cliniqflow`)
4. Click the **gear icon** → **Download GoogleService-Info.plist**
5. Save it to: `ios/Runner/GoogleService-Info.plist`

## Verification

After downloading the files, verify they exist:

```bash
ls -la android/app/google-services.json
ls -la ios/Runner/GoogleService-Info.plist
```

Both files should be present and not empty.

## Important Notes

- **Do NOT commit these files to Git** - they are already in `.gitignore`
- These files contain API keys and project identifiers
- Each team member needs to download their own copies
- CI/CD pipelines should download these files as part of the build process

## App Check Configuration

Firebase App Check is configured to use debug providers for development:

```dart
await FirebaseAppCheck.instance.activate(
  androidProvider: AndroidProvider.debug,
  appleProvider: AppleProvider.debug,
);
```

**For Production:**
- Android: Switch to `AndroidProvider.playIntegrity` and register SHA-256 fingerprint in Firebase Console
- iOS: Switch to `AppleProvider.deviceCheck` or `AppleProvider.appAttest`

## Troubleshooting

### "Permission denied" error
Ensure you're logged in to Firebase CLI and have access to the project:
```bash
firebase login
firebase projects:list
```

### Files not found after download
Check that you're in the correct directory and the paths are correct:
```bash
pwd  # Should show: /path/to/CliniqFlow
```

### Build errors after setup
Clean and rebuild the project:
```bash
flutter clean
flutter pub get
flutter run
```

## CI/CD Setup

For automated builds, add these commands to your CI/CD pipeline before building:

```yaml
# Example for GitHub Actions
- name: Download Firebase config
  run: |
    firebase apps:sdkconfig android > android/app/google-services.json
    firebase apps:sdkconfig ios > ios/Runner/GoogleService-Info.plist
  env:
    FIREBASE_TOKEN: ${{ secrets.FIREBASE_TOKEN }}
```

To generate a CI token:
```bash
firebase login:ci
```

## Related Documentation

- [Firebase Setup Guide](https://firebase.google.com/docs/flutter/setup)
- [Firebase CLI Reference](https://firebase.google.com/docs/cli)
- [Increment 3 Offline Support](./increment3_offline_support.md)
