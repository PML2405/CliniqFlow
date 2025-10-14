import 'package:cloud_firestore/cloud_firestore.dart';

class PatientProfile {
  const PatientProfile({
    required this.id,
    required this.patientUid,
    required this.fullName,
    required this.registrationDate,
    this.dateOfBirth,
    this.age,
    this.sex,
    required this.contactInfo,
    required this.emergencyContact,
    required this.medicalHistory,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String patientUid;
  final String fullName;
  final DateTime registrationDate;
  final DateTime? dateOfBirth;
  final int? age;
  final String? sex;
  final ContactInfo contactInfo;
  final EmergencyContact emergencyContact;
  final MedicalHistory medicalHistory;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory PatientProfile.empty() {
    final now = DateTime.now();
    return PatientProfile(
      id: '',
      patientUid: '',
      fullName: '',
      registrationDate: now,
      contactInfo: const ContactInfo(),
      emergencyContact: const EmergencyContact(),
      medicalHistory: const MedicalHistory(),
      createdAt: now,
      updatedAt: now,
    );
  }

  String get primaryPhone =>
      contactInfo.residentialPhone ?? contactInfo.officePhone ??
      emergencyContact.mobilePhone ?? emergencyContact.officePhone ?? '';

  PatientProfile copyWith({
    String? id,
    String? patientUid,
    String? fullName,
    DateTime? registrationDate,
    DateTime? dateOfBirth,
    int? age,
    String? sex,
    ContactInfo? contactInfo,
    EmergencyContact? emergencyContact,
    MedicalHistory? medicalHistory,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PatientProfile(
      id: id ?? this.id,
      patientUid: patientUid ?? this.patientUid,
      fullName: fullName ?? this.fullName,
      registrationDate: registrationDate ?? this.registrationDate,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      age: age ?? this.age,
      sex: sex ?? this.sex,
      contactInfo: contactInfo ?? this.contactInfo,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      medicalHistory: medicalHistory ?? this.medicalHistory,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'patientUid': patientUid,
      'fullName': fullName,
      'registrationDate': Timestamp.fromDate(registrationDate),
      'dateOfBirth': dateOfBirth != null ? Timestamp.fromDate(dateOfBirth!) : null,
      'age': age,
      'sex': sex,
      'contactInfo': contactInfo.toMap(),
      'emergencyContact': emergencyContact.toMap(),
      'medicalHistory': medicalHistory.toMap(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };

    map.removeWhere((key, value) => value == null);
    return map;
  }

  factory PatientProfile.fromMap(String id, Map<String, dynamic> data) {
    final registrationTimestamp = data['registrationDate'] as Timestamp?;
    final dobTimestamp = data['dateOfBirth'] as Timestamp?;
    final createdTimestamp = data['createdAt'] as Timestamp?;
    final updatedTimestamp = data['updatedAt'] as Timestamp?;

    return PatientProfile(
      id: id,
      patientUid: data['patientUid'] as String? ?? '',
      fullName: data['fullName'] as String? ?? '',
      registrationDate: registrationTimestamp?.toDate() ?? DateTime.now(),
      dateOfBirth: dobTimestamp?.toDate(),
      age: (data['age'] as num?)?.toInt(),
      sex: data['sex'] as String?,
      contactInfo: ContactInfo.fromMap(
        Map<String, dynamic>.from(data['contactInfo'] as Map? ?? {}),
      ),
      emergencyContact: EmergencyContact.fromMap(
        Map<String, dynamic>.from(data['emergencyContact'] as Map? ?? {}),
      ),
      medicalHistory: MedicalHistory.fromMap(
        Map<String, dynamic>.from(data['medicalHistory'] as Map? ?? {}),
      ),
      createdAt: createdTimestamp?.toDate() ?? DateTime.now(),
      updatedAt: updatedTimestamp?.toDate() ?? DateTime.now(),
    );
  }

  factory PatientProfile.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return PatientProfile.fromMap(doc.id, data);
  }
}

class ContactInfo {
  const ContactInfo({
    this.address,
    this.occupation,
    this.email,
    this.residentialPhone,
    this.officePhone,
  });

  final String? address;
  final String? occupation;
  final String? email;
  final String? residentialPhone;
  final String? officePhone;

  ContactInfo copyWith({
    String? address,
    String? occupation,
    String? email,
    String? residentialPhone,
    String? officePhone,
  }) {
    return ContactInfo(
      address: address ?? this.address,
      occupation: occupation ?? this.occupation,
      email: email ?? this.email,
      residentialPhone: residentialPhone ?? this.residentialPhone,
      officePhone: officePhone ?? this.officePhone,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'address': address,
      'occupation': occupation,
      'email': email,
      'residentialPhone': residentialPhone,
      'officePhone': officePhone,
    };

    map.removeWhere((key, value) => value == null);
    return map;
  }

  factory ContactInfo.fromMap(Map<String, dynamic> data) {
    return ContactInfo(
      address: data['address'] as String?,
      occupation: data['occupation'] as String?,
      email: data['email'] as String?,
      residentialPhone: data['residentialPhone'] as String?,
      officePhone: data['officePhone'] as String?,
    );
  }
}

class EmergencyContact {
  const EmergencyContact({
    this.name,
    this.relation,
    this.mobilePhone,
    this.officePhone,
  });

  final String? name;
  final String? relation;
  final String? mobilePhone;
  final String? officePhone;

  EmergencyContact copyWith({
    String? name,
    String? relation,
    String? mobilePhone,
    String? officePhone,
  }) {
    return EmergencyContact(
      name: name ?? this.name,
      relation: relation ?? this.relation,
      mobilePhone: mobilePhone ?? this.mobilePhone,
      officePhone: officePhone ?? this.officePhone,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'name': name,
      'relation': relation,
      'mobilePhone': mobilePhone,
      'officePhone': officePhone,
    };

    map.removeWhere((key, value) => value == null);
    return map;
  }

  factory EmergencyContact.fromMap(Map<String, dynamic> data) {
    return EmergencyContact(
      name: data['name'] as String?,
      relation: data['relation'] as String?,
      mobilePhone: data['mobilePhone'] as String?,
      officePhone: data['officePhone'] as String?,
    );
  }
}

class MedicalHistory {
  const MedicalHistory({
    this.referredBy,
    this.generalHistory,
    this.allergies,
    this.currentMedications,
    this.habits = const <String>[],
    this.pastHealthHistory,
  });

  final String? referredBy;
  final String? generalHistory;
  final String? allergies;
  final String? currentMedications;
  final List<String> habits;
  final String? pastHealthHistory;

  MedicalHistory copyWith({
    String? referredBy,
    String? generalHistory,
    String? allergies,
    String? currentMedications,
    List<String>? habits,
    String? pastHealthHistory,
  }) {
    return MedicalHistory(
      referredBy: referredBy ?? this.referredBy,
      generalHistory: generalHistory ?? this.generalHistory,
      allergies: allergies ?? this.allergies,
      currentMedications: currentMedications ?? this.currentMedications,
      habits: habits ?? this.habits,
      pastHealthHistory: pastHealthHistory ?? this.pastHealthHistory,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'referredBy': referredBy,
      'generalHistory': generalHistory,
      'allergies': allergies,
      'currentMedications': currentMedications,
      'habits': habits,
      'pastHealthHistory': pastHealthHistory,
    };

    map.removeWhere((key, value) => value == null);
    return map;
  }

  factory MedicalHistory.fromMap(Map<String, dynamic> data) {
    final habitsData = data['habits'];
    return MedicalHistory(
      referredBy: data['referredBy'] as String?,
      generalHistory: data['generalHistory'] as String?,
      allergies: data['allergies'] as String?,
      currentMedications: data['currentMedications'] as String?,
      habits: habitsData is Iterable ? List<String>.from(habitsData) : const <String>[],
      pastHealthHistory: data['pastHealthHistory'] as String?,
    );
  }
}
