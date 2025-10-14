import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/patient_repository.dart';
import '../models/patient_profile.dart';

class PatientDirectoryController extends ChangeNotifier {
  PatientDirectoryController(this._repository);

  final PatientRepository _repository;
  StreamSubscription<List<PatientProfile>>? _subscription;
  List<PatientProfile> _patients = const [];
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;

  List<PatientProfile> get patients {
    if (_searchQuery.trim().isEmpty) {
      return _patients;
    }

    final query = _searchQuery.trim().toLowerCase();
    return _patients
        .where((patient) {
          final name = patient.fullName.toLowerCase();
          final uid = patient.patientUid.toLowerCase();
          final phone = patient.primaryPhone.toLowerCase();
          return name.contains(query) ||
              uid.contains(query) ||
              phone.contains(query);
        })
        .toList(growable: false);
  }

  void initialize() {
    if (_subscription != null) {
      return;
    }

    _isLoading = true;
    notifyListeners();

    _subscription = _repository.watchAll().listen(
      (event) {
        _patients = event;
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (Object error, StackTrace stackTrace) {
        _errorMessage = error.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<void> refresh() async {
    await _subscription?.cancel();
    _subscription = null;
    initialize();
  }

  void setSearchQuery(String value) {
    _searchQuery = value;
    notifyListeners();
  }

  Future<String> savePatient(PatientProfile profile) async {
    if (profile.id.isEmpty) {
      return _repository.create(profile);
    } else {
      await _repository.update(profile);
      return profile.id;
    }
  }

  Future<void> deletePatient(String id) {
    return _repository.delete(id);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
