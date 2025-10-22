import 'package:cliniqflow/features/patients/data/patient_repository.dart';
import 'package:cliniqflow/features/patients/models/patient_profile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

PatientProfile buildProfile({
  required String id,
  String? patientUid,
  String fullName = 'Test Patient',
}) {
  final now = DateTime(2025, 1, 1);
  return PatientProfile(
    id: id,
    patientUid: patientUid ?? 'uid-$id',
    fullName: fullName,
    registrationDate: now,
    contactInfo: const ContactInfo(residentialPhone: '111-222'),
    emergencyContact: const EmergencyContact(name: 'Guardian'),
    medicalHistory: const MedicalHistory(habits: <String>['running']),
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('FirestorePatientRepository', () {
    late FakeFirebaseFirestore firestore;
    late FirestorePatientRepository repository;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      repository = FirestorePatientRepository(firestore);
    });

    test('watchAll streams ordered patients', () async {
      final collection = firestore.collection('patients');
      await collection.doc('b').set(buildProfile(id: 'b', fullName: 'Bob').toMap());
      await collection.doc('a').set(buildProfile(id: 'a', fullName: 'Alice').toMap());

      final patients = await repository.watchAll().first;
      expect(patients.map((p) => p.fullName), ['Alice', 'Bob']);
    });

    test('fetchById returns patient or null', () async {
      final collection = firestore.collection('patients');
      await collection.doc('c').set(buildProfile(id: 'c', fullName: 'Cara').toMap());

      final found = await repository.fetchById('c');
      final missing = await repository.fetchById('missing');

      expect(found, isNotNull);
      expect(found!.id, 'c');
      expect(found.fullName, 'Cara');
      expect(missing, isNull);
    });

    test('create generates id, timestamps, and patientUid', () async {
      final profile = buildProfile(id: '', patientUid: '');

      final id = await repository.create(profile);
      final doc = await firestore.collection('patients').doc(id).get();

      expect(doc.exists, isTrue);
      final data = doc.data()!;
      expect(data['patientUid'], id);
      expect(data['createdAt'], isA<Timestamp>());
      expect(data['updatedAt'], isA<Timestamp>());
    });

    test('update persists changes and fills missing patientUid', () async {
      final profile = buildProfile(id: '', patientUid: '');
      final id = await repository.create(profile);
      final existing = (await repository.fetchById(id))!;

      final before = (await firestore.collection('patients').doc(id).get()).data()!['updatedAt'];

      final updatedProfile = existing.copyWith(
        fullName: 'Updated Name',
        patientUid: '',
        contactInfo: existing.contactInfo.copyWith(email: 'updated@example.com'),
      );

      await repository.update(updatedProfile);

      final doc = await firestore.collection('patients').doc(id).get();
      final data = doc.data()!;
      expect(data['fullName'], 'Updated Name');
      expect(data['patientUid'], id);
      expect(data['updatedAt'], isA<Timestamp>());
      expect(data['updatedAt'], isNot(equals(before)));
      expect(data['contactInfo'], containsPair('email', 'updated@example.com'));
    });

    test('update throws when id is empty', () async {
      final emptyProfile = PatientProfile.empty();
      await expectLater(repository.update(emptyProfile), throwsArgumentError);
    });

    test('delete removes document', () async {
      final profile = buildProfile(id: 'delete-me');
      await firestore.collection('patients').doc('delete-me').set(profile.toMap());

      await repository.delete('delete-me');
      final doc = await firestore.collection('patients').doc('delete-me').get();
      expect(doc.exists, isFalse);
    });
  });
}
