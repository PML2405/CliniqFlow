import 'package:cliniqflow/features/appointments/data/appointment_repository.dart';
import 'package:cliniqflow/features/appointments/models/appointment.dart';
import 'package:cliniqflow/features/patients/models/patient_profile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

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

Future<Appointment> fetchAppointment(
  FirestoreAppointmentRepository repository,
  String id,
) async {
  final appointment = await repository.fetchById(id);
  expect(appointment, isNotNull);
  return appointment!;
}

void main() {
  group('FirestoreAppointmentRepository', () {
    late FakeFirebaseFirestore firestore;
    late FirestoreAppointmentRepository repository;
    late PatientProfile patient;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      repository = FirestoreAppointmentRepository(firestore);
      patient = buildPatient('patient-1');
    });

    test('create stores appointment and returns id', () async {
      final start = DateTime(2025, 5, 1, 9, 0);

      final id = await repository.create(
        patient: patient,
        start: start,
        durationMinutes: 60,
        purpose: 'Consultation',
      );

      final doc = await firestore.collection('appointments').doc(id).get();
      expect(doc.exists, isTrue);
      final data = doc.data()!;
      expect(data['patientId'], patient.id);
      expect(data['patientName'], patient.fullName);
      expect(data['purpose'], 'Consultation');
      expect(data['status'], 'scheduled');
      expect(data['start'], isA<Timestamp>());
      expect(data['end'], isA<Timestamp>());
    });

    test('watchRange returns appointments within range ordered by start', () async {
      final collection = firestore.collection('appointments');
      await collection.doc('early').set({
        'patientId': 'p1',
        'patientUid': 'u1',
        'patientName': 'Ann',
        'start': Timestamp.fromDate(DateTime(2025, 5, 2, 9)),
        'durationMinutes': 30,
        'purpose': 'Morning',
        'status': 'scheduled',
        'createdAt': Timestamp.fromDate(DateTime(2025, 5, 1)),
        'updatedAt': Timestamp.fromDate(DateTime(2025, 5, 1)),
      });
      await collection.doc('outside').set({
        'patientId': 'p2',
        'patientUid': 'u2',
        'patientName': 'Bev',
        'start': Timestamp.fromDate(DateTime(2025, 5, 5, 9)),
        'durationMinutes': 30,
        'purpose': 'Later',
        'status': 'scheduled',
        'createdAt': Timestamp.fromDate(DateTime(2025, 5, 1)),
        'updatedAt': Timestamp.fromDate(DateTime(2025, 5, 1)),
      });
      await collection.doc('late').set({
        'patientId': 'p3',
        'patientUid': 'u3',
        'patientName': 'Cal',
        'start': Timestamp.fromDate(DateTime(2025, 5, 3, 11)),
        'durationMinutes': 45,
        'purpose': 'Follow-up',
        'status': 'scheduled',
        'createdAt': Timestamp.fromDate(DateTime(2025, 5, 1)),
        'updatedAt': Timestamp.fromDate(DateTime(2025, 5, 1)),
      });

      final appointments = await repository.watchRange(
        start: DateTime(2025, 5, 2),
        end: DateTime(2025, 5, 4),
      ).first;

      expect(appointments.map((a) => a.id), ['early', 'late']);
    });

    test('fetchById returns null when missing', () async {
      expect(await repository.fetchById('missing'), isNull);
    });

    test('update modifies editable appointment', () async {
      final start = DateTime(2025, 5, 2, 10);
      final id = await repository.create(
        patient: patient,
        start: start,
        durationMinutes: 30,
        purpose: 'Initial',
      );
      final appointment = await fetchAppointment(repository, id);

      final newPatient = buildPatient('patient-2', name: 'Updated Patient');
      final newStart = start.add(const Duration(hours: 2));

      await repository.update(
        appointment: appointment,
        patient: newPatient,
        start: newStart,
        durationMinutes: 90,
        purpose: 'Updated Purpose',
      );

      final doc = await firestore.collection('appointments').doc(id).get();
      final data = doc.data()!;
      expect(data['patientId'], newPatient.id);
      expect(data['patientName'], newPatient.fullName);
      expect((data['start'] as Timestamp).toDate(), newStart);
      expect(data['durationMinutes'], 90);
      expect(data['purpose'], 'Updated Purpose');
    });

    test('update throws when appointment cannot be edited', () async {
      final collection = firestore.collection('appointments');
      await collection.doc('completed').set({
        'patientId': 'p',
        'patientUid': 'u',
        'patientName': 'Name',
        'start': Timestamp.fromDate(DateTime(2025, 6, 1, 10)),
        'durationMinutes': 30,
        'purpose': 'Done',
        'status': 'completed',
        'createdAt': Timestamp.fromDate(DateTime(2025, 6, 1, 9)),
        'updatedAt': Timestamp.fromDate(DateTime(2025, 6, 1, 9)),
      });

      final appointment = await fetchAppointment(repository, 'completed');

      await expectLater(
        repository.update(
          appointment: appointment,
          patient: patient,
          start: appointment.start,
          durationMinutes: appointment.durationMinutes,
          purpose: appointment.purpose,
        ),
        throwsStateError,
      );
    });

    test('create throws when slot conflicts', () async {
      final baseStart = DateTime(2025, 7, 10, 9);
      await repository.create(
        patient: patient,
        start: baseStart,
        durationMinutes: 60,
        purpose: 'Base',
      );

      await expectLater(
        repository.create(
          patient: buildPatient('patient-2'),
          start: baseStart.add(const Duration(minutes: 30)),
          durationMinutes: 60,
          purpose: 'Overlap',
        ),
        throwsStateError,
      );
    });

    test('update ignores conflict with the same appointment id', () async {
      final baseStart = DateTime(2025, 8, 1, 9);
      final id = await repository.create(
        patient: patient,
        start: baseStart,
        durationMinutes: 60,
        purpose: 'Morning',
      );
      final appointment = await fetchAppointment(repository, id);

      await repository.update(
        appointment: appointment,
        patient: patient,
        start: baseStart,
        durationMinutes: 60,
        purpose: 'Morning',
      );

      final doc = await firestore.collection('appointments').doc(id).get();
      expect(doc.exists, isTrue);
    });

    test('update throws when conflicting with another appointment', () async {
      final firstStart = DateTime(2025, 9, 1, 9);
      final secondStart = DateTime(2025, 9, 1, 11);

      final firstId = await repository.create(
        patient: patient,
        start: firstStart,
        durationMinutes: 60,
        purpose: 'First',
      );
      await repository.create(
        patient: buildPatient('patient-3'),
        start: secondStart,
        durationMinutes: 60,
        purpose: 'Second',
      );

      final appointment = await fetchAppointment(repository, firstId);

      await expectLater(
        repository.update(
          appointment: appointment,
          patient: patient,
          start: secondStart,
          durationMinutes: 60,
          purpose: 'Conflict',
        ),
        throwsStateError,
      );
    });

    test('cancel updates status when editable', () async {
      final id = await repository.create(
        patient: patient,
        start: DateTime(2025, 10, 1, 9),
        durationMinutes: 30,
        purpose: 'Cancelable',
      );
      final appointment = await fetchAppointment(repository, id);

      await repository.cancel(appointment);

      final doc = await firestore.collection('appointments').doc(id).get();
      expect(doc.data()!['status'], 'canceled');
    });

    test('cancel ignores non-editable appointment', () async {
      final collection = firestore.collection('appointments');
      await collection.doc('non-editable').set({
        'patientId': 'p',
        'patientUid': 'u',
        'patientName': 'Name',
        'start': Timestamp.fromDate(DateTime(2025, 11, 1, 9)),
        'durationMinutes': 30,
        'purpose': 'Done',
        'status': 'completed',
        'createdAt': Timestamp.fromDate(DateTime(2025, 11, 1)),
        'updatedAt': Timestamp.fromDate(DateTime(2025, 11, 1)),
      });

      final appointment = await fetchAppointment(repository, 'non-editable');
      await repository.cancel(appointment);

      final doc = await firestore.collection('appointments').doc('non-editable').get();
      expect(doc.data()!['status'], 'completed');
    });

    test('markCompleted sets status and timestamp', () async {
      final id = await repository.create(
        patient: patient,
        start: DateTime(2025, 12, 1, 9),
        durationMinutes: 45,
        purpose: 'Complete',
      );
      final appointment = await fetchAppointment(repository, id);

      await repository.markCompleted(appointment);

      final doc = await firestore.collection('appointments').doc(id).get();
      final data = doc.data()!;
      expect(data['status'], 'completed');
      expect(data['updatedAt'], isA<Timestamp>());
    });
  });
}
