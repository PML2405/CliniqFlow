import 'dart:async';

import 'package:cliniqflow/features/patients/data/patient_repository.dart';
import 'package:cliniqflow/features/patients/models/patient_profile.dart';
import 'package:cliniqflow/features/patients/presentation/patient_directory_controller.dart';
import 'package:flutter_test/flutter_test.dart';

class FakePatientRepository implements PatientRepository {
  FakePatientRepository({List<PatientProfile> initialPatients = const []})
      : _initialPatients = initialPatients;

  final List<PatientProfile> _initialPatients;
  final _controller = StreamController<List<PatientProfile>>.broadcast();

  bool fetchCalled = false;
  bool updateCalled = false;
  bool createCalled = false;
  bool deleteCalled = false;

  Object? errorToEmit;

  @override
  Stream<List<PatientProfile>> watchAll() {
    scheduleMicrotask(() {
      if (errorToEmit != null) {
        _controller.addError(errorToEmit!);
      } else {
        _controller.add(_initialPatients);
      }
    });
    return _controller.stream;
  }

  @override
  Future<PatientProfile?> fetchById(String id) async {
    fetchCalled = true;
    return _initialPatients.firstWhere((profile) => profile.id == id);
  }

  @override
  Future<String> create(PatientProfile profile) async {
    createCalled = true;
    return 'created-id';
  }

  @override
  Future<void> update(PatientProfile profile) async {
    updateCalled = true;
  }

  @override
  Future<void> delete(String id) async {
    deleteCalled = true;
  }

  void emit(List<PatientProfile> patients) {
    _controller.add(patients);
  }

  void emitError(Object error) {
    _controller.addError(error);
  }

  void dispose() {
    _controller.close();
  }
}

PatientProfile buildProfile(String id, {String? fullName, String? phone}) {
  final now = DateTime(2025, 1, 1);
  return PatientProfile(
    id: id,
    patientUid: 'uid-$id',
    fullName: fullName ?? 'Patient $id',
    registrationDate: now,
    contactInfo: ContactInfo(residentialPhone: phone),
    emergencyContact: const EmergencyContact(),
    medicalHistory: const MedicalHistory(),
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('PatientDirectoryController', () {
    late FakePatientRepository repository;
    late PatientDirectoryController controller;

    setUp(() {
      repository = FakePatientRepository(
        initialPatients: [
          buildProfile('1', fullName: 'Alice Doe', phone: '111'),
          buildProfile('2', fullName: 'Bob Ray', phone: '222'),
        ],
      );
      controller = PatientDirectoryController(repository);
    });

    tearDown(() {
      repository.dispose();
      controller.dispose();
    });

    Future<void> pumpEventQueue({int times = 1}) async {
      for (var i = 0; i < times; i++) {
        await Future<void>.delayed(Duration.zero);
      }
    }

    test('initialize loads patients and updates loading state', () async {
      controller.initialize();
      expect(controller.isLoading, isTrue);

      await pumpEventQueue(times: 2);

      expect(controller.isLoading, isFalse);
      expect(controller.errorMessage, isNull);
      expect(controller.patients.length, 2);
    });

    test('initialize handles stream errors', () async {
      repository.errorToEmit = StateError('boom');
      controller.initialize();

      await pumpEventQueue(times: 2);

      expect(controller.isLoading, isFalse);
      expect(controller.errorMessage, 'Bad state: boom');
    });

    test('setSearchQuery filters by name, uid, and phone', () async {
      controller.initialize();
      await pumpEventQueue(times: 2);

      controller.setSearchQuery('alice');
      expect(controller.patients.map((p) => p.id), ['1']);

      controller.setSearchQuery('UID-2');
      expect(controller.patients.map((p) => p.id), ['2']);

      controller.setSearchQuery('222');
      expect(controller.patients.map((p) => p.id), ['2']);

      controller.setSearchQuery('');
      expect(controller.patients.length, 2);
    });

    test('refresh restarts subscription', () async {
      controller.initialize();
      await pumpEventQueue(times: 2);
      repository.emit([
        buildProfile('3', fullName: 'Cara'),
      ]);

      await pumpEventQueue(times: 2);
      expect(controller.patients.map((p) => p.id), ['3']);

      await controller.refresh();
      await pumpEventQueue(times: 2);

      expect(controller.isLoading, isFalse);
      expect(controller.errorMessage, isNull);
    });

    test('savePatient delegates to create and update', () async {
      final newProfile = buildProfile('', fullName: 'New');
      final existingProfile = buildProfile('existing');

      final createdId = await controller.savePatient(newProfile);
      expect(createdId, 'created-id');
      expect(repository.createCalled, isTrue);

      await controller.savePatient(existingProfile);
      expect(repository.updateCalled, isTrue);
    });

    test('deletePatient delegates to repository', () async {
      await controller.deletePatient('id-9');
      expect(repository.deleteCalled, isTrue);
    });
  });
}
