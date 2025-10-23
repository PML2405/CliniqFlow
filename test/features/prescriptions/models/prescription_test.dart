import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cliniqflow/features/prescriptions/models/prescription.dart';

void main() {
  group('Prescription', () {
    test('creates empty prescription', () {
      final prescription = Prescription.empty();

      expect(prescription.id, isEmpty);
      expect(prescription.patientId, isEmpty);
      expect(prescription.patientUid, isEmpty);
      expect(prescription.patientName, isEmpty);
      expect(prescription.caseSheetId, isNull);
      expect(prescription.doctorName, isEmpty);
      expect(prescription.items, isEmpty);
    });

    test('copyWith creates new instance with updated values', () {
      final original = Prescription.empty();
      final updated = original.copyWith(
        doctorName: 'Dr. Smith',
        items: [
          const PrescriptionItem(
            id: '1',
            drugName: 'Amoxicillin',
            dosage: '500mg',
            frequency: 'Twice daily',
            duration: '7 days',
          ),
        ],
      );

      expect(updated.doctorName, 'Dr. Smith');
      expect(updated.items.length, 1);
      expect(updated.items.first.drugName, 'Amoxicillin');
      expect(original.doctorName, isEmpty);
    });

    test('toMap converts prescription to map', () {
      final now = DateTime.now();
      final prescription = Prescription(
        id: 'rx-1',
        patientId: 'patient-1',
        patientUid: 'UID-123',
        patientName: 'John Doe',
        caseSheetId: 'case-1',
        doctorName: 'Dr. Smith',
        prescriptionDate: now,
        items: [
          const PrescriptionItem(
            id: '1',
            drugName: 'Amoxicillin',
            dosage: '500mg',
            frequency: 'Twice daily',
            duration: '7 days',
          ),
        ],
        createdAt: now,
        updatedAt: now,
      );

      final map = prescription.toMap();

      expect(map['patientId'], 'patient-1');
      expect(map['patientUid'], 'UID-123');
      expect(map['patientName'], 'John Doe');
      expect(map['caseSheetId'], 'case-1');
      expect(map['doctorName'], 'Dr. Smith');
      expect(map['prescriptionDate'], isA<Timestamp>());
      expect(map['items'], isA<List>());
      expect((map['items'] as List).length, 1);
      expect(map['createdAt'], isA<Timestamp>());
      expect(map['updatedAt'], isA<Timestamp>());
    });

    test('fromMap creates prescription from map', () {
      final now = DateTime.now();
      final map = {
        'patientId': 'patient-1',
        'patientUid': 'UID-123',
        'patientName': 'John Doe',
        'caseSheetId': 'case-1',
        'doctorName': 'Dr. Smith',
        'prescriptionDate': Timestamp.fromDate(now),
        'items': [
          {
            'id': '1',
            'drugName': 'Amoxicillin',
            'dosage': '500mg',
            'frequency': 'Twice daily',
            'duration': '7 days',
          },
        ],
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      };

      final prescription = Prescription.fromMap('rx-1', map);

      expect(prescription.id, 'rx-1');
      expect(prescription.patientId, 'patient-1');
      expect(prescription.patientUid, 'UID-123');
      expect(prescription.patientName, 'John Doe');
      expect(prescription.caseSheetId, 'case-1');
      expect(prescription.doctorName, 'Dr. Smith');
      expect(prescription.items.length, 1);
      expect(prescription.items.first.drugName, 'Amoxicillin');
    });

    test('fromMap handles missing optional fields', () {
      final now = DateTime.now();
      final map = {
        'patientId': 'patient-1',
        'patientUid': 'UID-123',
        'patientName': 'John Doe',
        'doctorName': 'Dr. Smith',
        'prescriptionDate': Timestamp.fromDate(now),
        'items': [],
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      };

      final prescription = Prescription.fromMap('rx-1', map);

      expect(prescription.caseSheetId, isNull);
      expect(prescription.items, isEmpty);
    });
  });

  group('PrescriptionItem', () {
    test('creates prescription item', () {
      const item = PrescriptionItem(
        id: '1',
        drugName: 'Amoxicillin',
        dosage: '500mg',
        frequency: 'Twice daily',
        duration: '7 days',
        notes: 'Take with food',
      );

      expect(item.id, '1');
      expect(item.drugName, 'Amoxicillin');
      expect(item.dosage, '500mg');
      expect(item.frequency, 'Twice daily');
      expect(item.duration, '7 days');
      expect(item.notes, 'Take with food');
    });

    test('copyWith creates new instance with updated values', () {
      const original = PrescriptionItem(
        id: '1',
        drugName: 'Amoxicillin',
        dosage: '500mg',
        frequency: 'Twice daily',
        duration: '7 days',
      );

      final updated = original.copyWith(
        dosage: '250mg',
        notes: 'Take with food',
      );

      expect(updated.dosage, '250mg');
      expect(updated.notes, 'Take with food');
      expect(updated.drugName, 'Amoxicillin');
      expect(original.dosage, '500mg');
    });

    test('toMap converts item to map', () {
      const item = PrescriptionItem(
        id: '1',
        drugName: 'Amoxicillin',
        dosage: '500mg',
        frequency: 'Twice daily',
        duration: '7 days',
        notes: 'Take with food',
      );

      final map = item.toMap();

      expect(map['id'], '1');
      expect(map['drugName'], 'Amoxicillin');
      expect(map['dosage'], '500mg');
      expect(map['frequency'], 'Twice daily');
      expect(map['duration'], '7 days');
      expect(map['notes'], 'Take with food');
    });

    test('fromMap creates item from map', () {
      final map = {
        'id': '1',
        'drugName': 'Amoxicillin',
        'dosage': '500mg',
        'frequency': 'Twice daily',
        'duration': '7 days',
        'notes': 'Take with food',
      };

      final item = PrescriptionItem.fromMap(map);

      expect(item.id, '1');
      expect(item.drugName, 'Amoxicillin');
      expect(item.dosage, '500mg');
      expect(item.frequency, 'Twice daily');
      expect(item.duration, '7 days');
      expect(item.notes, 'Take with food');
    });

    test('fromMap handles missing optional fields', () {
      final map = {
        'id': '1',
        'drugName': 'Amoxicillin',
        'dosage': '500mg',
        'frequency': 'Twice daily',
        'duration': '7 days',
      };

      final item = PrescriptionItem.fromMap(map);

      expect(item.notes, isNull);
    });
  });
}
