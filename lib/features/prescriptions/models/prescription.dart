import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a prescription for a patient visit
class Prescription {
  const Prescription({
    required this.id,
    required this.patientId,
    required this.patientUid,
    required this.patientName,
    required this.caseSheetId,
    required this.doctorName,
    required this.prescriptionDate,
    required this.items,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String patientId;
  final String patientUid;
  final String patientName;
  final String? caseSheetId;
  final String doctorName;
  final DateTime prescriptionDate;
  final List<PrescriptionItem> items;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory Prescription.empty() {
    final now = DateTime.now();
    return Prescription(
      id: '',
      patientId: '',
      patientUid: '',
      patientName: '',
      caseSheetId: null,
      doctorName: '',
      prescriptionDate: now,
      items: const <PrescriptionItem>[],
      createdAt: now,
      updatedAt: now,
    );
  }

  Prescription copyWith({
    String? id,
    String? patientId,
    String? patientUid,
    String? patientName,
    String? caseSheetId,
    String? doctorName,
    DateTime? prescriptionDate,
    List<PrescriptionItem>? items,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Prescription(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      patientUid: patientUid ?? this.patientUid,
      patientName: patientName ?? this.patientName,
      caseSheetId: caseSheetId ?? this.caseSheetId,
      doctorName: doctorName ?? this.doctorName,
      prescriptionDate: prescriptionDate ?? this.prescriptionDate,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'patientId': patientId,
      'patientUid': patientUid,
      'patientName': patientName,
      'caseSheetId': caseSheetId,
      'doctorName': doctorName,
      'prescriptionDate': Timestamp.fromDate(prescriptionDate),
      'items': items.map((item) => item.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    }..removeWhere((key, value) => value == null);
  }

  factory Prescription.fromMap(String id, Map<String, dynamic> data) {
    final prescriptionTimestamp = data['prescriptionDate'] as Timestamp?;
    final createdTimestamp = data['createdAt'] as Timestamp?;
    final updatedTimestamp = data['updatedAt'] as Timestamp?;

    final itemsData = data['items'];

    return Prescription(
      id: id,
      patientId: data['patientId'] as String? ?? '',
      patientUid: data['patientUid'] as String? ?? '',
      patientName: data['patientName'] as String? ?? '',
      caseSheetId: data['caseSheetId'] as String?,
      doctorName: data['doctorName'] as String? ?? '',
      prescriptionDate: prescriptionTimestamp?.toDate() ?? DateTime.now(),
      items: itemsData is Iterable
          ? List<PrescriptionItem>.from(
              itemsData.map(
                (item) => PrescriptionItem.fromMap(
                  Map<String, dynamic>.from(item as Map? ?? {}),
                ),
              ),
            )
          : const <PrescriptionItem>[],
      createdAt: createdTimestamp?.toDate() ?? DateTime.now(),
      updatedAt: updatedTimestamp?.toDate() ?? DateTime.now(),
    );
  }

  factory Prescription.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return Prescription.fromMap(doc.id, data);
  }
}

/// Represents a single medication item in a prescription
class PrescriptionItem {
  const PrescriptionItem({
    required this.id,
    required this.drugName,
    required this.dosage,
    required this.frequency,
    required this.duration,
    this.notes,
  });

  final String id;
  final String drugName;
  final String dosage;
  final String frequency;
  final String duration;
  final String? notes;

  PrescriptionItem copyWith({
    String? id,
    String? drugName,
    String? dosage,
    String? frequency,
    String? duration,
    String? notes,
  }) {
    return PrescriptionItem(
      id: id ?? this.id,
      drugName: drugName ?? this.drugName,
      dosage: dosage ?? this.dosage,
      frequency: frequency ?? this.frequency,
      duration: duration ?? this.duration,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'drugName': drugName,
      'dosage': dosage,
      'frequency': frequency,
      'duration': duration,
      'notes': notes,
    }..removeWhere((key, value) => value == null);
  }

  factory PrescriptionItem.fromMap(Map<String, dynamic> data) {
    return PrescriptionItem(
      id: data['id'] as String? ?? '',
      drugName: data['drugName'] as String? ?? '',
      dosage: data['dosage'] as String? ?? '',
      frequency: data['frequency'] as String? ?? '',
      duration: data['duration'] as String? ?? '',
      notes: data['notes'] as String?,
    );
  }
}
