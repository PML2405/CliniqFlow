import 'package:flutter/material.dart';

import '../../patients/models/patient_profile.dart';
import '../../patients/presentation/patient_directory_controller.dart';
import '../models/appointment.dart';

class AppointmentEditorResult {
  const AppointmentEditorResult({
    required this.patient,
    required this.date,
    required this.time,
    required this.durationMinutes,
    required this.purpose,
    this.action,
  });

  final PatientProfile patient;
  final DateTime date;
  final TimeOfDay time;
  final int durationMinutes;
  final String purpose;
  final AppointmentEditorAction? action;
}

enum AppointmentEditorAction { cancel, complete }

class AppointmentEditorDelegate {
  const AppointmentEditorDelegate({this.existingAppointment});

  final Appointment? existingAppointment;

  bool get isEditing => existingAppointment != null;
}

class AppointmentEditorDialog extends StatefulWidget {
  const AppointmentEditorDialog._({
    required this.delegate,
    required this.patientController,
  });

  final AppointmentEditorDelegate delegate;
  final PatientDirectoryController patientController;

  static Future<AppointmentEditorResult?> show(
    BuildContext context, {
    required AppointmentEditorDelegate delegate,
    required PatientDirectoryController patientController,
  }) {
    return Navigator.of(context).push<AppointmentEditorResult>(
      MaterialPageRoute<AppointmentEditorResult>(
        fullscreenDialog: true,
        builder: (routeContext) => AppointmentEditorPage(
          delegate: delegate,
          patientController: patientController,
        ),
      ),
    );
  }

  @override
  State<AppointmentEditorDialog> createState() =>
      _AppointmentEditorDialogState();
}

class AppointmentEditorPage extends StatelessWidget {
  const AppointmentEditorPage({
    super.key,
    required this.delegate,
    required this.patientController,
  });

  final AppointmentEditorDelegate delegate;
  final PatientDirectoryController patientController;

  @override
  Widget build(BuildContext context) {
    final title = delegate.isEditing ? 'Edit appointment' : 'Add appointment';
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: AppointmentEditorDialog._(
          delegate: delegate,
          patientController: patientController,
        ),
      ),
    );
  }
}

class _AppointmentEditorDialogState extends State<AppointmentEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _purposeController;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  late int _durationMinutes;
  PatientProfile? _selectedPatient;
  bool _isSubmitting = false;
  AppointmentEditorAction? _pendingAction;

  PatientDirectoryController get patientController => widget.patientController;

  @override
  void initState() {
    super.initState();
    final appointment = widget.delegate.existingAppointment;
    _purposeController = TextEditingController(
      text: appointment?.purpose ?? '',
    );
    _selectedDate = appointment?.start ?? DateTime.now();
    _selectedTime = TimeOfDay.fromDateTime(
      appointment?.start ?? DateTime.now(),
    );
    _durationMinutes = appointment?.durationMinutes ?? 30;
    if (appointment == null) {
      _selectedPatient = patientController.patients.isNotEmpty
          ? patientController.patients.first
          : null;
    } else {
      try {
        _selectedPatient = patientController.patients.firstWhere(
          (patient) => patient.id == appointment.patientId,
        );
      } catch (_) {
        _selectedPatient = patientController.patients.isNotEmpty
            ? patientController.patients.first
            : null;
      }
    }
  }

  @override
  void dispose() {
    _purposeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          24 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPatientSelector(context),
                  const SizedBox(height: 16),
                  _buildDatePicker(context),
                  const SizedBox(height: 16),
                  _buildTimePicker(context),
                  const SizedBox(height: 16),
                  _buildDurationField(),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _purposeController,
                    decoration: const InputDecoration(
                      labelText: 'Purpose',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a purpose';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  OverflowBar(
                    alignment: MainAxisAlignment.end,
                    spacing: 12,
                    overflowSpacing: 12,
                    children: _buildActions(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientSelector(BuildContext context) {
    final patients = patientController.patients;
    return DropdownButtonFormField<PatientProfile>(
      initialValue: _selectedPatient,
      decoration: const InputDecoration(
        labelText: 'Patient',
        border: OutlineInputBorder(),
      ),
      items: patients
          .map(
            (patient) =>
                DropdownMenuItem(value: patient, child: Text(patient.fullName)),
          )
          .toList(growable: false),
      validator: (value) {
        if (value == null) {
          return 'Select a patient';
        }
        return null;
      },
      onChanged: (value) => setState(() => _selectedPatient = value),
    );
  }

  Widget _buildDatePicker(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: const Text('Date'),
      subtitle: Text(_formatDate(_selectedDate)),
      trailing: IconButton(
        icon: const Icon(Icons.calendar_today),
        onPressed: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: _selectedDate,
            firstDate: DateTime.now().subtract(const Duration(days: 365)),
            lastDate: DateTime.now().add(const Duration(days: 365)),
          );
          if (picked != null) {
            setState(() => _selectedDate = picked);
          }
        },
      ),
    );
  }

  Widget _buildTimePicker(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: const Text('Time'),
      subtitle: Text(_selectedTime.format(context)),
      trailing: IconButton(
        icon: const Icon(Icons.access_time),
        onPressed: () async {
          final picked = await showTimePicker(
            context: context,
            initialTime: _selectedTime,
          );
          if (picked != null) {
            setState(() => _selectedTime = picked);
          }
        },
      ),
    );
  }

  Widget _buildDurationField() {
    return TextFormField(
      initialValue: _durationMinutes.toString(),
      decoration: const InputDecoration(
        labelText: 'Duration (minutes)',
        border: OutlineInputBorder(),
      ),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Enter duration';
        }
        final parsed = int.tryParse(value);
        if (parsed == null || parsed <= 0) {
          return 'Enter a valid number';
        }
        return null;
      },
      onChanged: (value) => _durationMinutes = int.tryParse(value) ?? 30,
    );
  }

  List<Widget> _buildActions(BuildContext context) {
    final isEditing = widget.delegate.isEditing;
    final actions = <Widget>[
      TextButton(
        onPressed: _isSubmitting
            ? null
            : () => Navigator.of(context).maybePop(),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: _isSubmitting ? null : () => _submit(context),
        child: Text(
          _isSubmitting
              ? 'Saving…'
              : (isEditing ? 'Save changes' : 'Book appointment'),
        ),
      ),
    ];

    if (isEditing) {
      actions.insert(
        1,
        TextButton(
          onPressed: _isSubmitting
              ? null
              : () => _performAction(context, AppointmentEditorAction.cancel),
          child: const Text('Cancel appointment'),
        ),
      );
      actions.insert(
        2,
        TextButton(
          onPressed: _isSubmitting
              ? null
              : () => _performAction(context, AppointmentEditorAction.complete),
          child: const Text('Mark completed'),
        ),
      );
    }

    return actions;
  }

  Future<void> _submit(BuildContext context) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_selectedPatient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a patient before saving')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      Navigator.of(context).pop(
        AppointmentEditorResult(
          patient: _selectedPatient!,
          date: _selectedDate,
          time: _selectedTime,
          durationMinutes: _durationMinutes,
          purpose: _purposeController.text.trim(),
          action: _pendingAction,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _performAction(
    BuildContext context,
    AppointmentEditorAction action,
  ) async {
    _pendingAction = action;
    await _submit(context);
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}
