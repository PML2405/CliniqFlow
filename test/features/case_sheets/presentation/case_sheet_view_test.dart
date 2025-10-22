import 'dart:typed_data';

import 'package:cliniqflow/features/appointments/models/appointment.dart';
import 'package:cliniqflow/features/case_sheets/models/case_sheet.dart';
import 'package:cliniqflow/features/case_sheets/presentation/case_sheet_controller.dart';
import 'package:cliniqflow/features/case_sheets/presentation/case_sheet_page.dart';
import 'package:cliniqflow/features/patients/models/patient_profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockCaseSheetController extends Mock implements CaseSheetController {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      Appointment(
        id: 'fallback-appt',
        patientId: 'patient-1',
        patientUid: 'uid-1',
        patientName: 'Test Patient',
        start: DateTime(2025, 6, 1, 9),
        durationMinutes: 30,
        purpose: 'Fallback',
        status: AppointmentStatus.scheduled,
        createdAt: DateTime(2025, 6, 1, 8),
        updatedAt: DateTime(2025, 6, 1, 8),
      ),
    );
    registerFallbackValue(PatientProfile.empty());
    registerFallbackValue(const CaseSheetConsent(isGranted: false));
    registerFallbackValue(Uint8List(0));
  });

  group('CaseSheetPage', () {
    late _MockCaseSheetController controller;
    late List<CaseSheet> sheets;
    late PatientProfile patient;
    late List<Appointment> appointments;

    setUp(() {
      controller = _MockCaseSheetController();
      sheets = [
        CaseSheet(
          id: 'cs-1',
          patientId: 'patient-1',
          patientUid: 'uid-1',
          patientName: 'Test Patient',
          appointmentId: 'appt-1',
          doctorInCharge: 'Dr. Smith',
          visitDate: DateTime(2025, 6, 1, 9),
          chiefComplaint: 'Pain',
          provisionalDiagnosis: 'Cavity',
          treatmentPlan: 'Fillings',
          consent: const CaseSheetConsent(isGranted: false),
          attachments: const [],
          createdAt: DateTime(2025, 6, 1),
          updatedAt: DateTime(2025, 6, 1),
        ),
      ];

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

      appointments = [
        Appointment(
          id: 'appt-1',
          patientId: 'patient-1',
          patientUid: 'uid-1',
          patientName: 'Test Patient',
          start: DateTime(2025, 6, 1, 9),
          durationMinutes: 45,
          purpose: 'Checkup',
          status: AppointmentStatus.completed,
          createdAt: DateTime(2025, 5, 30),
          updatedAt: DateTime(2025, 6, 1),
        ),
      ];

      when(() => controller.caseSheets).thenReturn(sheets);
      when(() => controller.state).thenReturn(CaseSheetViewState.idle);
      when(() => controller.errorMessage).thenReturn(null);
      when(() => controller.selectedSheet).thenReturn(sheets.first);
      when(() => controller.patientId).thenReturn('patient-1');
      when(
        () => controller.createCaseSheet(
          patient: any(named: 'patient'),
          appointment: any(named: 'appointment'),
          visitDate: any(named: 'visitDate'),
          doctorInCharge: any(named: 'doctorInCharge'),
          chiefComplaint: any(named: 'chiefComplaint'),
          provisionalDiagnosis: any(named: 'provisionalDiagnosis'),
          treatmentPlan: any(named: 'treatmentPlan'),
        ),
      ).thenAnswer((_) async {});
      when(() => controller.recordConsent(any())).thenAnswer((_) async {});
      when(
        () => controller.uploadAttachment(
          fileName: any(named: 'fileName'),
          contentType: any(named: 'contentType'),
          bytes: any(named: 'bytes'),
        ),
      ).thenAnswer((_) async {});
      when(() => controller.initialize(any())).thenAnswer((_) {});
      when(() => controller.selectSheet(any())).thenAnswer((_) {});
      when(() => controller.caseSheets).thenReturn(sheets);
    });

    testWidgets('renders case sheet list and details', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CaseSheetPage(
            controller: controller,
            patientId: 'patient-1',
            patient: patient,
            availableAppointments: appointments,
          ),
        ),
      );

      verify(() => controller.initialize('patient-1')).called(1);
      expect(find.text('Case Sheets'), findsOneWidget);
      expect(find.text('Dr. Smith'), findsWidgets);
      expect(find.text('Pain'), findsWidgets);
      expect(find.text('Fillings'), findsWidgets);
      expect(find.textContaining('Linked appointment'), findsOneWidget);
      expect(find.textContaining('Checkup'), findsOneWidget);
    });

    testWidgets('shows loading indicator when state is loading', (tester) async {
      when(() => controller.state).thenReturn(CaseSheetViewState.loading);

      await tester.pumpWidget(
        MaterialApp(
          home: CaseSheetPage(
            controller: controller,
            patientId: 'patient-1',
            patient: patient,
            availableAppointments: appointments,
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows error state when controller has error', (tester) async {
      when(() => controller.errorMessage).thenReturn('Network error');
      when(() => controller.state).thenReturn(CaseSheetViewState.error);

      await tester.pumpWidget(
        MaterialApp(
          home: CaseSheetPage(
            controller: controller,
            patientId: 'patient-1',
            patient: patient,
            availableAppointments: appointments,
          ),
        ),
      );

      expect(find.textContaining('Network error'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('creates new case sheet from dialog', (tester) async {
      when(() => controller.caseSheets).thenReturn(const <CaseSheet>[]);

      await tester.pumpWidget(
        MaterialApp(
          home: CaseSheetPage(
            controller: controller,
            patientId: 'patient-1',
            patient: patient,
            availableAppointments: appointments,
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('createCaseSheetButton')));
      await tester.pump();
      expect(find.byType(AlertDialog), findsOneWidget);

      await tester.enterText(find.byKey(const Key('caseSheetDoctorField')), ' Dr. New ');
      await tester.enterText(find.byKey(const Key('caseSheetComplaintField')), ' Headache ');
      await tester.enterText(find.byKey(const Key('caseSheetDiagnosisField')), ' Migraine ');
      await tester.enterText(find.byKey(const Key('caseSheetTreatmentField')), ' Rest ');
      await tester.enterText(find.byKey(const Key('caseSheetDateField')), '2025-06-01T09:00');

      await tester.tap(find.byKey(const Key('caseSheetSubmitButton')));
      await tester.pump();
      final appointmentCaptured =
          verify(() => controller.createCaseSheet(
                patient: patient,
                appointment: captureAny(named: 'appointment'),
                visitDate: DateTime.parse('2025-06-01T09:00'),
                doctorInCharge: 'Dr. New',
                chiefComplaint: 'Headache',
                provisionalDiagnosis: 'Migraine',
                treatmentPlan: 'Rest',
              ))
              .captured
              .single as Appointment;
      expect(appointmentCaptured.id, 'appt-1');
    });

    testWidgets('records consent from dialog', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CaseSheetPage(
            controller: controller,
            patientId: 'patient-1',
            patient: patient,
            availableAppointments: appointments,
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('recordConsentButton')));
      await tester.pump();
      expect(find.byType(AlertDialog), findsOneWidget);

      await tester.enterText(find.byKey(const Key('consentCapturedByField')), ' Nurse Joy ');
      await tester.tap(find.byKey(const Key('consentSubmitButton')));
      await tester.pump();

      final recordedConsent = verify(() => controller.recordConsent(captureAny()))
          .captured
          .single as CaseSheetConsent;
      expect(recordedConsent.isGranted, isTrue);
      expect(recordedConsent.capturedBy, 'Nurse Joy');
    });

    testWidgets('uploads attachment from dialog', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CaseSheetPage(
            controller: controller,
            patientId: 'patient-1',
            patient: patient,
            availableAppointments: appointments,
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('addAttachmentButton')));
      await tester.pump();
      expect(find.byType(AlertDialog), findsOneWidget);

      await tester.enterText(find.byKey(const Key('attachmentFileNameField')), ' xray.png ');
      await tester.enterText(find.byKey(const Key('attachmentContentTypeField')), ' image/png ');
      await tester.enterText(find.byKey(const Key('attachmentDataField')), 'test-bytes');

      await tester.tap(find.byKey(const Key('attachmentSubmitButton')));
      await tester.pump();

      final uploadedBytes = verify(
        () => controller.uploadAttachment(
          fileName: 'xray.png',
          contentType: 'image/png',
          bytes: captureAny(named: 'bytes'),
        ),
      ).captured.single as Uint8List;
      expect(String.fromCharCodes(uploadedBytes), 'test-bytes');
    });

    testWidgets('quick action fills sample attachment data', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CaseSheetPage(
            controller: controller,
            patientId: 'patient-1',
            patient: patient,
            availableAppointments: appointments,
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('addAttachmentButton')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('attachmentSampleButton_photo')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('attachmentSubmitButton')));
      await tester.pump();

      final uploadedBytes = verify(
        () => controller.uploadAttachment(
          fileName: 'xray_sample.png',
          contentType: 'image/png',
          bytes: captureAny(named: 'bytes'),
        ),
      ).captured.single as Uint8List;
      expect(String.fromCharCodes(uploadedBytes), 'sample_png_bytes');
    });
  });
}
