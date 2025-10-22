import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../appointments/models/appointment.dart';
import '../../patients/models/patient_profile.dart';
import '../data/case_sheet_repository.dart';
import '../models/case_sheet.dart';

enum CaseSheetViewState {
  idle,
  loading,
  saving,
  error,
}

class CaseSheetController extends ChangeNotifier {
  CaseSheetController(this._repository);

  final CaseSheetRepository _repository;
  StreamSubscription<List<CaseSheet>>? _subscription;

  CaseSheetViewState _state = CaseSheetViewState.idle;
  String? _errorMessage;
  String? _patientId;
  List<CaseSheet> _caseSheets = const [];
  CaseSheet? _selectedSheet;

  CaseSheetViewState get state => _state;
  String? get errorMessage => _errorMessage;
  String? get patientId => _patientId;
  List<CaseSheet> get caseSheets => _caseSheets;
  CaseSheet? get selectedSheet => _selectedSheet;

  void initialize(String patientId) {
    if (_subscription != null && _patientId == patientId) {
      return;
    }

    _subscription?.cancel();
    _patientId = patientId;
    _setState(CaseSheetViewState.loading);

    _subscription = _repository.watchByPatient(patientId).listen(
      (sheets) {
        _caseSheets = sheets;
        if (_selectedSheet != null) {
          _selectedSheet = sheets.firstWhere(
            (sheet) => sheet.id == _selectedSheet!.id,
            orElse: () => _selectedSheet!,
          );
        }
        _errorMessage = null;
        _setState(CaseSheetViewState.idle, notify: true);
      },
      onError: (Object error, StackTrace stackTrace) {
        _caseSheets = const [];
        _errorMessage = error.toString();
        _setState(CaseSheetViewState.error, notify: true);
      },
      onDone: () {
        if (_state == CaseSheetViewState.loading) {
          _setState(CaseSheetViewState.idle, notify: true);
        }
      },
    );
  }

  void selectSheet(CaseSheet? sheet) {
    _selectedSheet = sheet;
    notifyListeners();
  }

  Future<void> recordConsent(CaseSheetConsent consent) async {
    final current = _selectedSheet;
    if (current == null) {
      return;
    }

    _setState(CaseSheetViewState.saving, notify: true);
    try {
      await _repository.recordConsent(sheet: current, consent: consent);
      final updatedSheet = current.copyWith(
        consent: consent,
        updatedAt: DateTime.now(),
      );

      _caseSheets = _caseSheets
          .map((sheet) => sheet.id == updatedSheet.id ? updatedSheet : sheet)
          .toList(growable: false);
      _selectedSheet = updatedSheet;
      _errorMessage = null;
      _setState(CaseSheetViewState.idle, notify: true);
    } catch (error) {
      _errorMessage = error.toString();
      _setState(CaseSheetViewState.error, notify: true);
    }
  }

  Future<void> createCaseSheet({
    required PatientProfile patient,
    required Appointment appointment,
    required DateTime visitDate,
    required String doctorInCharge,
    required String chiefComplaint,
    required String provisionalDiagnosis,
    required String treatmentPlan,
  }) async {
    _setState(CaseSheetViewState.saving, notify: true);

    try {
      final id = await _repository.create(
        patient: patient,
        appointment: appointment,
        visitDate: visitDate,
        doctorInCharge: doctorInCharge,
        chiefComplaint: chiefComplaint,
        provisionalDiagnosis: provisionalDiagnosis,
        treatmentPlan: treatmentPlan,
      );

      final createdSheet = await _repository.fetchById(id);
      if (createdSheet != null) {
        final updatedList = List<CaseSheet>.from(_caseSheets)..add(createdSheet);
        updatedList.sort((a, b) => b.visitDate.compareTo(a.visitDate));
        _caseSheets = updatedList;
        _selectedSheet = createdSheet;
      }

      _errorMessage = null;
      _setState(CaseSheetViewState.idle, notify: true);
    } catch (error) {
      _errorMessage = error.toString();
      _setState(CaseSheetViewState.error, notify: true);
    }
  }

  Future<void> uploadAttachment({
    required String fileName,
    required String contentType,
    required Uint8List bytes,
  }) async {
    final current = _selectedSheet;
    if (current == null || current.id.isEmpty) {
      return;
    }

    _setState(CaseSheetViewState.saving);

    try {
      final attachment = await _repository.uploadAttachment(
        sheet: current,
        fileName: fileName,
        contentType: contentType,
        bytes: bytes,
      );

      final updatedSheet = current.copyWith(
        attachments: List<CaseSheetAttachment>.from(current.attachments)
          ..add(attachment),
        updatedAt: DateTime.now(),
      );

      _caseSheets = _caseSheets
          .map((sheet) => sheet.id == updatedSheet.id ? updatedSheet : sheet)
          .toList(growable: false);
      _selectedSheet = updatedSheet;
      _errorMessage = null;
      _setState(CaseSheetViewState.idle, notify: true);
    } catch (error) {
      _errorMessage = error.toString();
      _setState(CaseSheetViewState.error, notify: true);
    }
  }

  void _setState(CaseSheetViewState value, {bool notify = false}) {
    _state = value;
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
