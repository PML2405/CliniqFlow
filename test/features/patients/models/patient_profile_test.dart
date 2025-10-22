import 'package:cliniqflow/features/patients/models/patient_profile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PatientProfile', () {
    test('primaryPhone prefers contact info over emergency contact', () {
      final now = DateTime(2025, 1, 1);
      final profile = PatientProfile(
        id: 'id-1',
        patientUid: 'uid-1',
        fullName: 'Alice Doe',
        registrationDate: now,
        contactInfo: const ContactInfo(residentialPhone: '111', officePhone: '222'),
        emergencyContact: const EmergencyContact(mobilePhone: '999'),
        medicalHistory: const MedicalHistory(),
        createdAt: now,
        updatedAt: now,
      );

      expect(profile.primaryPhone, '111');

      final fallbackProfile = profile.copyWith(
        contactInfo: const ContactInfo(),
        emergencyContact: const EmergencyContact(mobilePhone: '888'),
      );
      expect(fallbackProfile.primaryPhone, '888');
    });

    test('toMap removes null values and serializes nested types', () {
      final now = DateTime(2025, 1, 2, 10);
      final profile = PatientProfile(
        id: 'id-2',
        patientUid: 'uid-2',
        fullName: 'Bob Smith',
        registrationDate: now,
        age: 42,
        contactInfo: const ContactInfo(email: 'bob@example.com'),
        emergencyContact: const EmergencyContact(name: 'Eve', mobilePhone: '555'),
        medicalHistory: const MedicalHistory(habits: <String>['running']),
        createdAt: now,
        updatedAt: now,
      );

      final map = profile.toMap();

      expect(map.containsKey('dateOfBirth'), isFalse);
      expect(map.containsKey('sex'), isFalse);
      expect(map['patientUid'], 'uid-2');
      expect(map['contactInfo'], {'email': 'bob@example.com'});
      expect(map['emergencyContact'], {'name': 'Eve', 'mobilePhone': '555'});
      expect(map['medicalHistory'], {
        'habits': <String>['running'],
      });
      expect(map['registrationDate'], isA<Timestamp>());
      expect(map['createdAt'], isA<Timestamp>());
      expect(map['updatedAt'], isA<Timestamp>());
    });

    test('fromMap reconstructs profile with defaults', () {
      final registrationDate = DateTime(2024, 3, 10);
      final createdAt = DateTime(2024, 3, 11);
      final updatedAt = DateTime(2024, 3, 12);
      final map = {
        'patientUid': 'uid-3',
        'fullName': 'Charlie Day',
        'registrationDate': Timestamp.fromDate(registrationDate),
        'contactInfo': {
          'residentialPhone': '123',
        },
        'emergencyContact': {
          'mobilePhone': '456',
        },
        'medicalHistory': {
          'habits': ['cycling'],
          'generalHistory': 'Fit',
        },
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

      final profile = PatientProfile.fromMap('doc-3', map);

      expect(profile.id, 'doc-3');
      expect(profile.patientUid, 'uid-3');
      expect(profile.fullName, 'Charlie Day');
      expect(profile.registrationDate, registrationDate);
      expect(profile.contactInfo.residentialPhone, '123');
      expect(profile.emergencyContact.mobilePhone, '456');
      expect(profile.medicalHistory.habits, ['cycling']);
      expect(profile.medicalHistory.generalHistory, 'Fit');
      expect(profile.createdAt, createdAt);
      expect(profile.updatedAt, updatedAt);
    });

    test('copyWith overrides selected fields', () {
      final now = DateTime(2024, 5, 1);
      final profile = PatientProfile(
        id: 'id-4',
        patientUid: 'uid-4',
        fullName: 'Dana Ray',
        registrationDate: now,
        contactInfo: const ContactInfo(email: 'dana@clinic.test'),
        emergencyContact: const EmergencyContact(name: 'Sam'),
        medicalHistory: const MedicalHistory(referredBy: 'Dr. Who'),
        createdAt: now,
        updatedAt: now,
      );

      final updated = profile.copyWith(
        fullName: 'Dana Ray Jr.',
        contactInfo: profile.contactInfo.copyWith(email: 'new@clinic.test'),
        medicalHistory: profile.medicalHistory.copyWith(habits: <String>['swimming']),
        updatedAt: now.add(const Duration(days: 1)),
      );

      expect(updated.id, 'id-4');
      expect(updated.fullName, 'Dana Ray Jr.');
      expect(updated.contactInfo.email, 'new@clinic.test');
      expect(updated.medicalHistory.habits, ['swimming']);
      expect(updated.updatedAt, now.add(const Duration(days: 1)));
      expect(updated.createdAt, profile.createdAt);
    });

    test('fromDocument uses snapshot data', () async {
      final firestore = FakeFirebaseFirestore();
      final patients = firestore.collection('patients');
      await patients.doc('doc-5').set({
        'patientUid': 'uid-5',
        'fullName': 'Evan Lee',
        'registrationDate': Timestamp.fromDate(DateTime(2024, 6, 1)),
        'contactInfo': {
          'officePhone': '333',
        },
        'emergencyContact': {
          'officePhone': '777',
        },
        'medicalHistory': {
          'habits': ['yoga'],
        },
        'createdAt': Timestamp.fromDate(DateTime(2024, 6, 1)),
        'updatedAt': Timestamp.fromDate(DateTime(2024, 6, 2)),
      });

      final snapshot = await patients.doc('doc-5').get();
      final profile = PatientProfile.fromDocument(snapshot);

      expect(profile.id, 'doc-5');
      expect(profile.patientUid, 'uid-5');
      expect(profile.contactInfo.officePhone, '333');
      expect(profile.emergencyContact.officePhone, '777');
      expect(profile.medicalHistory.habits, ['yoga']);
    });
  });
}
