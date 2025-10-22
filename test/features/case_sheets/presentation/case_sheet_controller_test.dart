import 'dart:typed_data';

import 'package:cliniqflow/features/appointments/models/appointment.dart';
import 'package:cliniqflow/features/case_sheets/data/case_sheet_repository.dart';
import 'package:cliniqflow/features/case_sheets/models/case_sheet.dart';
import 'package:cliniqflow/features/case_sheets/presentation/case_sheet_controller.dart';
import 'package:cliniqflow/features/patients/models/patient_profile.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepository extends Mock implements CaseSheetRepository {}
void main() {
  setUpAll(() {
    registerFallbackValue(Uint8List(0));
  });

  group('CaseSheetController', () {
    late CaseSheetController controller;
    late _MockRepository repository;
    late PatientProfile patient;

    setUp(() {
      repository = _MockRepository();
      controller = CaseSheetController(repository);
      patient = PatientProfile(
        id: 'patient-1',
        patientUid: 'uid-1',
        fullName: 'Test Patient',
        registrationDate: DateTime(2025, 1, 1),
        contactInfo: const ContactInfo(),
        emergencyContact: const EmergencyContact(),
        medicalHistory: const MedicalHistory(),
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 1),
      );

      when(() => repository.watchByPatient(patient.id)).thenAnswer(
        (_) => const Stream<List<CaseSheet>>.empty(),
      );
    });

    test('setConsent updates state and triggers repository call', () async {
      controller.initialize(patient.id);
      final sheet = CaseSheet.empty().copyWith(id: 'cs-1');
      controller.selectSheet(sheet);

      final consent = CaseSheetConsent(
        isGranted: true,
        capturedBy: 'Guardian',
        capturedAt: DateTime(2025, 3, 1, 10),
      );

      when(() => repository.recordConsent(sheet: sheet, consent: consent))
          .thenAnswer((_) async {});

      await controller.recordConsent(consent);

      verify(() => repository.recordConsent(sheet: sheet, consent: consent))
          .called(1);
      expect(controller.selectedSheet?.consent.isGranted, isTrue);
      expect(controller.selectedSheet?.consent.capturedBy, 'Guardian');
      expect(controller.state, CaseSheetViewState.idle);
    });

    test('recordConsent handles repository errors', () async {
      controller.initialize(patient.id);
      final sheet = CaseSheet.empty().copyWith(id: 'cs-2');
      controller.selectSheet(sheet);

      final consent = CaseSheetConsent(isGranted: false);

      when(() => repository.recordConsent(sheet: sheet, consent: consent))
          .thenThrow(Exception('network error'));

      await controller.recordConsent(consent);

      expect(controller.errorMessage, isNotNull);
      expect(controller.state, CaseSheetViewState.error);
    });

    test('createCaseSheet adds new sheet and selects it', () async {
      controller.initialize(patient.id);
      final appointment = Appointment(
        id: 'appt-1',
        patientId: patient.id,
        patientUid: patient.patientUid,
        patientName: patient.fullName,
        start: DateTime(2025, 6, 1, 9),
        durationMinutes: 60,
        purpose: 'Checkup',
        status: AppointmentStatus.completed,
        createdAt: DateTime(2025, 6, 1, 8),
        updatedAt: DateTime(2025, 6, 1, 8),
      );

      when(
        () => repository.create(
          patient: patient,
          appointment: appointment,
          visitDate: DateTime(2025, 6, 1, 9),
          doctorInCharge: 'Dr. New',
          chiefComplaint: 'Headache',
          provisionalDiagnosis: 'Migraine',
          treatmentPlan: 'Rest',
        ),
      ).thenAnswer((_) async => 'cs-new');

      final createdSheet = CaseSheet(
        id: 'cs-new',
        patientId: patient.id,
        patientUid: patient.patientUid,
        patientName: patient.fullName,
        appointmentId: appointment.id,
        doctorInCharge: 'Dr. New',
        visitDate: DateTime(2025, 6, 1, 9),
        chiefComplaint: 'Headache',
        provisionalDiagnosis: 'Migraine',
        treatmentPlan: 'Rest',
        consent: const CaseSheetConsent(isGranted: false),
        attachments: const [],
        createdAt: DateTime(2025, 6, 1, 9),
        updatedAt: DateTime(2025, 6, 1, 9),
      );

      when(() => repository.fetchById('cs-new')).thenAnswer((_) async => createdSheet);

      await controller.createCaseSheet(
        patient: patient,
        appointment: appointment,
        visitDate: DateTime(2025, 6, 1, 9),
        doctorInCharge: 'Dr. New',
        chiefComplaint: 'Headache',
        provisionalDiagnosis: 'Migraine',
        treatmentPlan: 'Rest',
      );

      expect(controller.caseSheets, contains(createdSheet));
      expect(controller.selectedSheet?.id, 'cs-new');
      expect(controller.state, CaseSheetViewState.idle);
    });

    test('createCaseSheet handles errors', () async {
      controller.initialize(patient.id);
      final appointment = Appointment(
        id: 'appt-error',
        patientId: patient.id,
        patientUid: patient.patientUid,
        patientName: patient.fullName,
        start: DateTime(2025, 6, 2, 9),
        durationMinutes: 45,
        purpose: 'Follow-up',
        status: AppointmentStatus.scheduled,
        createdAt: DateTime(2025, 6, 2, 8),
        updatedAt: DateTime(2025, 6, 2, 8),
      );

      when(
        () => repository.create(
          patient: patient,
          appointment: appointment,
          visitDate: DateTime(2025, 6, 2, 9),
          doctorInCharge: 'Dr. Error',
          chiefComplaint: 'Pain',
          provisionalDiagnosis: 'Unknown',
          treatmentPlan: 'Investigate',
        ),
      ).thenThrow(Exception('creation failed'));

      await controller.createCaseSheet(
        patient: patient,
        appointment: appointment,
        visitDate: DateTime(2025, 6, 2, 9),
        doctorInCharge: 'Dr. Error',
        chiefComplaint: 'Pain',
        provisionalDiagnosis: 'Unknown',
        treatmentPlan: 'Investigate',
      );

      expect(controller.errorMessage, contains('creation failed'));
      expect(controller.state, CaseSheetViewState.error);
    });

    test('uploadAttachment updates selected sheet and case sheet list', () async {
      controller.initialize(patient.id);
      final sheet = CaseSheet(
        id: 'cs-attach',
        patientId: patient.id,
        patientUid: patient.patientUid,
        patientName: patient.fullName,
        appointmentId: 'appt-1',
        doctorInCharge: 'Dr. Files',
        visitDate: DateTime(2025, 6, 1),
        chiefComplaint: 'Pain',
        provisionalDiagnosis: 'Cavity',
        treatmentPlan: 'Fillings',
        consent: const CaseSheetConsent(isGranted: false),
        attachments: const [],
        createdAt: DateTime(2025, 6, 1),
        updatedAt: DateTime(2025, 6, 1),
      );

      controller.selectSheet(sheet);

      final attachment = CaseSheetAttachment(
        id: 'att-1',
        storagePath: 'case_sheets/cs-attach/att-1.png',
        fileName: 'xray.png',
        downloadUrl: 'https://example.com/xray.png',
        contentType: 'image/png',
        sizeBytes: 2048,
        uploadedAt: DateTime(2025, 6, 1, 10),
      );

      when(
        () => repository.uploadAttachment(
          sheet: sheet,
          fileName: 'xray.png',
          contentType: 'image/png',
          bytes: any(named: 'bytes'),
        ),
      ).thenAnswer((_) async => attachment);

      when(() => repository.fetchById(sheet.id)).thenAnswer((_) async => sheet);

      await controller.uploadAttachment(
        fileName: 'xray.png',
        contentType: 'image/png',
        bytes: Uint8List.fromList([1, 2, 3]),
      );

      verify(
        () => repository.uploadAttachment(
          sheet: sheet,
          fileName: 'xray.png',
          contentType: 'image/png',
          bytes: any(named: 'bytes'),
        ),
      ).called(1);

      expect(controller.selectedSheet?.attachments, hasLength(1));
      expect(controller.selectedSheet?.attachments.first.fileName, 'xray.png');
      expect(controller.state, CaseSheetViewState.idle);
    });
  });
}
