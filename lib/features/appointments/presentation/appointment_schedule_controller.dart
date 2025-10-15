import 'dart:async';

import 'package:flutter/material.dart';

import '../../patients/models/patient_profile.dart';
import '../data/appointment_repository.dart';
import '../models/appointment.dart';

class AppointmentScheduleController extends ChangeNotifier {
  AppointmentScheduleController(this._repository);

  final AppointmentRepository _repository;
  StreamSubscription<List<Appointment>>? _subscription;

  DateTime _selectedDate = DateUtils.dateOnly(DateTime.now());
  List<Appointment> _appointments = const [];
  bool _isLoading = true;
  String? _errorMessage;
  AppointmentStatus? _statusFilter;

  DateTime get selectedDate => _selectedDate;
  List<Appointment> get appointments => _appointments;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  AppointmentStatus? get statusFilter => _statusFilter;

  List<Appointment> appointmentsForDate(DateTime date) {
    final target = DateUtils.dateOnly(date);
    return _appointments
        .where((appointment) => DateUtils.isSameDay(appointment.start, target))
        .toList(growable: false);
  }

  List<Appointment> get filteredAppointments {
    final daily = appointmentsForDate(_selectedDate);
    final filter = _statusFilter;
    if (filter == null) {
      return daily;
    }
    return daily
        .where((appointment) => appointment.status == filter)
        .toList(growable: false);
  }

  List<Appointment> get upcomingAppointments {
    final now = DateTime.now();
    return filteredAppointments
        .where((appointment) =>
            appointment.status.isActive && appointment.start.isAfter(now))
        .toList(growable: false);
  }

  AppointmentDaySummary get daySummary {
    final daily = filteredAppointments;
    final scheduled = daily
        .where((appointment) => appointment.status == AppointmentStatus.scheduled)
        .toList(growable: false);
    final completed =
        daily.where((appointment) => appointment.status == AppointmentStatus.completed).length;
    final canceled = daily.where((appointment) => appointment.status == AppointmentStatus.canceled).length;
    final bookedMinutes = scheduled.fold<int>(0, (sum, appointment) => sum + appointment.durationMinutes);

    return AppointmentDaySummary(
      scheduledCount: scheduled.length,
      completedCount: completed,
      canceledCount: canceled,
      bookedMinutes: bookedMinutes,
      appointments: daily,
    );
  }

  List<Appointment> get pastAppointments {
    final now = DateTime.now();
    return filteredAppointments
        .where((appointment) => appointment.status.isActive && appointment.start.isBefore(now))
        .toList(growable: false);
  }

  Appointment? get nextAppointment {
    return nextFilteredAppointment;
  }

  Appointment? get nextFilteredAppointment {
    final now = DateTime.now();
    final upcoming = filteredAppointments
        .where((appointment) =>
            appointment.status.isActive && appointment.start.isAfter(now))
        .toList(growable: false)
      ..sort((a, b) => a.start.compareTo(b.start));
    if (upcoming.isNotEmpty) {
      return upcoming.first;
    }

    final active = filteredAppointments
        .where((appointment) => appointment.status.isActive)
        .toList(growable: false)
      ..sort((a, b) => a.start.compareTo(b.start));
    if (active.isNotEmpty) {
      return active.first;
    }
    return null;
  }

  void initialize() {
    if (_subscription != null) {
      return;
    }
    _listenForDay(_selectedDate);
  }

  void refresh() {
    _listenForDay(_selectedDate);
  }

  void setSelectedDate(DateTime value) {
    final normalized = DateUtils.dateOnly(value);
    if (_selectedDate == normalized) {
      return;
    }
    _selectedDate = normalized;
    _listenForDay(_selectedDate);
    notifyListeners();
  }

  void setStatusFilter(AppointmentStatus? value) {
    if (_statusFilter == value) {
      return;
    }
    _statusFilter = value;
    notifyListeners();
  }

  Future<String> createAppointment({
    required PatientProfile patient,
    required DateTime date,
    required TimeOfDay time,
    required int durationMinutes,
    required String purpose,
  }) {
    final start = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    return _repository.create(
      patient: patient,
      start: start,
      durationMinutes: durationMinutes,
      purpose: purpose.trim(),
    );
  }

  Future<void> updateAppointment({
    required Appointment appointment,
    required PatientProfile patient,
    required DateTime date,
    required TimeOfDay time,
    required int durationMinutes,
    required String purpose,
  }) {
    final newStart = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    return _repository.update(
      appointment: appointment,
      patient: patient,
      start: newStart,
      durationMinutes: durationMinutes,
      purpose: purpose,
    );
  }

  Future<void> cancelAppointment(Appointment appointment) {
    return _repository.cancel(appointment);
  }

  Future<void> markAppointmentCompleted(Appointment appointment) {
    return _repository.markCompleted(appointment);
  }

  void _listenForDay(DateTime date) {
    _subscription?.cancel();
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));

    _subscription = _repository.watchRange(start: start, end: end).listen(
      (event) {
        _appointments = event;
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (Object error, StackTrace stackTrace) {
        _appointments = const [];
        _isLoading = false;
        _errorMessage = error.toString();
        notifyListeners();
      },
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

class AppointmentDaySummary {
  const AppointmentDaySummary({
    required this.scheduledCount,
    required this.completedCount,
    required this.canceledCount,
    required this.bookedMinutes,
    required this.appointments,
  });

  final int scheduledCount;
  final int completedCount;
  final int canceledCount;
  final int bookedMinutes;
  final List<Appointment> appointments;
}
