import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cliniqflow/features/appointments/data/appointment_repository.dart';
import 'package:cliniqflow/features/appointments/models/appointment.dart';
import 'package:cliniqflow/features/appointments/presentation/appointment_schedule_controller.dart';
import 'package:cliniqflow/features/patients/models/patient_profile.dart';

class FakeAppointmentRepository implements AppointmentRepository {
  FakeAppointmentRepository();

  final _controller = StreamController<List<Appointment>>.broadcast();
  List<Appointment>? _latest;
  Completer<void>? _createCompleter;
  Completer<void>? _updateCompleter;
  Completer<void>? _cancelCompleter;
  Completer<void>? _markCompleter;

  int createCallCount = 0;
  PatientProfile? lastCreatedPatient;
  DateTime? lastCreateStart;
  int? lastCreateDuration;
  String? lastCreatePurpose;
  String createReturnId = 'created-id';

  int updateCallCount = 0;
  Appointment? lastUpdatedAppointment;
  PatientProfile? lastUpdatedPatient;
  DateTime? lastUpdateStart;
  int? lastUpdateDuration;
  String? lastUpdatePurpose;

  int cancelCallCount = 0;
  Appointment? lastCanceledAppointment;

  int markCompletedCallCount = 0;
  Appointment? lastMarkedCompletedAppointment;

  void emit(List<Appointment> appointments) {
    _latest = appointments;
    _controller.add(appointments);
  }

  void dispose() {
    _controller.close();
  }

  Future<void> waitForCreateCall() {
    _createCompleter = Completer<void>();
    return _createCompleter!.future;
  }

  Future<void> waitForUpdateCall() {
    _updateCompleter = Completer<void>();
    return _updateCompleter!.future;
  }

  Future<void> waitForCancelCall() {
    _cancelCompleter = Completer<void>();
    return _cancelCompleter!.future;
  }

  Future<void> waitForMarkCompleteCall() {
    _markCompleter = Completer<void>();
    return _markCompleter!.future;
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
  }) {
    createCallCount += 1;
    lastCreatedPatient = patient;
    lastCreateStart = start;
    lastCreateDuration = durationMinutes;
    lastCreatePurpose = purpose;
    final completer = _createCompleter;
    if (completer != null && !completer.isCompleted) {
      completer.complete();
    }
    _createCompleter = null;
    return Future.value(createReturnId);
  }

  @override
  Future<void> update({
    required Appointment appointment,
    required PatientProfile patient,
    required DateTime start,
    required int durationMinutes,
    required String purpose,
  }) {
    updateCallCount += 1;
    lastUpdatedAppointment = appointment;
    lastUpdatedPatient = patient;
    lastUpdateStart = start;
    lastUpdateDuration = durationMinutes;
    lastUpdatePurpose = purpose;
    final completer = _updateCompleter;
    if (completer != null && !completer.isCompleted) {
      completer.complete();
    }
    _updateCompleter = null;
    return Future.value();
  }

  @override
  Future<void> cancel(Appointment appointment) {
    cancelCallCount += 1;
    lastCanceledAppointment = appointment;
    final completer = _cancelCompleter;
    if (completer != null && !completer.isCompleted) {
      completer.complete();
    }
    _cancelCompleter = null;
    return Future.value();
  }

  @override
  Future<void> markCompleted(Appointment appointment) {
    markCompletedCallCount += 1;
    lastMarkedCompletedAppointment = appointment;
    final completer = _markCompleter;
    if (completer != null && !completer.isCompleted) {
      completer.complete();
    }
    _markCompleter = null;
    return Future.value();
  }
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

    test('appointmentsForDate filters by calendar day', () async {
      final selectedDate = DateTime(2025, 10, 18);

      controller.initialize();
      await pumpEventQueue();
      controller.setSelectedDate(selectedDate);
      await pumpEventQueue();

      repository.emit([
        buildAppointment(
          id: 'same-day',
          status: AppointmentStatus.scheduled,
          start: selectedDate.add(const Duration(hours: 10)),
        ),
        buildAppointment(
          id: 'other-day',
          status: AppointmentStatus.scheduled,
          start: selectedDate.add(const Duration(days: 1)),
        ),
      ]);

      await pumpEventQueue(times: 3);

      final result = controller.appointmentsForDate(selectedDate);
      expect(result.map((appointment) => appointment.id).toList(), ['same-day']);
    });

    test('upcomingAppointments and nextAppointment return future active visits', () async {
      final selectedDate = DateTime.now().add(const Duration(days: 2));

      controller.initialize();
      await pumpEventQueue();
      controller.setSelectedDate(selectedDate);
      await pumpEventQueue();

      final morning = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 9);
      final evening = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 18);

      repository.emit([
        buildAppointment(
          id: 'morning',
          status: AppointmentStatus.scheduled,
          start: morning,
        ),
        buildAppointment(
          id: 'evening',
          status: AppointmentStatus.completed,
          start: evening,
        ),
      ]);

      await pumpEventQueue(times: 3);

      expect(controller.upcomingAppointments.map((appointment) => appointment.id), ['morning']);
      expect(controller.nextAppointment?.id, 'morning');
      expect(controller.nextFilteredAppointment?.id, 'morning');
    });

    test('pastAppointments returns prior scheduled visits on past date', () async {
      final selectedDate = DateTime.now().subtract(const Duration(days: 1));

      controller.initialize();
      await pumpEventQueue();
      controller.setSelectedDate(selectedDate);
      await pumpEventQueue();

      final morning = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 9);
      final afternoon = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 14);

      repository.emit([
        buildAppointment(
          id: 'morning',
          status: AppointmentStatus.scheduled,
          start: morning,
        ),
        buildAppointment(
          id: 'afternoon',
          status: AppointmentStatus.canceled,
          start: afternoon,
        ),
      ]);

      await pumpEventQueue(times: 3);

      expect(controller.pastAppointments.map((appointment) => appointment.id), ['morning']);
      expect(controller.nextFilteredAppointment?.id, 'morning');
    });

    test('createAppointment delegates to repository with normalized start', () async {
      final patient = PatientProfile.empty();
      repository.createReturnId = 'new-id';
      final wait = repository.waitForCreateCall();
      final date = DateTime(2025, 11, 1);
      final time = const TimeOfDay(hour: 14, minute: 30);

      final future = controller.createAppointment(
        patient: patient,
        date: date,
        time: time,
        durationMinutes: 45,
        purpose: '  Checkup  ',
      );

      await wait;
      final id = await future;

      expect(id, 'new-id');
      expect(repository.createCallCount, 1);
      expect(repository.lastCreatedPatient, patient);
      expect(repository.lastCreateStart, DateTime(2025, 11, 1, 14, 30));
      expect(repository.lastCreateDuration, 45);
      expect(repository.lastCreatePurpose, 'Checkup');
    });

    test('updateAppointment delegates with converted start and duration', () async {
      final patient = PatientProfile.empty();
      final appointment = buildAppointment(
        id: 'appt',
        status: AppointmentStatus.scheduled,
        start: DateTime(2025, 12, 1, 9),
      );

      final wait = repository.waitForUpdateCall();
      final date = DateTime(2025, 12, 2);
      final time = const TimeOfDay(hour: 10, minute: 15);

      final future = controller.updateAppointment(
        appointment: appointment,
        patient: patient,
        date: date,
        time: time,
        durationMinutes: 60,
        purpose: 'Follow up',
      );

      await wait;
      await future;

      expect(repository.updateCallCount, 1);
      expect(repository.lastUpdatedAppointment, appointment);
      expect(repository.lastUpdatedPatient, patient);
      expect(repository.lastUpdateStart, DateTime(2025, 12, 2, 10, 15));
      expect(repository.lastUpdateDuration, 60);
      expect(repository.lastUpdatePurpose, 'Follow up');
    });

    test('cancel and markCompleted delegate to repository', () async {
      final appointment = buildAppointment(
        id: 'cancel-me',
        status: AppointmentStatus.scheduled,
        start: DateTime(2026, 1, 1, 9),
      );

      final cancelWait = repository.waitForCancelCall();
      final cancelFuture = controller.cancelAppointment(appointment);
      await cancelWait;
      await cancelFuture;

      expect(repository.cancelCallCount, 1);
      expect(repository.lastCanceledAppointment, appointment);

      final markWait = repository.waitForMarkCompleteCall();
      final markFuture = controller.markAppointmentCompleted(appointment);
      await markWait;
      await markFuture;

      expect(repository.markCompletedCallCount, 1);
      expect(repository.lastMarkedCompletedAppointment, appointment);
    });
  });
}
