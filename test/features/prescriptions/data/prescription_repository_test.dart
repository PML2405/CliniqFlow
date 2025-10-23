import 'package:cliniqflow/features/patients/models/patient_profile.dart';
import 'package:cliniqflow/features/prescriptions/data/prescription_repository.dart';
import 'package:cliniqflow/features/prescriptions/models/prescription.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

PatientProfile buildPatient(String id, {String? name}) {
  final now = DateTime(2025, 1, 1);
  return PatientProfile(
    id: id,
    patientUid: 'uid-$id',
    fullName: name ?? 'Patient $id',
    registrationDate: now,
    contactInfo: const ContactInfo(residentialPhone: '123-456'),
    emergencyContact: const EmergencyContact(name: 'Guardian'),
    medicalHistory: const MedicalHistory(),
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('FirestorePrescriptionRepository', () {
    late FakeFirebaseFirestore firestore;
    late FirestorePrescriptionRepository repository;
    late PatientProfile patient;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      repository = FirestorePrescriptionRepository(firestore);
      patient = buildPatient('patient-1', name: 'John Doe');
    });

    test('create stores prescription and returns id', () async {
      final prescriptionDate = DateTime(2025, 5, 1);
      final items = [
        const PrescriptionItem(
          id: '1',
          drugName: 'Amoxicillin',
          dosage: '500mg',
          frequency: 'Twice daily',
          duration: '7 days',
        ),
        const PrescriptionItem(
          id: '2',
          drugName: 'Ibuprofen',
          dosage: '400mg',
          frequency: 'As needed',
          duration: '5 days',
        ),
      ];

      final id = await repository.create(
        patient: patient,
        doctorName: 'Dr. Smith',
        prescriptionDate: prescriptionDate,
        items: items,
        caseSheetId: 'case-1',
      );

      final doc = await firestore.collection('prescriptions').doc(id).get();
      expect(doc.exists, isTrue);
      final data = doc.data()!;
      expect(data['patientId'], patient.id);
      expect(data['patientUid'], patient.patientUid);
      expect(data['patientName'], patient.fullName);
      expect(data['caseSheetId'], 'case-1');
      expect(data['doctorName'], 'Dr. Smith');
      expect(data['prescriptionDate'], isA<Timestamp>());
      expect(data['items'], isA<List>());
      expect((data['items'] as List).length, 2);
      expect(data['createdAt'], isA<Timestamp>());
      expect(data['updatedAt'], isA<Timestamp>());
    });

    test('create without caseSheetId stores prescription', () async {
      final prescriptionDate = DateTime(2025, 5, 1);
      final items = [
        const PrescriptionItem(
          id: '1',
          drugName: 'Amoxicillin',
          dosage: '500mg',
          frequency: 'Twice daily',
          duration: '7 days',
        ),
      ];

      final id = await repository.create(
        patient: patient,
        doctorName: 'Dr. Smith',
        prescriptionDate: prescriptionDate,
        items: items,
      );

      final doc = await firestore.collection('prescriptions').doc(id).get();
      expect(doc.exists, isTrue);
      final data = doc.data()!;
      expect(data['caseSheetId'], isNull);
    });

    test('fetchById returns prescription when it exists', () async {
      final collection = firestore.collection('prescriptions');
      await collection.doc('rx-1').set({
        'patientId': 'patient-1',
        'patientUid': 'uid-1',
        'patientName': 'John Doe',
        'caseSheetId': 'case-1',
        'doctorName': 'Dr. Smith',
        'prescriptionDate': Timestamp.fromDate(DateTime(2025, 5, 1)),
        'items': [
          {
            'id': '1',
            'drugName': 'Amoxicillin',
            'dosage': '500mg',
            'frequency': 'Twice daily',
            'duration': '7 days',
          },
        ],
        'createdAt': Timestamp.fromDate(DateTime(2025, 5, 1)),
        'updatedAt': Timestamp.fromDate(DateTime(2025, 5, 1)),
      });

      final prescription = await repository.fetchById('rx-1');

      expect(prescription, isNotNull);
      expect(prescription!.id, 'rx-1');
      expect(prescription.patientId, 'patient-1');
      expect(prescription.doctorName, 'Dr. Smith');
      expect(prescription.items.length, 1);
      expect(prescription.items.first.drugName, 'Amoxicillin');
    });

    test('fetchById returns null when prescription does not exist', () async {
      final prescription = await repository.fetchById('nonexistent');
      expect(prescription, isNull);
    });

    test('watchByPatient returns prescriptions ordered by date descending', () async {
      final collection = firestore.collection('prescriptions');
      await collection.doc('rx-1').set({
        'patientId': 'patient-1',
        'patientUid': 'uid-1',
        'patientName': 'John Doe',
        'doctorName': 'Dr. Smith',
        'prescriptionDate': Timestamp.fromDate(DateTime(2025, 5, 1)),
        'items': [],
        'createdAt': Timestamp.fromDate(DateTime(2025, 5, 1)),
        'updatedAt': Timestamp.fromDate(DateTime(2025, 5, 1)),
      });
      await collection.doc('rx-2').set({
        'patientId': 'patient-1',
        'patientUid': 'uid-1',
        'patientName': 'John Doe',
        'doctorName': 'Dr. Jones',
        'prescriptionDate': Timestamp.fromDate(DateTime(2025, 5, 5)),
        'items': [],
        'createdAt': Timestamp.fromDate(DateTime(2025, 5, 5)),
        'updatedAt': Timestamp.fromDate(DateTime(2025, 5, 5)),
      });
      await collection.doc('rx-3').set({
        'patientId': 'patient-2',
        'patientUid': 'uid-2',
        'patientName': 'Jane Smith',
        'doctorName': 'Dr. Brown',
        'prescriptionDate': Timestamp.fromDate(DateTime(2025, 5, 3)),
        'items': [],
        'createdAt': Timestamp.fromDate(DateTime(2025, 5, 3)),
        'updatedAt': Timestamp.fromDate(DateTime(2025, 5, 3)),
      });

      final stream = repository.watchByPatient('patient-1');
      final prescriptions = await stream.first;

      expect(prescriptions.length, 2);
      expect(prescriptions[0].id, 'rx-2'); // Most recent first
      expect(prescriptions[1].id, 'rx-1');
    });

    test('updateItems updates prescription items', () async {
      final collection = firestore.collection('prescriptions');
      await collection.doc('rx-1').set({
        'patientId': 'patient-1',
        'patientUid': 'uid-1',
        'patientName': 'John Doe',
        'doctorName': 'Dr. Smith',
        'prescriptionDate': Timestamp.fromDate(DateTime(2025, 5, 1)),
        'items': [
          {
            'id': '1',
            'drugName': 'Amoxicillin',
            'dosage': '500mg',
            'frequency': 'Twice daily',
            'duration': '7 days',
          },
        ],
        'createdAt': Timestamp.fromDate(DateTime(2025, 5, 1)),
        'updatedAt': Timestamp.fromDate(DateTime(2025, 5, 1)),
      });

      final prescription = await repository.fetchById('rx-1');
      final newItems = [
        const PrescriptionItem(
          id: '1',
          drugName: 'Amoxicillin',
          dosage: '250mg',
          frequency: 'Three times daily',
          duration: '10 days',
        ),
        const PrescriptionItem(
          id: '2',
          drugName: 'Ibuprofen',
          dosage: '400mg',
          frequency: 'As needed',
          duration: '5 days',
        ),
      ];

      await repository.updateItems(
        prescription: prescription!,
        items: newItems,
      );

      final doc = await collection.doc('rx-1').get();
      final data = doc.data()!;
      final items = data['items'] as List;
      expect(items.length, 2);
      expect(items[0]['dosage'], '250mg');
      expect(items[1]['drugName'], 'Ibuprofen');
    });

    test('delete removes prescription', () async {
      final collection = firestore.collection('prescriptions');
      await collection.doc('rx-1').set({
        'patientId': 'patient-1',
        'patientUid': 'uid-1',
        'patientName': 'John Doe',
        'doctorName': 'Dr. Smith',
        'prescriptionDate': Timestamp.fromDate(DateTime(2025, 5, 1)),
        'items': [],
        'createdAt': Timestamp.fromDate(DateTime(2025, 5, 1)),
        'updatedAt': Timestamp.fromDate(DateTime(2025, 5, 1)),
      });

      await repository.delete('rx-1');

      final doc = await collection.doc('rx-1').get();
      expect(doc.exists, isFalse);
    });
  });
}
