import 'package:cliniqflow/features/appointments/models/appointment.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Appointment', () {
    test('end computes based on duration', () {
      final start = DateTime(2025, 1, 1, 9, 0);
      final appointment = Appointment(
        id: 'a-1',
        patientId: 'p-1',
        patientUid: 'uid-1',
        patientName: 'Alice',
        start: start,
        durationMinutes: 45,
        purpose: 'Checkup',
        status: AppointmentStatus.scheduled,
        createdAt: start,
        updatedAt: start,
      );

      expect(appointment.end, DateTime(2025, 1, 1, 9, 45));
    });

    test('canEdit mirrors status', () {
      final base = Appointment.empty();
      expect(base.canEdit, isTrue);

      final completed = base.copyWith(status: AppointmentStatus.completed);
      expect(completed.canEdit, isFalse);

      final canceled = base.copyWith(status: AppointmentStatus.canceled);
      expect(canceled.canEdit, isFalse);
    });

    test('copyWith overrides provided fields', () {
      final start = DateTime(2025, 2, 3, 14, 0);
      final appointment = Appointment(
        id: 'a-2',
        patientId: 'p-2',
        patientUid: 'uid-2',
        patientName: 'Bob',
        start: start,
        durationMinutes: 30,
        purpose: 'Consult',
        status: AppointmentStatus.scheduled,
        createdAt: start,
        updatedAt: start,
      );

      final updated = appointment.copyWith(
        start: start.add(const Duration(hours: 1)),
        durationMinutes: 60,
        purpose: 'Follow-up',
        status: AppointmentStatus.completed,
      );

      expect(updated.start, start.add(const Duration(hours: 1)));
      expect(updated.durationMinutes, 60);
      expect(updated.purpose, 'Follow-up');
      expect(updated.status, AppointmentStatus.completed);
      expect(updated.patientId, 'p-2');
    });

    test('toMap serializes values and timestamps', () {
      final start = DateTime(2025, 3, 4, 11, 0);
      final appointment = Appointment(
        id: 'a-3',
        patientId: 'p-3',
        patientUid: 'uid-3',
        patientName: 'Carla',
        start: start,
        durationMinutes: 30,
        purpose: 'Dental',
        status: AppointmentStatus.canceled,
        createdAt: start,
        updatedAt: start.add(const Duration(minutes: 10)),
      );

      final map = appointment.toMap();

      expect(map['patientId'], 'p-3');
      expect(map['patientName'], 'Carla');
      expect(map['durationMinutes'], 30);
      expect(map['status'], 'canceled');
      expect(map['start'], isA<Timestamp>());
      expect(map['end'], isA<Timestamp>());
      expect(map['createdAt'], isA<Timestamp>());
      expect(map['updatedAt'], isA<Timestamp>());
    });

    test('fromDocument reads snapshot data with defaults', () async {
      final firestore = FakeFirebaseFirestore();
      final appointments = firestore.collection('appointments');
      await appointments.doc('doc-1').set({
        'patientId': 'p-4',
        'patientUid': 'uid-4',
        'patientName': 'Derek',
        'start': Timestamp.fromDate(DateTime(2025, 4, 5, 8, 30)),
        'durationMinutes': 50,
        'purpose': 'Therapy',
        'status': 'completed',
        'createdAt': Timestamp.fromDate(DateTime(2025, 4, 1, 9)),
        'updatedAt': Timestamp.fromDate(DateTime(2025, 4, 6, 9)),
      });

      final snapshot = await appointments.doc('doc-1').get();
      final appointment = Appointment.fromDocument(snapshot);

      expect(appointment.id, 'doc-1');
      expect(appointment.patientId, 'p-4');
      expect(appointment.patientName, 'Derek');
      expect(appointment.durationMinutes, 50);
      expect(appointment.status, AppointmentStatus.completed);
      expect(appointment.start, DateTime(2025, 4, 5, 8, 30));
    });

    test('AppointmentStatusX handles conversion and active flag', () {
      expect(AppointmentStatus.scheduled.value, 'scheduled');
      expect(AppointmentStatus.completed.value, 'completed');
      expect(AppointmentStatus.canceled.value, 'canceled');

      expect(AppointmentStatus.scheduled.isActive, isTrue);
      expect(AppointmentStatus.completed.isActive, isFalse);

      expect(AppointmentStatusX.fromValue('scheduled'), AppointmentStatus.scheduled);
      expect(AppointmentStatusX.fromValue('completed'), AppointmentStatus.completed);
      expect(AppointmentStatusX.fromValue('canceled'), AppointmentStatus.canceled);
      expect(AppointmentStatusX.fromValue('unknown'), AppointmentStatus.scheduled);
    });
  });
}
