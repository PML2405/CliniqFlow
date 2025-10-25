import 'package:cliniqflow/features/case_sheets/models/case_sheet.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CaseSheet', () {
    test('empty provides sensible defaults', () {
      final sheet = CaseSheet.empty();

      expect(sheet.id, isEmpty);
      expect(sheet.patientId, isEmpty);
      expect(sheet.patientUid, isEmpty);
      expect(sheet.patientName, isEmpty);
      expect(sheet.appointmentId, isEmpty);
      expect(sheet.doctorInCharge, isEmpty);
      expect(sheet.attachments, isEmpty);
      expect(sheet.consent.isGranted, isFalse);
      expect(sheet.createdAt, isA<DateTime>());
      expect(sheet.updatedAt, isA<DateTime>());
    });

    test('copyWith overrides selective fields', () {
      final now = DateTime(2025, 1, 1, 9);
      final sheet = CaseSheet(
        id: 'cs-1',
        patientId: 'patient-1',
        patientUid: 'uid-1',
        patientName: 'Alice',
        appointmentId: 'appt-1',
        doctorInCharge: 'Dr. Smith',
        visitDate: now,
        chiefComplaint: 'Pain',
        provisionalDiagnosis: 'Cavity',
        treatmentPlan: 'Filling',
        consent: const CaseSheetConsent(isGranted: false),
        attachments: const <CaseSheetAttachment>[],
        createdAt: now,
        updatedAt: now,
      );

      final updated = sheet.copyWith(
        doctorInCharge: 'Dr. Adams',
        chiefComplaint: 'Sensitivity',
        attachments: [
          CaseSheetAttachment(
            id: 'att-1',
            storagePath: 'case_sheets/cs-1/att-1.png',
            fileName: 'xray.png',
            downloadUrl: 'https://example.com/xray.png',
            contentType: 'image/png',
            sizeBytes: 2048,
            uploadedAt: DateTime(2025, 1, 1, 10),
          ),
        ],
        consent: sheet.consent.copyWith(isGranted: true),
        updatedAt: now.add(const Duration(minutes: 30)),
      );

      expect(updated.doctorInCharge, 'Dr. Adams');
      expect(updated.chiefComplaint, 'Sensitivity');
      expect(updated.attachments, hasLength(1));
      expect(updated.consent.isGranted, isTrue);
      expect(updated.id, sheet.id);
      expect(updated.createdAt, sheet.createdAt);
    });

    test('toMap serializes fields and nested values', () {
      final visitDate = DateTime(2025, 2, 2, 14, 30);
      final uploadedAt = DateTime(2025, 2, 2, 15);
      final sheet = CaseSheet(
        id: 'cs-2',
        patientId: 'patient-2',
        patientUid: 'uid-2',
        patientName: 'Bob',
        appointmentId: 'appt-2',
        doctorInCharge: 'Dr. Jane',
        visitDate: visitDate,
        chiefComplaint: 'Bleeding gums',
        provisionalDiagnosis: 'Gingivitis',
        treatmentPlan: 'Cleaning',
        consent: const CaseSheetConsent(
          isGranted: true,
          capturedBy: 'Bob',
        ),
        attachments: [
          CaseSheetAttachment(
            id: 'att-2',
            storagePath: 'case_sheets/cs-2/att-2.jpg',
            fileName: 'photo.jpg',
            downloadUrl: 'https://example.com/photo.jpg',
            contentType: 'image/jpeg',
            sizeBytes: 4096,
            uploadedAt: uploadedAt,
          ),
        ],
        createdAt: visitDate,
        updatedAt: visitDate,
      );

      final map = sheet.toMap();

      expect(map['patientId'], 'patient-2');
      expect(map['patientUid'], 'uid-2');
      expect(map['doctorInCharge'], 'Dr. Jane');
      expect(map['chiefComplaint'], 'Bleeding gums');
      expect(map['consent'], {
        'isGranted': true,
        'capturedBy': 'Bob',
      });
      expect(map['attachments'], hasLength(1));
      final attachment = map['attachments'].first as Map<String, dynamic>;
      expect(attachment['fileName'], 'photo.jpg');
      expect(attachment['storagePath'], 'case_sheets/cs-2/att-2.jpg');
      expect(map['visitDate'], isA<Timestamp>());
      expect(map['createdAt'], isA<Timestamp>());
      expect(map['updatedAt'], isA<Timestamp>());
    });

    test('fromDocument reconstructs values with defaults', () async {
      final firestore = FakeFirebaseFirestore();
      final visitDate = DateTime(2025, 3, 3, 9);
      final docRef = firestore.collection('case_sheets').doc('cs-3');
      await docRef.set({
        'patientId': 'patient-3',
        'patientUid': 'uid-3',
        'patientName': 'Cara',
        'appointmentId': 'appt-3',
        'doctorInCharge': 'Dr. Gill',
        'visitDate': Timestamp.fromDate(visitDate),
        'chiefComplaint': 'Toothache',
        'provisionalDiagnosis': 'Root infection',
        'treatmentPlan': 'RCT',
        'consent': {
          'isGranted': true,
          'capturedAt': Timestamp.fromDate(visitDate),
        },
        'attachments': [
          {
            'id': 'att-3',
            'fileName': 'xray.jpg',
            'storagePath': 'case_sheets/cs-3/att-3.jpg',
            'downloadUrl': 'https://example.com/xray.jpg',
            'contentType': 'image/jpeg',
            'sizeBytes': 5120,
            'uploadedAt': Timestamp.fromDate(visitDate.add(const Duration(minutes: 5))),
          },
        ],
        'createdAt': Timestamp.fromDate(visitDate),
        'updatedAt': Timestamp.fromDate(visitDate),
      });

      final snapshot = await docRef.get();
      final sheet = CaseSheet.fromDocument(snapshot);

      expect(sheet.id, 'cs-3');
      expect(sheet.patientId, 'patient-3');
      expect(sheet.patientName, 'Cara');
      expect(sheet.visitDate, visitDate);
      expect(sheet.consent.isGranted, isTrue);
      expect(sheet.consent.capturedAt, visitDate);
      expect(sheet.attachments, hasLength(1));
      expect(sheet.attachments.first.fileName, 'xray.jpg');
    });
  });

  group('CaseSheetAttachment', () {
    test('fromMap handles optional values', () {
      final attachment = CaseSheetAttachment.fromMap({
        'id': 'att-4',
        'storagePath': 'case_sheets/cs-4/att-4.pdf',
        'fileName': 'consent.pdf',
        'downloadUrl': 'https://example.com/consent.pdf',
        'contentType': 'application/pdf',
        'sizeBytes': 1024,
        'uploadedAt': Timestamp.fromDate(DateTime(2025, 4, 4, 11)),
      });

      expect(attachment.id, 'att-4');
      expect(attachment.fileName, 'consent.pdf');
      expect(attachment.uploadedAt, DateTime(2025, 4, 4, 11));
    });
  });

  group('CaseSheetConsent', () {
    test('copyWith updates provided properties', () {
      final consent = const CaseSheetConsent(
        isGranted: false,
        capturedBy: 'Guardian',
      );

      final updated = consent.copyWith(
        isGranted: true,
        capturedAt: DateTime(2025, 5, 5, 12),
      );

      expect(updated.isGranted, isTrue);
      expect(updated.capturedBy, 'Guardian');
      expect(updated.capturedAt, DateTime(2025, 5, 5, 12));
    });
  });
}
