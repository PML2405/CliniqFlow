import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../core/preferences/app_preferences.dart';
import '../../home/home_shell.dart';
import 'auth_screen.dart';

/// Wrapper that handles authentication state and navigation
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({
    super.key,
    required this.themeModeNotifier,
    required this.preferences,
  });

  final ValueNotifier<ThemeMode> themeModeNotifier;
  final AppPreferences preferences;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show loading indicator while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Show home screen if user is authenticated
        if (snapshot.hasData && snapshot.data != null) {
          return HomeShell(
            themeModeNotifier: themeModeNotifier,
            preferences: preferences,
          );
        }

        // Show auth screen if user is not authenticated
        return const AuthScreen();
      },
    );
  }
}
