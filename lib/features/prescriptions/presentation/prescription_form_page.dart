import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../patients/models/patient_profile.dart';
import '../models/prescription.dart';
import 'prescription_controller.dart';

/// Page for creating or editing a prescription
class PrescriptionFormPage extends StatefulWidget {
  const PrescriptionFormPage({
    required this.controller,
    required this.patient,
    this.caseSheetId,
    this.prescription,
    super.key,
  });

  final PrescriptionController controller;
  final PatientProfile patient;
  final String? caseSheetId;
  final Prescription? prescription;

  @override
  State<PrescriptionFormPage> createState() => _PrescriptionFormPageState();
}

class _PrescriptionFormPageState extends State<PrescriptionFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _doctorController = TextEditingController();
  late DateTime _prescriptionDate;
  final List<_DrugFormData> _drugs = [];

  @override
  void initState() {
    super.initState();
    _prescriptionDate = DateTime.now();
    
    if (widget.prescription != null) {
      _doctorController.text = widget.prescription!.doctorName;
      _prescriptionDate = widget.prescription!.prescriptionDate;
      _drugs.addAll(
        widget.prescription!.items.map(
          (item) => _DrugFormData(
            id: item.id,
            drugName: item.drugName,
            dosage: item.dosage,
            frequency: item.frequency,
            duration: item.duration,
            notes: item.notes,
          ),
        ),
      );
    } else {
      _addDrug();
    }
  }

  @override
  void dispose() {
    _doctorController.dispose();
    for (final drug in _drugs) {
      drug.dispose();
    }
    super.dispose();
  }

  void _addDrug() {
    setState(() {
      _drugs.add(_DrugFormData());
    });
  }

  void _removeDrug(int index) {
    setState(() {
      _drugs[index].dispose();
      _drugs.removeAt(index);
    });
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _prescriptionDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _prescriptionDate = picked;
      });
    }
  }

  Future<void> _savePrescription() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_drugs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one medication'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final items = _drugs
        .map(
          (drug) => PrescriptionItem(
            id: drug.id,
            drugName: drug.drugNameController.text.trim(),
            dosage: drug.dosageController.text.trim(),
            frequency: drug.frequencyController.text.trim(),
            duration: drug.durationController.text.trim(),
            notes: drug.notesController.text.trim().isEmpty
                ? null
                : drug.notesController.text.trim(),
          ),
        )
        .toList();

    try {
      if (widget.prescription != null) {
        await widget.controller.updateItems(
          prescription: widget.prescription!,
          items: items,
        );
      } else {
        await widget.controller.createPrescription(
          patient: widget.patient,
          doctorName: _doctorController.text.trim(),
          prescriptionDate: _prescriptionDate,
          items: items,
          caseSheetId: widget.caseSheetId,
        );
      }

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.prescription != null
                  ? 'Prescription updated successfully'
                  : 'Prescription created successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save prescription: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.prescription != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Prescription' : 'New Prescription'),
        actions: [
          ListenableBuilder(
            listenable: widget.controller,
            builder: (context, _) {
              final isSaving =
                  widget.controller.state == PrescriptionViewState.saving;
              return TextButton(
                onPressed: isSaving ? null : _savePrescription,
                child: isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save'),
              );
            },
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Patient Info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Patient Information',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text('Name: ${widget.patient.fullName}'),
                    Text('UID: ${widget.patient.patientUid}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Doctor Name
            TextFormField(
              controller: _doctorController,
              decoration: const InputDecoration(
                labelText: 'Doctor Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter doctor name';
                }
                if (value.trim().length < 3) {
                  return 'Doctor name must be at least 3 characters';
                }
                if (value.trim().length > 100) {
                  return 'Doctor name must be less than 100 characters';
                }
                return null;
              },
              enabled: !isEditing,
            ),
            const SizedBox(height: 16),

            // Prescription Date
            InkWell(
              onTap: isEditing ? null : _selectDate,
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Prescription Date',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.calendar_today),
                  enabled: !isEditing,
                ),
                child: Text(
                  '${_prescriptionDate.day}/${_prescriptionDate.month}/${_prescriptionDate.year}',
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Medications Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Medications',
                  style: theme.textTheme.titleLarge,
                ),
                FilledButton.icon(
                  onPressed: _addDrug,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Drug'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Drug List
            ..._drugs.asMap().entries.map((entry) {
              final index = entry.key;
              final drug = entry.value;
              return _DrugFormCard(
                key: ValueKey(drug.id),
                drug: drug,
                index: index,
                onRemove: _drugs.length > 1 ? () => _removeDrug(index) : null,
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _DrugFormData {
  _DrugFormData({
    String? id,
    String? drugName,
    String? dosage,
    String? frequency,
    String? duration,
    String? notes,
  })  : id = id ?? const Uuid().v4(),
        drugNameController = TextEditingController(text: drugName),
        dosageController = TextEditingController(text: dosage),
        frequencyController = TextEditingController(text: frequency),
        durationController = TextEditingController(text: duration),
        notesController = TextEditingController(text: notes);

  final String id;
  final TextEditingController drugNameController;
  final TextEditingController dosageController;
  final TextEditingController frequencyController;
  final TextEditingController durationController;
  final TextEditingController notesController;

  void dispose() {
    drugNameController.dispose();
    dosageController.dispose();
    frequencyController.dispose();
    durationController.dispose();
    notesController.dispose();
  }
}

class _DrugFormCard extends StatelessWidget {
  const _DrugFormCard({
    required this.drug,
    required this.index,
    this.onRemove,
    super.key,
  });

  final _DrugFormData drug;
  final int index;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Drug ${index + 1}',
                  style: theme.textTheme.titleMedium,
                ),
                if (onRemove != null)
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: onRemove,
                    tooltip: 'Remove drug',
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: drug.drugNameController,
              decoration: const InputDecoration(
                labelText: 'Drug Name',
                border: OutlineInputBorder(),
                hintText: 'e.g., Amoxicillin',
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter drug name';
                }
                if (value.trim().length < 2) {
                  return 'Drug name must be at least 2 characters';
                }
                if (value.trim().length > 200) {
                  return 'Drug name must be less than 200 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: drug.dosageController,
              decoration: const InputDecoration(
                labelText: 'Dosage',
                border: OutlineInputBorder(),
                hintText: 'e.g., 500mg',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter dosage';
                }
                if (value.trim().length > 50) {
                  return 'Dosage must be less than 50 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: drug.frequencyController,
              decoration: const InputDecoration(
                labelText: 'Frequency',
                border: OutlineInputBorder(),
                hintText: 'e.g., Twice daily',
              ),
              textCapitalization: TextCapitalization.sentences,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter frequency';
                }
                if (value.trim().length > 100) {
                  return 'Frequency must be less than 100 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: drug.durationController,
              decoration: const InputDecoration(
                labelText: 'Duration',
                border: OutlineInputBorder(),
                hintText: 'e.g., 7 days',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter duration';
                }
                if (value.trim().length > 50) {
                  return 'Duration must be less than 50 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: drug.notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (Optional)',
                border: OutlineInputBorder(),
                hintText: 'e.g., Take with food',
              ),
              textCapitalization: TextCapitalization.sentences,
              maxLines: 3,
              maxLength: 500,
              validator: (value) {
                if (value != null && value.trim().length > 500) {
                  return 'Notes must be less than 500 characters';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }
}
