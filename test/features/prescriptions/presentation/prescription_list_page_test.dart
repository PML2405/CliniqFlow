import 'package:cliniqflow/features/patients/models/patient_profile.dart';
import 'package:cliniqflow/features/prescriptions/models/prescription.dart';
import 'package:cliniqflow/features/prescriptions/presentation/prescription_controller.dart';
import 'package:cliniqflow/features/prescriptions/presentation/prescription_list_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockPrescriptionController extends Mock
    implements PrescriptionController {}

void main() {
  group('PrescriptionListPage', () {
    late _MockPrescriptionController controller;
    late PatientProfile patient;
    late List<Prescription> prescriptions;

    setUp(() {
      controller = _MockPrescriptionController();
      patient = PatientProfile(
        id: 'patient-1',
        patientUid: 'uid-1',
        fullName: 'Test Patient',
        registrationDate: DateTime(2025, 1, 1),
        contactInfo: const ContactInfo(residentialPhone: '12345'),
        emergencyContact: const EmergencyContact(name: 'Guardian'),
        medicalHistory: const MedicalHistory(),
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 1),
      );

      prescriptions = [
        Prescription(
          id: 'rx-1',
          patientId: 'patient-1',
          patientUid: 'uid-1',
          patientName: 'Test Patient',
          caseSheetId: 'case-1',
          doctorName: 'Dr. Smith',
          prescriptionDate: DateTime(2025, 6, 1),
          items: [
            const PrescriptionItem(
              id: '1',
              drugName: 'Amoxicillin',
              dosage: '500mg',
              frequency: 'Twice daily',
              duration: '7 days',
            ),
          ],
          createdAt: DateTime(2025, 6, 1),
          updatedAt: DateTime(2025, 6, 1),
        ),
      ];

      when(() => controller.state).thenReturn(PrescriptionViewState.idle);
      when(() => controller.errorMessage).thenReturn(null);
      when(() => controller.prescriptions).thenReturn(prescriptions);
      when(() => controller.initialize(any())).thenAnswer((_) async {});
      when(() => controller.addListener(any())).thenReturn(null);
      when(() => controller.removeListener(any())).thenReturn(null);
    });

    testWidgets('renders prescription list', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PrescriptionListPage(
            controller: controller,
            patient: patient,
          ),
        ),
      );
      await tester.pumpAndSettle();

      verify(() => controller.initialize('patient-1')).called(1);
      expect(find.text('Prescriptions'), findsOneWidget);
      expect(find.text('Dr. Smith'), findsOneWidget);
      expect(find.text('1 medication(s)'), findsOneWidget);
    });

    testWidgets('shows loading indicator when state is loading',
        (tester) async {
      when(() => controller.state).thenReturn(PrescriptionViewState.loading);

      await tester.pumpWidget(
        MaterialApp(
          home: PrescriptionListPage(
            controller: controller,
            patient: patient,
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows error state when controller has error', (tester) async {
      when(() => controller.errorMessage).thenReturn('Network error');
      when(() => controller.state).thenReturn(PrescriptionViewState.error);

      await tester.pumpWidget(
        MaterialApp(
          home: PrescriptionListPage(
            controller: controller,
            patient: patient,
          ),
        ),
      );

      expect(find.text('Error loading prescriptions'), findsOneWidget);
      expect(find.text('Network error'), findsOneWidget);
    });

    testWidgets('shows empty state when no prescriptions', (tester) async {
      when(() => controller.prescriptions).thenReturn([]);

      await tester.pumpWidget(
        MaterialApp(
          home: PrescriptionListPage(
            controller: controller,
            patient: patient,
          ),
        ),
      );

      expect(find.text('No prescriptions yet'), findsOneWidget);
      expect(find.text('Create a prescription to get started'), findsOneWidget);
    });

    testWidgets('has create prescription button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PrescriptionListPage(
            controller: controller,
            patient: patient,
          ),
        ),
      );

      expect(
        find.byKey(const Key('createPrescriptionButton')),
        findsOneWidget,
      );
    });
  });
}
