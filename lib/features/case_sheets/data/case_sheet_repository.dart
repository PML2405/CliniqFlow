import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../appointments/models/appointment.dart';
import '../../patients/models/patient_profile.dart';
import '../models/case_sheet.dart';
import 'case_sheet_storage.dart';

abstract class CaseSheetRepository {
  Stream<List<CaseSheet>> watchByPatient(String patientId);

  Future<CaseSheet?> fetchById(String id);

  Future<String> create({
    required PatientProfile patient,
    required Appointment appointment,
    required DateTime visitDate,
    required String doctorInCharge,
    required String chiefComplaint,
    required String provisionalDiagnosis,
    required String treatmentPlan,
  });

  Future<void> updateDetails({
    required CaseSheet sheet,
    required String doctorInCharge,
    required String chiefComplaint,
    required String provisionalDiagnosis,
    required String treatmentPlan,
  });

  Future<void> recordConsent({
    required CaseSheet sheet,
    required CaseSheetConsent consent,
  });

  Future<void> replaceAttachments({
    required CaseSheet sheet,
    required List<CaseSheetAttachment> attachments,
  });

  Future<CaseSheetAttachment> uploadAttachment({
    required CaseSheet sheet,
    required String fileName,
    required String contentType,
    required Uint8List bytes,
  });
}

class FirestoreCaseSheetRepository implements CaseSheetRepository {
  FirestoreCaseSheetRepository(
    this._firestore, {
    CaseSheetStorageService? storage,
  }) : _storage = storage ?? CaseSheetStorageService();

  final FirebaseFirestore _firestore;
  final CaseSheetStorageService _storage;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('case_sheets');

  @override
  Stream<List<CaseSheet>> watchByPatient(String patientId) {
    return _collection
        .where('patientId', isEqualTo: patientId)
        .orderBy('visitDate', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(CaseSheet.fromDocument)
              .toList(growable: false),
        );
  }

  @override
  Future<CaseSheet?> fetchById(String id) async {
    final doc = await _collection.doc(id).get();
    if (!doc.exists) {
      return null;
    }
    return CaseSheet.fromDocument(doc);
  }

  @override
  Future<String> create({
    required PatientProfile patient,
    required Appointment appointment,
    required DateTime visitDate,
    required String doctorInCharge,
    required String chiefComplaint,
    required String provisionalDiagnosis,
    required String treatmentPlan,
  }) async {
    final docRef = _collection.doc();
    final now = DateTime.now();
    final sheet = CaseSheet(
      id: docRef.id,
      patientId: patient.id,
      patientUid: patient.patientUid,
      patientName: patient.fullName,
      appointmentId: appointment.id,
      doctorInCharge: doctorInCharge,
      visitDate: visitDate,
      chiefComplaint: chiefComplaint,
      provisionalDiagnosis: provisionalDiagnosis,
      treatmentPlan: treatmentPlan,
      consent: const CaseSheetConsent(isGranted: false),
      attachments: const <CaseSheetAttachment>[],
      createdAt: now,
      updatedAt: now,
    );

    await docRef.set(sheet.toMap());
    return docRef.id;
  }

  @override
  Future<void> updateDetails({
    required CaseSheet sheet,
    required String doctorInCharge,
    required String chiefComplaint,
    required String provisionalDiagnosis,
    required String treatmentPlan,
  }) async {
    final now = DateTime.now();
    await _collection.doc(sheet.id).update({
      'doctorInCharge': doctorInCharge,
      'chiefComplaint': chiefComplaint,
      'provisionalDiagnosis': provisionalDiagnosis,
      'treatmentPlan': treatmentPlan,
      'updatedAt': Timestamp.fromDate(now),
    });
  }

  @override
  Future<void> recordConsent({
    required CaseSheet sheet,
    required CaseSheetConsent consent,
  }) async {
    await _collection.doc(sheet.id).update({
      'consent': consent.toMap(),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  @override
  Future<void> replaceAttachments({
    required CaseSheet sheet,
    required List<CaseSheetAttachment> attachments,
  }) async {
    await _collection.doc(sheet.id).update({
      'attachments': attachments.map((attachment) => attachment.toMap()).toList(),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  @override
  Future<CaseSheetAttachment> uploadAttachment({
    required CaseSheet sheet,
    required String fileName,
    required String contentType,
    required Uint8List bytes,
  }) async {
    final attachment = await _storage.uploadAttachment(
      caseSheetId: sheet.id,
      fileName: fileName,
      bytes: bytes,
      contentType: contentType,
    );

    final updatedAttachments = List<CaseSheetAttachment>.from(sheet.attachments)
      ..add(attachment);

    await replaceAttachments(sheet: sheet, attachments: updatedAttachments);

    return attachment;
  }
}
