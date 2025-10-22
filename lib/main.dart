import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/preferences/app_preferences.dart';
import 'features/appointments/data/appointment_repository.dart';
import 'features/appointments/presentation/appointment_schedule_controller.dart';
import 'features/home/home_shell.dart';
import 'features/patients/data/patient_repository.dart';
import 'features/patients/presentation/patient_directory_controller.dart';
import 'features/case_sheets/data/case_sheet_repository.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  final firestore = FirebaseFirestore.instance;

  firestore.settings = const Settings(persistenceEnabled: true);

  final preferences = await AppPreferences.instance();

  runApp(
    MultiProvider(
      providers: [
        Provider<PatientRepository>(
          create: (_) => FirestorePatientRepository(firestore),
        ),
        Provider<AppointmentRepository>(
          create: (_) => FirestoreAppointmentRepository(firestore),
        ),
        Provider<CaseSheetRepository>(
          create: (_) => FirestoreCaseSheetRepository(firestore),
        ),
        ChangeNotifierProvider<PatientDirectoryController>(
          create: (context) => PatientDirectoryController(
            context.read<PatientRepository>(),
          )..initialize(),
        ),
        ChangeNotifierProvider<AppointmentScheduleController>(
          create: (context) => AppointmentScheduleController(
            context.read<AppointmentRepository>(),
          )..initialize(),
        ),
      ],
      child: MyApp(preferences: preferences),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key, required this.preferences});

  final AppPreferences preferences;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final ValueNotifier<ThemeMode> _themeMode;

  @override
  void initState() {
    super.initState();
    _themeMode = ValueNotifier(widget.preferences.loadThemeMode())
      ..addListener(_handleThemeModeChanged);
  }

  @override
  void dispose() {
    _themeMode.removeListener(_handleThemeModeChanged);
    _themeMode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const seedBlue = Color(0xFF1976D2);
    const healingGreen = Color(0xFF388E3C);
    const softTeal = Color(0xFF00897B);

    final lightColorScheme = ColorScheme.fromSeed(
      seedColor: seedBlue,
      brightness: Brightness.light,
      secondary: healingGreen,
      tertiary: softTeal,
    );

    final darkColorScheme = ColorScheme.fromSeed(
      seedColor: seedBlue,
      brightness: Brightness.dark,
      secondary: healingGreen,
      tertiary: softTeal,
    );

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: _themeMode,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'CliniqFlow',
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: lightColorScheme,
            appBarTheme: const AppBarTheme(surfaceTintColor: Colors.transparent),
            cardTheme: const CardThemeData(surfaceTintColor: Colors.transparent),
            floatingActionButtonTheme: FloatingActionButtonThemeData(
              backgroundColor: lightColorScheme.secondary,
              foregroundColor: lightColorScheme.onSecondary,
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: darkColorScheme,
            appBarTheme: const AppBarTheme(surfaceTintColor: Colors.transparent),
            cardTheme: const CardThemeData(surfaceTintColor: Colors.transparent),
            floatingActionButtonTheme: FloatingActionButtonThemeData(
              backgroundColor: darkColorScheme.secondary,
              foregroundColor: darkColorScheme.onSecondary,
            ),
          ),
          themeMode: mode,
          home: HomeShell(
            themeModeNotifier: _themeMode,
            preferences: widget.preferences,
          ),
        );
      },
    );
  }

  void _handleThemeModeChanged() {
    widget.preferences.saveThemeMode(_themeMode.value);
  }
}
