import 'package:flutter/material.dart';

import '../appointments/presentation/appointment_schedule_page.dart';
import '../patients/presentation/patient_directory_page.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final destinations = _destinations;
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: IndexedStack(
          key: ValueKey(_index),
          index: _index,
          children: const [
            AppointmentSchedulePage(),
            PatientDirectoryPage(),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        destinations: destinations,
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
      ];
}
