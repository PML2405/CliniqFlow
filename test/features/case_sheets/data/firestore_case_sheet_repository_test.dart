import 'dart:typed_data';

import 'package:cliniqflow/features/appointments/models/appointment.dart';
import 'package:cliniqflow/features/case_sheets/data/case_sheet_repository.dart';
import 'package:cliniqflow/features/case_sheets/data/case_sheet_storage.dart';
import 'package:cliniqflow/features/case_sheets/models/case_sheet.dart';
import 'package:cliniqflow/features/patients/models/patient_profile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockCaseSheetStorageService extends Mock
    implements CaseSheetStorageService {}

PatientProfile buildPatient(String id, {String? name}) {
  final now = DateTime(2025, 1, 1);
  return PatientProfile(
    id: id,
    patientUid: 'uid-$id',
    fullName: name ?? 'Patient $id',
    registrationDate: now,
    contactInfo: const ContactInfo(residentialPhone: '123-456'),
    emergencyContact: const EmergencyContact(name: 'Guardian'),
    medicalHistory: const MedicalHistory(),
    createdAt: now,
    updatedAt: now,
  );
}

Appointment buildAppointment(String id, DateTime start) {
  return Appointment(
    id: id,
    patientId: 'patient-1',
    patientUid: 'uid-patient-1',
    patientName: 'Patient 1',
    start: start,
    durationMinutes: 60,
    purpose: 'Dental visit',
    status: AppointmentStatus.completed,
    createdAt: start,
    updatedAt: start,
  );
}

Future<CaseSheet> fetchCaseSheet(
  CaseSheetRepository repository,
  String id,
) async {
  final sheet = await repository.fetchById(id);
  expect(sheet, isNotNull);
  return sheet!;
}

void main() {
  setUpAll(() {
    registerFallbackValue(Uint8List(0));
  });

  group('FirestoreCaseSheetRepository', () {
    late FakeFirebaseFirestore firestore;
    late CaseSheetRepository repository;
    late PatientProfile patient;
    late Appointment appointment;
    late _MockCaseSheetStorageService storage;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      storage = _MockCaseSheetStorageService();
      repository = FirestoreCaseSheetRepository(
        firestore,
        storage: storage,
      );
      patient = buildPatient('patient-1');
      appointment = buildAppointment('appt-1', DateTime(2025, 2, 1, 9));
    });

    test('create stores case sheet linked to patient and appointment', () async {
      final id = await repository.create(
        patient: patient,
        appointment: appointment,
        visitDate: DateTime(2025, 2, 1, 9, 30),
        doctorInCharge: 'Dr. Clark',
        chiefComplaint: 'Pain',
        provisionalDiagnosis: 'Cavity',
        treatmentPlan: 'Filling',
      );

      final doc = await firestore.collection('case_sheets').doc(id).get();
      expect(doc.exists, isTrue);
      final data = doc.data()!;
      expect(data['patientId'], patient.id);
      expect(data['patientUid'], patient.patientUid);
      expect(data['patientName'], patient.fullName);
      expect(data['appointmentId'], appointment.id);
      expect(data['doctorInCharge'], 'Dr. Clark');
      expect(data['chiefComplaint'], 'Pain');
      expect(data['consent'], {'isGranted': false});
      expect(data['attachments'], isEmpty);
      expect(data['visitDate'], isA<Timestamp>());
      expect(data['createdAt'], isA<Timestamp>());
      expect(data['updatedAt'], isA<Timestamp>());
    });

    test('watchByPatient streams sheets ordered by visitDate descending', () async {
      final collection = firestore.collection('case_sheets');
      await collection.doc('first').set({
        'patientId': patient.id,
        'patientUid': patient.patientUid,
        'patientName': patient.fullName,
        'appointmentId': 'appt-a',
        'doctorInCharge': 'Dr. A',
        'visitDate': Timestamp.fromDate(DateTime(2025, 2, 1, 9)),
        'chiefComplaint': 'Checkup',
        'provisionalDiagnosis': 'Healthy',
        'treatmentPlan': 'Routine',
        'consent': {'isGranted': true},
        'attachments': const <Map<String, dynamic>>[],
        'createdAt': Timestamp.fromDate(DateTime(2025, 2, 1, 8)),
        'updatedAt': Timestamp.fromDate(DateTime(2025, 2, 1, 8)),
      });
      await collection.doc('second').set({
        'patientId': patient.id,
        'patientUid': patient.patientUid,
        'patientName': patient.fullName,
        'appointmentId': 'appt-b',
        'doctorInCharge': 'Dr. B',
        'visitDate': Timestamp.fromDate(DateTime(2025, 3, 1, 10)),
        'chiefComplaint': 'Follow-up',
        'provisionalDiagnosis': 'Improving',
        'treatmentPlan': 'Medication',
        'consent': {'isGranted': false},
        'attachments': const <Map<String, dynamic>>[],
        'createdAt': Timestamp.fromDate(DateTime(2025, 3, 1, 9)),
        'updatedAt': Timestamp.fromDate(DateTime(2025, 3, 1, 9)),
      });

      final sheets = await repository.watchByPatient(patient.id).first;
      expect(sheets.map((s) => s.id), ['second', 'first']);
    });

    test('updateDetails modifies editable fields and timestamp', () async {
      final id = await repository.create(
        patient: patient,
        appointment: appointment,
        visitDate: DateTime(2025, 4, 1, 9),
        doctorInCharge: 'Dr. Base',
        chiefComplaint: 'Initial',
        provisionalDiagnosis: 'TBD',
        treatmentPlan: 'Observe',
      );
      final sheet = await fetchCaseSheet(repository, id);

      await repository.updateDetails(
        sheet: sheet,
        doctorInCharge: 'Dr. Updated',
        chiefComplaint: 'Severe pain',
        provisionalDiagnosis: 'Abscess',
        treatmentPlan: 'Root canal',
      );

      final doc = await firestore.collection('case_sheets').doc(id).get();
      final data = doc.data()!;
      expect(data['doctorInCharge'], 'Dr. Updated');
      expect(data['chiefComplaint'], 'Severe pain');
      expect(data['provisionalDiagnosis'], 'Abscess');
      expect(data['treatmentPlan'], 'Root canal');
      expect(data['updatedAt'], isA<Timestamp>());
    });

    test('recordConsent saves consent metadata', () async {
      final id = await repository.create(
        patient: patient,
        appointment: appointment,
        visitDate: DateTime(2025, 5, 1, 11),
        doctorInCharge: 'Dr. Consent',
        chiefComplaint: 'Extraction',
        provisionalDiagnosis: 'Impacted tooth',
        treatmentPlan: 'Surgery',
      );
      final sheet = await fetchCaseSheet(repository, id);

      final consent = CaseSheetConsent(
        isGranted: true,
        capturedBy: 'Guardian',
        capturedAt: DateTime(2025, 5, 1, 11, 15),
      );

      await repository.recordConsent(sheet: sheet, consent: consent);

      final updated = await fetchCaseSheet(repository, id);
      expect(updated.consent.isGranted, isTrue);
      expect(updated.consent.capturedBy, 'Guardian');
      expect(updated.consent.capturedAt, DateTime(2025, 5, 1, 11, 15));
    });

    test('replaceAttachments persists attachment metadata', () async {
      final id = await repository.create(
        patient: patient,
        appointment: appointment,
        visitDate: DateTime(2025, 6, 1, 12),
        doctorInCharge: 'Dr. Files',
        chiefComplaint: 'Imaging',
        provisionalDiagnosis: 'Check-up',
        treatmentPlan: 'Monitoring',
      );
      final sheet = await fetchCaseSheet(repository, id);

      final attachments = [
        CaseSheetAttachment(
          id: 'att-1',
          storagePath: 'case_sheets/$id/att-1.png',
          fileName: 'xray.png',
          downloadUrl: 'https://example.com/xray.png',
          contentType: 'image/png',
          sizeBytes: 2048,
          uploadedAt: DateTime(2025, 6, 1, 12, 10),
        ),
      ];

      await repository.replaceAttachments(sheet: sheet, attachments: attachments);

      final updated = await fetchCaseSheet(repository, id);
      expect(updated.attachments, hasLength(1));
      expect(updated.attachments.first.fileName, 'xray.png');
      expect(updated.attachments.first.storagePath, 'case_sheets/$id/att-1.png');
    });

    test('uploadAttachment stores bytes via storage service and updates Firestore', () async {
      final id = await repository.create(
        patient: patient,
        appointment: appointment,
        visitDate: DateTime(2025, 7, 1, 13),
        doctorInCharge: 'Dr. Upload',
        chiefComplaint: 'Scan',
        provisionalDiagnosis: 'Review',
        treatmentPlan: 'Monitor',
      );
      final sheet = await fetchCaseSheet(repository, id);

      final uploadedAttachment = CaseSheetAttachment(
        id: 'att-storage',
        storagePath: 'case_sheets/$id/att-storage.png',
        fileName: 'scan.png',
        downloadUrl: 'https://example.com/scan.png',
        contentType: 'image/png',
        sizeBytes: 1024,
        uploadedAt: DateTime(2025, 7, 1, 13, 30),
      );

      when(
        () => storage.uploadAttachment(
          caseSheetId: id,
          fileName: 'scan.png',
          bytes: any(named: 'bytes'),
          contentType: 'image/png',
        ),
      ).thenAnswer((_) async => uploadedAttachment);

      final result = await repository.uploadAttachment(
        sheet: sheet,
        fileName: 'scan.png',
        contentType: 'image/png',
        bytes: Uint8List.fromList([1, 2, 3]),
      );

      expect(result.fileName, 'scan.png');
      verify(
        () => storage.uploadAttachment(
          caseSheetId: id,
          fileName: 'scan.png',
          bytes: any(named: 'bytes'),
          contentType: 'image/png',
        ),
      ).called(1);

      final doc = await firestore.collection('case_sheets').doc(id).get();
      final attachments = List<Map<String, dynamic>>.from(doc.data()!['attachments']);
      expect(attachments, hasLength(1));
      expect(attachments.first['fileName'], 'scan.png');
      expect(attachments.first['storagePath'], 'case_sheets/$id/att-storage.png');
    });
  });
}
