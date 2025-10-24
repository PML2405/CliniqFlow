import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/models/clinician_profile.dart';
import '../../core/preferences/app_preferences.dart';
import '../appointments/presentation/appointment_schedule_page.dart';
import '../patients/presentation/patient_directory_page.dart';
import '../settings/presentation/settings_page.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({
    super.key,
    required this.themeModeNotifier,
    required this.preferences,
  });

  final ValueNotifier<ThemeMode> themeModeNotifier;
  final AppPreferences preferences;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  late final ValueNotifier<ClinicianProfile> _clinicianProfile;
  StreamSubscription<User?>? _authSubscription;

  @override
  void initState() {
    super.initState();
    final initialProfile = _resolveProfile(FirebaseAuth.instance.currentUser);

    _clinicianProfile = ValueNotifier(initialProfile)
      ..addListener(_persistClinicianProfile);

    _authSubscription = FirebaseAuth.instance.userChanges().listen((user) {
      final nextProfile = _resolveProfile(user);
      final current = _clinicianProfile.value;
      if (current.name != nextProfile.name || current.photoUrl != nextProfile.photoUrl) {
        _clinicianProfile.value = nextProfile;
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _clinicianProfile.removeListener(_persistClinicianProfile);
    _clinicianProfile.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final useRail = width >= 900;
    final extendRail = width >= 1200;

    final content = AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: IndexedStack(
        key: ValueKey(_index),
        index: _index,
        children: [
          ValueListenableBuilder<ClinicianProfile>(
            valueListenable: _clinicianProfile,
            builder: (context, profile, _) => AppointmentSchedulePage(
              clinicianName: profile.name,
              clinicianPhotoUrl: profile.photoUrl,
            ),
          ),
          const PatientDirectoryPage(),
          SettingsPage(
            themeModeNotifier: widget.themeModeNotifier,
          ),
        ],
      ),
    );

    if (useRail) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _index,
              destinations: _railDestinations,
              onDestinationSelected: (value) => setState(() => _index = value),
              labelType: extendRail ? NavigationRailLabelType.none : NavigationRailLabelType.all,
              extended: extendRail,
            ),
            const VerticalDivider(width: 1),
            Expanded(child: content),
          ],
        ),
      );
    }

    return Scaffold(
      body: content,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        destinations: _destinations,
        onDestinationSelected: (value) => setState(() => _index = value),
      ),
    );
  }

  List<NavigationDestination> get _destinations => const [
        NavigationDestination(
          icon: Icon(Icons.event),
          label: 'Schedule',
        ),
        NavigationDestination(
          icon: Icon(Icons.group),
          label: 'Patients',
        ),
        NavigationDestination(
          icon: Icon(Icons.settings),
          label: 'Settings',
        ),
      ];

  List<NavigationRailDestination> get _railDestinations => const [
        NavigationRailDestination(
          icon: Icon(Icons.event),
          label: Text('Schedule'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.group),
          label: Text('Patients'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.settings),
          label: Text('Settings'),
        ),
      ];

  void _persistClinicianProfile() {
    final profile = _clinicianProfile.value;
    widget.preferences.saveClinicianName(profile.name);
    widget.preferences.saveClinicianPhotoUrl(profile.photoUrl);
  }

  ClinicianProfile _resolveProfile(User? user) {
    final fallbackName = widget.preferences.loadClinicianName();
    final fallbackPhoto = widget.preferences.loadClinicianPhotoUrl();

    final displayName = user?.displayName?.trim();
    final resolvedName = (displayName != null && displayName.isNotEmpty)
        ? displayName
        : fallbackName;

    final resolvedPhoto = user?.photoURL ?? fallbackPhoto;

    return ClinicianProfile(
      name: resolvedName,
      photoUrl: resolvedPhoto,
    );
  }
}
