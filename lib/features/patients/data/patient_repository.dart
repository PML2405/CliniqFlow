import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/patient_profile.dart';

abstract class PatientRepository {
  Stream<List<PatientProfile>> watchAll();
  Future<PatientProfile?> fetchById(String id);
  Future<String> create(PatientProfile profile);
  Future<void> update(PatientProfile profile);
  Future<void> delete(String id);
}

class FirestorePatientRepository implements PatientRepository {
  FirestorePatientRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('patients');

  @override
  Stream<List<PatientProfile>> watchAll() {
    return _collection.orderBy('fullName').snapshots().map((snapshot) {
      return snapshot.docs
          .map(PatientProfile.fromDocument)
          .toList(growable: false);
    });
  }

  @override
  Future<PatientProfile?> fetchById(String id) async {
    final doc = await _collection.doc(id).get();
    if (!doc.exists) {
      return null;
    }
    return PatientProfile.fromDocument(doc);
  }

  @override
  Future<String> create(PatientProfile profile) async {
    final docRef = _collection.doc();
    final now = DateTime.now();
    final generatedUid =
        profile.patientUid.isEmpty ? docRef.id : profile.patientUid;
    final payload = profile.copyWith(
      id: docRef.id,
      patientUid: generatedUid,
      createdAt: now,
      updatedAt: now,
    );
    await docRef.set(payload.toMap());
    return docRef.id;
  }

  @override
  Future<void> update(PatientProfile profile) async {
    if (profile.id.isEmpty) {
      throw ArgumentError('PatientProfile.id cannot be empty for update');
    }
    final now = DateTime.now();
    final effectiveProfile = profile.patientUid.isEmpty
        ? profile.copyWith(patientUid: profile.id)
        : profile;
    final payload = effectiveProfile.copyWith(updatedAt: now).toMap();
    await _collection.doc(profile.id).update(payload);
    await _updateAppointmentsForPatient(effectiveProfile, now);
  }

  @override
  Future<void> delete(String id) {
    return _collection.doc(id).delete();
  }

  Future<void> _updateAppointmentsForPatient(
    PatientProfile profile,
    DateTime timestamp,
  ) async {
    final query = await _firestore
        .collection('appointments')
        .where('patientId', isEqualTo: profile.id)
        .get();

    if (query.docs.isEmpty) {
      return;
    }

    final batch = _firestore.batch();
    final updatePayload = {
      'patientUid': profile.patientUid,
      'patientName': profile.fullName,
      'updatedAt': Timestamp.fromDate(timestamp),
    };

    for (final doc in query.docs) {
      batch.update(doc.reference, updatePayload);
    }

    await batch.commit();
  }
}
