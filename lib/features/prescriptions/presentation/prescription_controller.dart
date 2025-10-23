import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../patients/models/patient_profile.dart';
import '../data/prescription_repository.dart';
import '../models/prescription.dart';

enum PrescriptionViewState {
  idle,
  loading,
  saving,
  error,
}

/// Controller for managing prescription state and operations
class PrescriptionController extends ChangeNotifier {
  PrescriptionController(this._repository);

  final PrescriptionRepository _repository;
  StreamSubscription<List<Prescription>>? _subscription;

  PrescriptionViewState _state = PrescriptionViewState.idle;
  String? _errorMessage;
  String? _patientId;
  List<Prescription> _prescriptions = const [];
  Prescription? _selectedPrescription;

  PrescriptionViewState get state => _state;
  String? get errorMessage => _errorMessage;
  String? get patientId => _patientId;
  List<Prescription> get prescriptions => _prescriptions;
  Prescription? get selectedPrescription => _selectedPrescription;

  /// Initialize controller to watch prescriptions for a patient
  void initialize(String patientId) {
    if (_subscription != null && _patientId == patientId) {
      return;
    }

    _subscription?.cancel();
    _patientId = patientId;
    _setState(PrescriptionViewState.loading);

    _subscription = _repository.watchByPatient(patientId).listen(
      (prescriptions) {
        _prescriptions = prescriptions;
        if (_selectedPrescription != null) {
          _selectedPrescription = prescriptions.firstWhere(
            (rx) => rx.id == _selectedPrescription!.id,
            orElse: () => _selectedPrescription!,
          );
        }
        _errorMessage = null;
        _setState(PrescriptionViewState.idle, notify: true);
      },
      onError: (Object error, StackTrace stackTrace) {
        _prescriptions = const [];
        _errorMessage = error.toString();
        _setState(PrescriptionViewState.error, notify: true);
      },
      onDone: () {
        if (_state == PrescriptionViewState.loading) {
          _setState(PrescriptionViewState.idle, notify: true);
        }
      },
    );
  }

  /// Select a prescription to view/edit
  void selectPrescription(Prescription? prescription) {
    _selectedPrescription = prescription;
    notifyListeners();
  }

  /// Create a new prescription
  Future<String> createPrescription({
    required PatientProfile patient,
    required String doctorName,
    required DateTime prescriptionDate,
    required List<PrescriptionItem> items,
    String? caseSheetId,
  }) async {
    _setState(PrescriptionViewState.saving, notify: true);
    try {
      final id = await _repository.create(
        patient: patient,
        doctorName: doctorName,
        prescriptionDate: prescriptionDate,
        items: items,
        caseSheetId: caseSheetId,
      );
      _errorMessage = null;
      _setState(PrescriptionViewState.idle, notify: true);
      return id;
    } catch (error) {
      _errorMessage = error.toString();
      _setState(PrescriptionViewState.error, notify: true);
      rethrow;
    }
  }

  /// Update prescription items
  Future<void> updateItems({
    required Prescription prescription,
    required List<PrescriptionItem> items,
  }) async {
    _setState(PrescriptionViewState.saving, notify: true);
    try {
      await _repository.updateItems(
        prescription: prescription,
        items: items,
      );
      final updatedPrescription = prescription.copyWith(
        items: items,
        updatedAt: DateTime.now(),
      );

      _prescriptions = _prescriptions
          .map((rx) => rx.id == updatedPrescription.id ? updatedPrescription : rx)
          .toList(growable: false);
      _selectedPrescription = updatedPrescription;
      _errorMessage = null;
      _setState(PrescriptionViewState.idle, notify: true);
    } catch (error) {
      _errorMessage = error.toString();
      _setState(PrescriptionViewState.error, notify: true);
      rethrow;
    }
  }

  /// Delete a prescription
  Future<void> deletePrescription(String id) async {
    _setState(PrescriptionViewState.saving, notify: true);
    try {
      await _repository.delete(id);
      _prescriptions = _prescriptions
          .where((rx) => rx.id != id)
          .toList(growable: false);
      if (_selectedPrescription?.id == id) {
        _selectedPrescription = null;
      }
      _errorMessage = null;
      _setState(PrescriptionViewState.idle, notify: true);
    } catch (error) {
      _errorMessage = error.toString();
      _setState(PrescriptionViewState.error, notify: true);
      rethrow;
    }
  }

  void _setState(PrescriptionViewState newState, {bool notify = false}) {
    _state = newState;
    if (notify) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
