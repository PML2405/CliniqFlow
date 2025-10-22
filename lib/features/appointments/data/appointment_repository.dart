import 'package:cloud_firestore/cloud_firestore.dart';

import '../../patients/models/patient_profile.dart';
import '../models/appointment.dart';

abstract class AppointmentRepository {
  Stream<List<Appointment>> watchRange({
    required DateTime start,
    required DateTime end,
  });

  Future<Appointment?> fetchById(String id);
  Future<String> create({
    required PatientProfile patient,
    required DateTime start,
    required int durationMinutes,
    required String purpose,
  });

  Future<void> update({
    required Appointment appointment,
    required PatientProfile patient,
    required DateTime start,
    required int durationMinutes,
    required String purpose,
  });

  Future<void> cancel(Appointment appointment);
  Future<void> markCompleted(Appointment appointment);
}

class FirestoreAppointmentRepository implements AppointmentRepository {
  FirestoreAppointmentRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('appointments');

  @override
  Stream<List<Appointment>> watchRange({
    required DateTime start,
    required DateTime end,
  }) {
    final startTs = Timestamp.fromDate(start);
    final endTs = Timestamp.fromDate(end);
    return _collection
        .where('start', isGreaterThanOrEqualTo: startTs)
        .where('start', isLessThan: endTs)
        .orderBy('start')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(Appointment.fromDocument)
              .toList(growable: false),
        );
  }

  @override
  Future<Appointment?> fetchById(String id) async {
    final doc = await _collection.doc(id).get();
    if (!doc.exists) {
      return null;
    }
    return Appointment.fromDocument(doc);
  }

  @override
  Future<String> create({
    required PatientProfile patient,
    required DateTime start,
    required int durationMinutes,
    required String purpose,
  }) async {
    await _assertSlotAvailable(
      start: start,
      durationMinutes: durationMinutes,
      excludeId: null,
    );

    final docRef = _collection.doc();
    final now = DateTime.now();
    final appointment = Appointment(
      id: docRef.id,
      patientId: patient.id,
      patientUid: patient.patientUid,
      patientName: patient.fullName,
      start: start,
      durationMinutes: durationMinutes,
      purpose: purpose,
      status: AppointmentStatus.scheduled,
      createdAt: now,
      updatedAt: now,
    );

    await docRef.set(appointment.toMap());
    return docRef.id;
  }

  @override
  Future<void> update({
    required Appointment appointment,
    required PatientProfile patient,
    required DateTime start,
    required int durationMinutes,
    required String purpose,
  }) async {
    if (!appointment.canEdit) {
      throw StateError('Cannot edit an appointment that is ${appointment.status.value}');
    }

    await _assertSlotAvailable(
      start: start,
      durationMinutes: durationMinutes,
      excludeId: appointment.id,
    );

    final now = DateTime.now();
    final payload = appointment
        .copyWith(
          patientId: patient.id,
          patientUid: patient.patientUid,
          patientName: patient.fullName,
          start: start,
          durationMinutes: durationMinutes,
          purpose: purpose,
          updatedAt: now,
        )
        .toMap();

    await _collection.doc(appointment.id).update(payload);
  }

  @override
  Future<void> cancel(Appointment appointment) {
    if (!appointment.canEdit) {
      return Future.value();
    }

    final now = DateTime.now();
    return _collection.doc(appointment.id).update({
      'status': AppointmentStatus.canceled.value,
      'updatedAt': Timestamp.fromDate(now),
    });
  }

  @override
  Future<void> markCompleted(Appointment appointment) {
    final now = DateTime.now();
    return _collection.doc(appointment.id).update({
      'status': AppointmentStatus.completed.value,
      'updatedAt': Timestamp.fromDate(now),
    });
  }

  Future<void> _assertSlotAvailable({
    required DateTime start,
    required int durationMinutes,
    required String? excludeId,
  }) async {
    final end = start.add(Duration(minutes: durationMinutes));
    final endTs = Timestamp.fromDate(end);

    final query = await _collection
        .where('status', isEqualTo: AppointmentStatus.scheduled.value)
        .where('start', isLessThan: endTs)
        .get();

    final hasConflict = query.docs.any((doc) {
      if (doc.id == excludeId) {
        return false;
      }
      final data = doc.data();
      final existingStart = (data['start'] as Timestamp).toDate();
      final existingEnd = data['end'] is Timestamp
          ? (data['end'] as Timestamp).toDate()
          : existingStart.add(Duration(minutes: data['durationMinutes'] as int? ?? 0));
      final startsBeforeEnd = existingStart.isBefore(end) || existingStart.isAtSameMomentAs(end);
      final endsAfterStart = existingEnd.isAfter(start) || existingEnd.isAtSameMomentAs(start);
      return startsBeforeEnd && endsAfterStart;
    });

    if (hasConflict) {
      throw StateError('Appointment slot conflicts with an existing booking');
    }
  }
}
