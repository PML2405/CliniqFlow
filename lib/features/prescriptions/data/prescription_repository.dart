import 'package:cloud_firestore/cloud_firestore.dart';

import '../../patients/models/patient_profile.dart';
import '../models/prescription.dart';

/// Repository interface for prescription data operations
abstract class PrescriptionRepository {
  /// Watch all prescriptions for a specific patient
  Stream<List<Prescription>> watchByPatient(String patientId);

  /// Fetch a single prescription by ID
  Future<Prescription?> fetchById(String id);

  /// Create a new prescription
  Future<String> create({
    required PatientProfile patient,
    required String doctorName,
    required DateTime prescriptionDate,
    required List<PrescriptionItem> items,
    String? caseSheetId,
  });

  /// Update prescription items
  Future<void> updateItems({
    required Prescription prescription,
    required List<PrescriptionItem> items,
  });

  /// Delete a prescription
  Future<void> delete(String id);
}

/// Firestore implementation of PrescriptionRepository
class FirestorePrescriptionRepository implements PrescriptionRepository {
  FirestorePrescriptionRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('prescriptions');

  @override
  Stream<List<Prescription>> watchByPatient(String patientId) {
    return _collection
        .where('patientId', isEqualTo: patientId)
        .orderBy('prescriptionDate', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(Prescription.fromDocument)
              .toList(growable: false),
        );
  }

  @override
  Future<Prescription?> fetchById(String id) async {
    final doc = await _collection.doc(id).get();
    if (!doc.exists) {
      return null;
    }
    return Prescription.fromDocument(doc);
  }

  @override
  Future<String> create({
    required PatientProfile patient,
    required String doctorName,
    required DateTime prescriptionDate,
    required List<PrescriptionItem> items,
    String? caseSheetId,
  }) async {
    final docRef = _collection.doc();
    final now = DateTime.now();

    final prescription = Prescription(
      id: docRef.id,
      patientId: patient.id,
      patientUid: patient.patientUid,
      patientName: patient.fullName,
      caseSheetId: caseSheetId,
      doctorName: doctorName,
      prescriptionDate: prescriptionDate,
      items: items,
      createdAt: now,
      updatedAt: now,
    );

    await docRef.set(prescription.toMap());
    return docRef.id;
  }

  @override
  Future<void> updateItems({
    required Prescription prescription,
    required List<PrescriptionItem> items,
  }) async {
    final updatedPrescription = prescription.copyWith(
      items: items,
      updatedAt: DateTime.now(),
    );

    await _collection.doc(prescription.id).update(
      updatedPrescription.toMap(),
    );
  }

  @override
  Future<void> delete(String id) async {
    await _collection.doc(id).delete();
  }
}
