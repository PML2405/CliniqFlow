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

  @override
  void initState() {
    super.initState();
    _clinicianProfile = ValueNotifier(
      ClinicianProfile(
        name: widget.preferences.loadClinicianName(),
        photoUrl: widget.preferences.loadClinicianPhotoUrl(),
      ),
    )..addListener(_persistClinicianProfile);
  }

  @override
  void dispose() {
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
            profileNotifier: _clinicianProfile,
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
}
