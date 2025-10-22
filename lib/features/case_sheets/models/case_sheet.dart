import 'package:cloud_firestore/cloud_firestore.dart';

class CaseSheet {
  const CaseSheet({
    required this.id,
    required this.patientId,
    required this.patientUid,
    required this.patientName,
    required this.appointmentId,
    required this.doctorInCharge,
    required this.visitDate,
    required this.chiefComplaint,
    required this.provisionalDiagnosis,
    required this.treatmentPlan,
    required this.consent,
    required this.attachments,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String patientId;
  final String patientUid;
  final String patientName;
  final String appointmentId;
  final String doctorInCharge;
  final DateTime visitDate;
  final String chiefComplaint;
  final String provisionalDiagnosis;
  final String treatmentPlan;
  final CaseSheetConsent consent;
  final List<CaseSheetAttachment> attachments;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory CaseSheet.empty() {
    final now = DateTime.now();
    return CaseSheet(
      id: '',
      patientId: '',
      patientUid: '',
      patientName: '',
      appointmentId: '',
      doctorInCharge: '',
      visitDate: now,
      chiefComplaint: '',
      provisionalDiagnosis: '',
      treatmentPlan: '',
      consent: const CaseSheetConsent(isGranted: false),
      attachments: const <CaseSheetAttachment>[],
      createdAt: now,
      updatedAt: now,
    );
  }

  CaseSheet copyWith({
    String? id,
    String? patientId,
    String? patientUid,
    String? patientName,
    String? appointmentId,
    String? doctorInCharge,
    DateTime? visitDate,
    String? chiefComplaint,
    String? provisionalDiagnosis,
    String? treatmentPlan,
    CaseSheetConsent? consent,
    List<CaseSheetAttachment>? attachments,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CaseSheet(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      patientUid: patientUid ?? this.patientUid,
      patientName: patientName ?? this.patientName,
      appointmentId: appointmentId ?? this.appointmentId,
      doctorInCharge: doctorInCharge ?? this.doctorInCharge,
      visitDate: visitDate ?? this.visitDate,
      chiefComplaint: chiefComplaint ?? this.chiefComplaint,
      provisionalDiagnosis: provisionalDiagnosis ?? this.provisionalDiagnosis,
      treatmentPlan: treatmentPlan ?? this.treatmentPlan,
      consent: consent ?? this.consent,
      attachments: attachments ?? this.attachments,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'patientId': patientId,
      'patientUid': patientUid,
      'patientName': patientName,
      'appointmentId': appointmentId,
      'doctorInCharge': doctorInCharge,
      'visitDate': Timestamp.fromDate(visitDate),
      'chiefComplaint': chiefComplaint,
      'provisionalDiagnosis': provisionalDiagnosis,
      'treatmentPlan': treatmentPlan,
      'consent': consent.toMap(),
      'attachments': attachments.map((attachment) => attachment.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    }..removeWhere((key, value) => value == null);
  }

  factory CaseSheet.fromMap(String id, Map<String, dynamic> data) {
    final visitTimestamp = data['visitDate'] as Timestamp?;
    final createdTimestamp = data['createdAt'] as Timestamp?;
    final updatedTimestamp = data['updatedAt'] as Timestamp?;

    final attachmentsData = data['attachments'];
    final consentData = data['consent'] as Map<String, dynamic>?;

    return CaseSheet(
      id: id,
      patientId: data['patientId'] as String? ?? '',
      patientUid: data['patientUid'] as String? ?? '',
      patientName: data['patientName'] as String? ?? '',
      appointmentId: data['appointmentId'] as String? ?? '',
      doctorInCharge: data['doctorInCharge'] as String? ?? '',
      visitDate: visitTimestamp?.toDate() ?? DateTime.now(),
      chiefComplaint: data['chiefComplaint'] as String? ?? '',
      provisionalDiagnosis: data['provisionalDiagnosis'] as String? ?? '',
      treatmentPlan: data['treatmentPlan'] as String? ?? '',
      consent: CaseSheetConsent.fromMap(consentData ?? const {}),
      attachments: attachmentsData is Iterable
          ? List<CaseSheetAttachment>.from(
              attachmentsData.map(
                (item) => CaseSheetAttachment.fromMap(
                  Map<String, dynamic>.from(item as Map? ?? {}),
                ),
              ),
            )
          : const <CaseSheetAttachment>[],
      createdAt: createdTimestamp?.toDate() ?? DateTime.now(),
      updatedAt: updatedTimestamp?.toDate() ?? DateTime.now(),
    );
  }

  factory CaseSheet.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return CaseSheet.fromMap(doc.id, data);
  }
}

class CaseSheetAttachment {
  const CaseSheetAttachment({
    required this.id,
    required this.storagePath,
    required this.fileName,
    required this.downloadUrl,
    required this.contentType,
    required this.sizeBytes,
    required this.uploadedAt,
  });

  final String id;
  final String storagePath;
  final String fileName;
  final String downloadUrl;
  final String? contentType;
  final int? sizeBytes;
  final DateTime? uploadedAt;

  CaseSheetAttachment copyWith({
    String? id,
    String? storagePath,
    String? fileName,
    String? downloadUrl,
    String? contentType,
    int? sizeBytes,
    DateTime? uploadedAt,
  }) {
    return CaseSheetAttachment(
      id: id ?? this.id,
      storagePath: storagePath ?? this.storagePath,
      fileName: fileName ?? this.fileName,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      contentType: contentType ?? this.contentType,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      uploadedAt: uploadedAt ?? this.uploadedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'storagePath': storagePath,
      'fileName': fileName,
      'downloadUrl': downloadUrl,
      'contentType': contentType,
      'sizeBytes': sizeBytes,
      'uploadedAt': uploadedAt != null ? Timestamp.fromDate(uploadedAt!) : null,
    }..removeWhere((key, value) => value == null);
  }

  factory CaseSheetAttachment.fromMap(Map<String, dynamic> data) {
    final uploadedTimestamp = data['uploadedAt'] as Timestamp?;
    return CaseSheetAttachment(
      id: data['id'] as String? ?? '',
      storagePath: data['storagePath'] as String? ?? '',
      fileName: data['fileName'] as String? ?? '',
      downloadUrl: data['downloadUrl'] as String? ?? '',
      contentType: data['contentType'] as String?,
      sizeBytes: (data['sizeBytes'] as num?)?.toInt(),
      uploadedAt: uploadedTimestamp?.toDate(),
    );
  }
}

class CaseSheetConsent {
  const CaseSheetConsent({
    required this.isGranted,
    this.capturedBy,
    this.capturedAt,
  });

  final bool isGranted;
  final String? capturedBy;
  final DateTime? capturedAt;

  CaseSheetConsent copyWith({
    bool? isGranted,
    String? capturedBy,
    DateTime? capturedAt,
  }) {
    return CaseSheetConsent(
      isGranted: isGranted ?? this.isGranted,
      capturedBy: capturedBy ?? this.capturedBy,
      capturedAt: capturedAt ?? this.capturedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isGranted': isGranted,
      'capturedBy': capturedBy,
      'capturedAt': capturedAt != null ? Timestamp.fromDate(capturedAt!) : null,
    }..removeWhere((key, value) => value == null);
  }

  factory CaseSheetConsent.fromMap(Map<String, dynamic> data) {
    final capturedTimestamp = data['capturedAt'] as Timestamp?;
    return CaseSheetConsent(
      isGranted: data['isGranted'] as bool? ?? false,
      capturedBy: data['capturedBy'] as String?,
      capturedAt: capturedTimestamp?.toDate(),
    );
  }
}
