import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:cliniqflow/features/appointments/data/appointment_repository.dart';
import 'package:cliniqflow/features/appointments/models/appointment.dart';
import 'package:cliniqflow/features/appointments/presentation/appointment_schedule_controller.dart';
import 'package:cliniqflow/features/patients/models/patient_profile.dart';

class FakeAppointmentRepository implements AppointmentRepository {
  FakeAppointmentRepository();

  final _controller = StreamController<List<Appointment>>.broadcast();
  List<Appointment>? _latest;

  void emit(List<Appointment> appointments) {
    _latest = appointments;
    _controller.add(appointments);
  }

  void dispose() {
    _controller.close();
  }

  @override
  Stream<List<Appointment>> watchRange({
    required DateTime start,
    required DateTime end,
  }) {
    final latestSnapshot = _latest;
    if (latestSnapshot != null) {
      scheduleMicrotask(() => _controller.add(latestSnapshot));
    }
    return _controller.stream;
  }

  @override
  Future<Appointment?> fetchById(String id) => throw UnimplementedError();

  @override
  Future<String> create({
    required PatientProfile patient,
    required DateTime start,
    required int durationMinutes,
    required String purpose,
  }) =>
      throw UnimplementedError();

  @override
  Future<void> update({
    required Appointment appointment,
    required PatientProfile patient,
    required DateTime start,
    required int durationMinutes,
    required String purpose,
  }) =>
      throw UnimplementedError();

  @override
  Future<void> cancel(Appointment appointment) => throw UnimplementedError();

  @override
  Future<void> markCompleted(Appointment appointment) => throw UnimplementedError();
}

Appointment buildAppointment({
  required String id,
  required AppointmentStatus status,
  required DateTime start,
  int durationMinutes = 30,
}) {
  final now = DateTime(2025, 1, 1);
  return Appointment(
    id: id,
    patientId: 'patient-$id',
    patientUid: 'uid-$id',
    patientName: 'Patient $id',
    start: start,
    durationMinutes: durationMinutes,
    purpose: 'Purpose $id',
    status: status,
    createdAt: now,
    updatedAt: now,
  );
}

Future<void> pumpEventQueue({int times = 1}) async {
  for (var i = 0; i < times; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  group('AppointmentScheduleController', () {
    late FakeAppointmentRepository repository;
    late AppointmentScheduleController controller;

    setUp(() {
      repository = FakeAppointmentRepository();
      controller = AppointmentScheduleController(repository);
    });

    tearDown(() {
      controller.dispose();
      repository.dispose();
    });

    test('aggregates daily summary for selected date', () async {
      final targetDate = DateTime(2025, 10, 15);

      controller.initialize();
      await pumpEventQueue();
      controller.setSelectedDate(targetDate);
      await pumpEventQueue();

      repository.emit([
        buildAppointment(
          id: 'scheduled',
          status: AppointmentStatus.scheduled,
          start: targetDate.add(const Duration(hours: 9)),
          durationMinutes: 45,
        ),
        buildAppointment(
          id: 'completed',
          status: AppointmentStatus.completed,
          start: targetDate.add(const Duration(hours: 11)),
        ),
        buildAppointment(
          id: 'canceled',
          status: AppointmentStatus.canceled,
          start: targetDate.add(const Duration(hours: 13)),
        ),
        buildAppointment(
          id: 'other-day',
          status: AppointmentStatus.scheduled,
          start: targetDate.add(const Duration(days: 1)),
        ),
      ]);

      await pumpEventQueue(times: 3);

      final summary = controller.daySummary;
      expect(summary.scheduledCount, 1);
      expect(summary.completedCount, 1);
      expect(summary.canceledCount, 1);
      expect(summary.bookedMinutes, 45);
      expect(summary.appointments.map((appointment) => appointment.id).toList(),
          ['scheduled', 'completed', 'canceled']);
    });

    test('filters appointments by status', () async {
      final targetDate = DateTime(2025, 10, 16);

      controller.initialize();
      await pumpEventQueue();
      controller.setSelectedDate(targetDate);
      await pumpEventQueue();

      repository.emit([
        buildAppointment(
          id: 'a',
          status: AppointmentStatus.scheduled,
          start: targetDate.add(const Duration(hours: 9)),
        ),
        buildAppointment(
          id: 'b',
          status: AppointmentStatus.completed,
          start: targetDate.add(const Duration(hours: 11)),
        ),
        buildAppointment(
          id: 'c',
          status: AppointmentStatus.canceled,
          start: targetDate.add(const Duration(hours: 13)),
        ),
      ]);

      await pumpEventQueue(times: 3);

      expect(controller.filteredAppointments.map((appointment) => appointment.id), ['a', 'b', 'c']);

      controller.setStatusFilter(AppointmentStatus.completed);
      await pumpEventQueue();
      expect(controller.filteredAppointments.map((appointment) => appointment.id), ['b']);

      controller.setStatusFilter(null);
      await pumpEventQueue();
      expect(controller.filteredAppointments.length, 3);
    });
  });
}
