import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'features/patients/data/patient_repository.dart';
import 'features/patients/presentation/patient_directory_controller.dart';
import 'features/patients/presentation/patient_directory_page.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  final firestore = FirebaseFirestore.instance;

  firestore.settings = const Settings(persistenceEnabled: true);

  runApp(
    MultiProvider(
      providers: [
        Provider<PatientRepository>(
          create: (_) => FirestorePatientRepository(firestore),
        ),
        ChangeNotifierProvider<PatientDirectoryController>(
          create: (context) => PatientDirectoryController(
            context.read<PatientRepository>(),
          )..initialize(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CliniqFlow',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const PatientDirectoryPage(),
    );
  }
}
