import 'package:cloud_firestore/cloud_firestore.dart';

enum AppointmentStatus { scheduled, completed, canceled }

extension AppointmentStatusX on AppointmentStatus {
  String get value {
    switch (this) {
      case AppointmentStatus.scheduled:
        return 'scheduled';
      case AppointmentStatus.completed:
        return 'completed';
      case AppointmentStatus.canceled:
        return 'canceled';
    }
  }

  bool get isActive => this == AppointmentStatus.scheduled;

  static AppointmentStatus fromValue(String value) {
    switch (value) {
      case 'completed':
        return AppointmentStatus.completed;
      case 'canceled':
        return AppointmentStatus.canceled;
      case 'scheduled':
      default:
        return AppointmentStatus.scheduled;
    }
  }
}

class Appointment {
  Appointment({
    required this.id,
    required this.patientId,
    required this.patientUid,
    required this.patientName,
    required this.start,
    required this.durationMinutes,
    required this.purpose,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Appointment.empty() {
    final now = DateTime.now();
    return Appointment(
      id: '',
      patientId: '',
      patientUid: '',
      patientName: '',
      start: now,
      durationMinutes: 30,
      purpose: '',
      status: AppointmentStatus.scheduled,
      createdAt: now,
      updatedAt: now,
    );
  }

  factory Appointment.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    final startTimestamp = data['start'] as Timestamp?;
    final createdTimestamp = data['createdAt'] as Timestamp?;
    final updatedTimestamp = data['updatedAt'] as Timestamp?;
    return Appointment(
      id: doc.id,
      patientId: data['patientId'] as String? ?? '',
      patientUid: data['patientUid'] as String? ?? '',
      patientName: data['patientName'] as String? ?? '',
      start: startTimestamp != null ? startTimestamp.toDate() : DateTime.now(),
      durationMinutes: data['durationMinutes'] as int? ?? 30,
      purpose: data['purpose'] as String? ?? '',
      status: AppointmentStatusX.fromValue(data['status'] as String? ?? 'scheduled'),
      createdAt: createdTimestamp != null ? createdTimestamp.toDate() : DateTime.now(),
      updatedAt: updatedTimestamp != null ? updatedTimestamp.toDate() : DateTime.now(),
    );
  }

  final String id;
  final String patientId;
  final String patientUid;
  final String patientName;
  final DateTime start;
  final int durationMinutes;
  final String purpose;
  final AppointmentStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  DateTime get end => start.add(Duration(minutes: durationMinutes));

  bool get canEdit => status.isActive;

  Appointment copyWith({
    String? id,
    String? patientId,
    String? patientUid,
    String? patientName,
    DateTime? start,
    int? durationMinutes,
    String? purpose,
    AppointmentStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Appointment(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      patientUid: patientUid ?? this.patientUid,
      patientName: patientName ?? this.patientName,
      start: start ?? this.start,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      purpose: purpose ?? this.purpose,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'patientId': patientId,
      'patientUid': patientUid,
      'patientName': patientName,
      'start': Timestamp.fromDate(start),
      'end': Timestamp.fromDate(end),
      'durationMinutes': durationMinutes,
      'purpose': purpose,
      'status': status.value,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
