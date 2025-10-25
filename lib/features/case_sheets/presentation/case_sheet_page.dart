import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../appointments/models/appointment.dart';
import '../../patients/models/patient_profile.dart';
import '../../prescriptions/data/prescription_repository.dart';
import '../../prescriptions/presentation/prescription_controller.dart';
import '../../prescriptions/presentation/prescription_form_page.dart';
import '../models/case_sheet.dart';
import 'case_sheet_controller.dart';

class CaseSheetPage extends StatefulWidget {
  const CaseSheetPage({
    super.key,
    required this.controller,
    required this.patientId,
    required this.patient,
    this.availableAppointments = const <Appointment>[],
  });

  final CaseSheetController controller;
  final String patientId;
  final PatientProfile patient;
  final List<Appointment> availableAppointments;

  @override
  State<CaseSheetPage> createState() => _CaseSheetPageState();
}

class _CaseSheetPageState extends State<CaseSheetPage> {
  @override
  void initState() {
    super.initState();
    widget.controller.initialize(widget.patientId);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Case Sheets'),
          ),
          floatingActionButton: FloatingActionButton.extended(
            key: const Key('createCaseSheetButton'),
            icon: const Icon(Icons.note_add),
            label: const Text('New case sheet'),
            onPressed: () => _showCreateDialog(context),
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _buildContent(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent() {
    final state = widget.controller.state;
    final error = widget.controller.errorMessage;

    if (state == CaseSheetViewState.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state == CaseSheetViewState.error && error != null) {
      return _ErrorView(
        message: error,
        onRetry: () => widget.controller.initialize(widget.patientId),
      );
    }

    final sheets = widget.controller.caseSheets;
    if (sheets.isEmpty) {
      return const _EmptyView();
    }

    final selected = widget.controller.selectedSheet ?? sheets.first;
    final linkedAppointment = _findAppointment(selected.appointmentId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CaseSheetHeader(
          state: state,
          onCreate: () => _showCreateDialog(context),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: _CaseSheetList(
                  sheets: sheets,
                  selected: selected,
                  onSelect: widget.controller.selectSheet,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 3,
                child: _CaseSheetDetails(
                  sheet: selected,
                  isSaving: state == CaseSheetViewState.saving,
                  appointment: linkedAppointment,
                  onRecordConsent: () => _showConsentDialog(context),
                  onAddAttachment: () => _showAttachmentDialog(context),
                  onDeleteAttachment: (attachment) =>
                      _showDeleteAttachmentDialog(context, attachment),
                  onCreatePrescription: () => _navigateToPrescriptionForm(context, selected),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showCreateDialog(BuildContext context) async {
    final controller = widget.controller;
    final appointments = widget.availableAppointments;

    DateTime? visitDate = appointments.isNotEmpty ? appointments.first.start : DateTime.now();
    Appointment? appointment = appointments.isNotEmpty ? appointments.first : null;
    final doctorController = TextEditingController();
    final complaintController = TextEditingController();
    final diagnosisController = TextEditingController();
    final treatmentController = TextEditingController();
    final dateController = TextEditingController(text: visitDate.toIso8601String());

    final pageContext = context;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('New case sheet'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  key: const Key('caseSheetDoctorField'),
                  controller: doctorController,
                  decoration: const InputDecoration(labelText: 'Doctor in charge'),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('caseSheetComplaintField'),
                  controller: complaintController,
                  decoration: const InputDecoration(labelText: 'Chief complaint'),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('caseSheetDiagnosisField'),
                  controller: diagnosisController,
                  decoration: const InputDecoration(labelText: 'Provisional diagnosis'),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('caseSheetTreatmentField'),
                  controller: treatmentController,
                  decoration: const InputDecoration(labelText: 'Treatment plan'),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('caseSheetDateField'),
                  controller: dateController,
                  decoration: const InputDecoration(labelText: 'Visit date (ISO-8601)'),
                ),
                if (appointments.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<Appointment>(
                    key: const Key('caseSheetAppointmentField'),
                    decoration: const InputDecoration(labelText: 'Link appointment'),
                    initialValue: appointment,
                    items: appointments
                        .map(
                          (appt) => DropdownMenuItem(
                            value: appt,
                            child: Text('${appt.purpose} • ${appt.start}'),
                          ),
                        )
                        .toList(),
                    onChanged: (selected) {
                      appointment = selected;
                      if (selected != null) {
                        visitDate = selected.start;
                        dateController.text = visitDate!.toIso8601String();
                      }
                    },
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              key: const Key('caseSheetSubmitButton'),
              onPressed: () {
                final parsedDate = DateTime.tryParse(dateController.text.trim());
                if (parsedDate == null) {
                  final messenger = ScaffoldMessenger.maybeOf(pageContext);
                  messenger?.showSnackBar(
                    const SnackBar(content: Text('Invalid visit date format.')),
                  );
                  return;
                }

                visitDate = parsedDate;
                Navigator.of(context).pop(true);
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );

    if (result == true && visitDate != null) {
      await controller.createCaseSheet(
        patient: widget.patient,
        appointment: appointment ?? Appointment.empty().copyWith(
          id: 'ad-hoc-${DateTime.now().millisecondsSinceEpoch}',
          patientId: widget.patient.id,
          patientUid: widget.patient.patientUid,
          patientName: widget.patient.fullName,
          start: visitDate!,
          durationMinutes: 30,
          status: AppointmentStatus.completed,
          createdAt: visitDate!,
          updatedAt: visitDate!,
        ),
        visitDate: visitDate!,
        doctorInCharge: doctorController.text.trim(),
        chiefComplaint: complaintController.text.trim(),
        provisionalDiagnosis: diagnosisController.text.trim(),
        treatmentPlan: treatmentController.text.trim(),
      );
    }

    doctorController.dispose();
    complaintController.dispose();
    diagnosisController.dispose();
    treatmentController.dispose();
    dateController.dispose();
  }

  Future<void> _showConsentDialog(BuildContext context) async {
    final controller = widget.controller;
    final capturedByController = TextEditingController();
    bool granted = true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Record consent'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SwitchListTile(
                    title: const Text('Consent granted'),
                    value: granted,
                    onChanged: (value) => setState(() => granted = value),
                  ),
                  TextField(
                    key: const Key('consentCapturedByField'),
                    controller: capturedByController,
                    decoration: const InputDecoration(labelText: 'Captured by'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  key: const Key('consentSubmitButton'),
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == true) {
      await controller.recordConsent(
        CaseSheetConsent(
          isGranted: granted,
          capturedBy: capturedByController.text.trim().isEmpty
              ? null
              : capturedByController.text.trim(),
          capturedAt: DateTime.now(),
        ),
      );
    }

    capturedByController.dispose();
  }

  Future<void> _showAttachmentDialog(BuildContext context) async {
    final controller = widget.controller;

    final result = await showDialog<_PickedAttachment>(
      context: context,
      builder: (context) {
        return _AttachmentPickerDialog(
          onPickFile: () async {
            final pickerResult = await FilePicker.platform.pickFiles(
              type: FileType.any,
              allowMultiple: false,
              withData: true,
            );

            if (pickerResult == null || pickerResult.files.isEmpty) {
              return null;
            }

            final pickedFile = pickerResult.files.first;
            final bytes = pickedFile.bytes;
            if (bytes == null) {
              return null;
            }

            return _PickedAttachment(
              fileName: pickedFile.name,
              contentType: _inferContentType(pickedFile),
              bytes: bytes,
            );
          },
          onPickSample: (sample) {
            final bytes = base64Decode(sample.base64Data);
            return _PickedAttachment(
              fileName: sample.fileName,
              contentType: sample.contentType,
              bytes: bytes,
            );
          },
        );
      },
    );

    if (result == null) {
      return;
    }

    try {
      await controller.uploadAttachment(
        fileName: result.fileName,
        contentType: result.contentType,
        bytes: result.bytes,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${result.fileName} uploaded successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showDeleteAttachmentDialog(
    BuildContext context,
    CaseSheetAttachment attachment,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete attachment'),
        content: Text('Are you sure you want to delete ${attachment.fileName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await widget.controller.removeAttachment(attachment);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${attachment.fileName} deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete attachment: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _navigateToPrescriptionForm(
    BuildContext context,
    CaseSheet caseSheet,
  ) async {
    final firestore = FirebaseFirestore.instance;
    final prescriptionController = PrescriptionController(
      FirestorePrescriptionRepository(firestore),
    );

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => PrescriptionFormPage(
          controller: prescriptionController,
          patient: widget.patient,
          caseSheetId: caseSheet.id,
        ),
      ),
    );

    prescriptionController.dispose();

    if (result == true && context.mounted) {
      // Prescription was created successfully, snackbar already shown
    }
  }

  String _inferContentType(PlatformFile file) {
    final extension = file.extension?.toLowerCase();
    if (extension == null) {
      return 'application/octet-stream';
    }

    const mapping = {
      'png': 'image/png',
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'gif': 'image/gif',
      'webp': 'image/webp',
      'pdf': 'application/pdf',
      'csv': 'text/csv',
      'txt': 'text/plain',
      'json': 'application/json',
      'mp4': 'video/mp4',
      'mov': 'video/quicktime',
      'mp3': 'audio/mpeg',
      'wav': 'audio/wav',
      'doc': 'application/msword',
      'docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'xls': 'application/vnd.ms-excel',
      'xlsx': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
    };

    return mapping[extension] ?? 'application/octet-stream';
  }

  Appointment? _findAppointment(String appointmentId) {
    if (appointmentId.isEmpty) {
      return null;
    }
    for (final appointment in widget.availableAppointments) {
      if (appointment.id == appointmentId) {
        return appointment;
      }
    }
    return null;
  }
}

class _PickedAttachment {
  const _PickedAttachment({
    required this.fileName,
    required this.contentType,
    required this.bytes,
  });

  final String fileName;
  final String contentType;
  final Uint8List bytes;
}

class _AttachmentPickerDialog extends StatefulWidget {
  const _AttachmentPickerDialog({
    required this.onPickFile,
    required this.onPickSample,
  });

  final Future<_PickedAttachment?> Function() onPickFile;
  final _PickedAttachment? Function(_AttachmentSample sample) onPickSample;

  @override
  State<_AttachmentPickerDialog> createState() => _AttachmentPickerDialogState();
}

class _AttachmentPickerDialogState extends State<_AttachmentPickerDialog> {
  _PickedAttachment? _pickedAttachment;
  bool _isPicking = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Upload attachment'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilledButton.icon(
              key: const Key('attachmentPickFileButton'),
              onPressed: _isPicking
                  ? null
                  : () async {
                      setState(() => _isPicking = true);
                      try {
                        final picked = await widget.onPickFile();
                        if (picked != null) {
                          setState(() => _pickedAttachment = picked);
                        }
                      } finally {
                        if (mounted) {
                          setState(() => _isPicking = false);
                        }
                      }
                    },
              icon: _isPicking
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.attach_file),
              label: Text(_isPicking ? 'Selecting…' : 'Choose file'),
            ),
            const SizedBox(height: 16),
            Text(
              'Quick samples',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _attachmentSamples
                  .map(
                    (sample) => FilledButton.tonal(
                      key: Key('attachmentSampleButton_${sample.key}'),
                      onPressed: () {
                        final picked = widget.onPickSample(sample);
                        setState(() => _pickedAttachment = picked);
                      },
                      child: Text(sample.label),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
            if (_pickedAttachment != null)
              _AttachmentPreview(attachment: _pickedAttachment!),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const Key('attachmentSubmitButton'),
          onPressed: _pickedAttachment == null
              ? null
              : () => Navigator.of(context).pop(_pickedAttachment),
          child: const Text('Upload'),
        ),
      ],
    );
  }
}

class _AttachmentPreview extends StatelessWidget {
  const _AttachmentPreview({required this.attachment});

  final _PickedAttachment attachment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sizeInKb = attachment.bytes.lengthInBytes / 1024;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              attachment.fileName,
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Text(
              '${attachment.contentType} • ${sizeInKb.toStringAsFixed(1)} KB',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

const _attachmentSamples = <_AttachmentSample>[
  _AttachmentSample(
    key: 'photo',
    label: 'Use clinical photo sample',
    fileName: 'xray_sample.png',
    contentType: 'image/png',
    base64Data: 'c2FtcGxlX3BuZ19ieXRlcw==',
  ),
  _AttachmentSample(
    key: 'document',
    label: 'Use consent form (PDF sample)',
    fileName: 'consent_sample.pdf',
    contentType: 'application/pdf',
    base64Data: 'c2FtcGxlX3BkZl9ieXRlcw==',
  ),
];

class _AttachmentSample {
  const _AttachmentSample({
    required this.key,
    required this.label,
    required this.fileName,
    required this.contentType,
    required this.base64Data,
  });

  final String key;
  final String label;
  final String fileName;
  final String contentType;
  final String base64Data;
}

class _CaseSheetHeader extends StatelessWidget {
  const _CaseSheetHeader({
    required this.state,
    required this.onCreate,
  });

  final CaseSheetViewState state;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'Case history',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const Spacer(),
        FilledButton.icon(
          onPressed: state == CaseSheetViewState.saving ? null : onCreate,
          icon: const Icon(Icons.add),
          label: const Text('New case sheet'),
        ),
      ],
    );
  }
}

class _CaseSheetList extends StatelessWidget {
  const _CaseSheetList({
    required this.sheets,
    required this.selected,
    required this.onSelect,
  });

  final List<CaseSheet> sheets;
  final CaseSheet selected;
  final void Function(CaseSheet) onSelect;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 1,
      borderRadius: BorderRadius.circular(12),
      child: ListView.separated(
        itemCount: sheets.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final sheet = sheets[index];
          final isSelected = sheet.id == selected.id;
          return ListTile(
            title: Text(sheet.doctorInCharge.isEmpty ? 'Untitled visit' : sheet.doctorInCharge),
            subtitle: Text(sheet.chiefComplaint.isEmpty ? 'No complaint recorded' : sheet.chiefComplaint),
            selected: isSelected,
            selectedTileColor: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.2),
            onTap: () => onSelect(sheet),
          );
        },
      ),
    );
  }
}

class _CaseSheetDetails extends StatelessWidget {
  const _CaseSheetDetails({
    required this.sheet,
    required this.isSaving,
    required this.appointment,
    required this.onRecordConsent,
    required this.onAddAttachment,
    required this.onDeleteAttachment,
    required this.onCreatePrescription,
  });

  final CaseSheet sheet;
  final bool isSaving;
  final Appointment? appointment;
  final VoidCallback onRecordConsent;
  final VoidCallback onAddAttachment;
  final void Function(CaseSheetAttachment) onDeleteAttachment;
  final VoidCallback onCreatePrescription;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text(
              sheet.doctorInCharge.isEmpty ? 'Doctor not assigned' : sheet.doctorInCharge,
              style: theme.textTheme.titleLarge,
            ),
            if (appointment != null) ...[
              const SizedBox(height: 8),
              Text('Linked appointment', style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                '${MaterialLocalizations.of(context).formatMediumDate(appointment!.start)} • '
                '${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(appointment!.start))}',
              ),
              const SizedBox(height: 4),
              Text('Purpose: ${appointment!.purpose.isEmpty ? 'Not specified' : appointment!.purpose}'),
              const SizedBox(height: 4),
              Text('Status: ${appointment!.status.value}'),
            ],
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  key: const Key('recordConsentButton'),
                  onPressed: isSaving ? null : onRecordConsent,
                  icon: const Icon(Icons.fact_check),
                  label: const Text('Record consent'),
                ),
                OutlinedButton.icon(
                  key: const Key('addAttachmentButton'),
                  onPressed: isSaving ? null : onAddAttachment,
                  icon: const Icon(Icons.attachment),
                  label: const Text('Add attachment'),
                ),
                FilledButton.tonalIcon(
                  key: const Key('createPrescriptionButton'),
                  onPressed: isSaving ? null : onCreatePrescription,
                  icon: const Icon(Icons.medication),
                  label: const Text('Create prescription'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              sheet.chiefComplaint.isEmpty ? 'No chief complaint recorded.' : sheet.chiefComplaint,
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            Text('Diagnosis', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(sheet.provisionalDiagnosis.isEmpty ? 'Pending diagnosis.' : sheet.provisionalDiagnosis),
            const SizedBox(height: 16),
            Text('Treatment plan', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(sheet.treatmentPlan.isEmpty ? 'No treatment plan yet.' : sheet.treatmentPlan),
            const SizedBox(height: 16),
            Text('Consent', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: Chip(
                label: Text(sheet.consent.isGranted ? 'Granted' : 'Pending'),
                backgroundColor: sheet.consent.isGranted
                    ? theme.colorScheme.primaryContainer
                    : theme.colorScheme.surfaceContainerHighest,
                labelStyle: theme.textTheme.labelLarge?.copyWith(
                  color: sheet.consent.isGranted
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            if (sheet.consent.capturedBy != null || sheet.consent.capturedAt != null) ...[
              const SizedBox(height: 8),
              if (sheet.consent.capturedBy != null)
                Text('Captured by: ${sheet.consent.capturedBy}'),
              if (sheet.consent.capturedAt != null)
                Text(
                  'Captured at: '
                  '${MaterialLocalizations.of(context).formatMediumDate(sheet.consent.capturedAt!)} • '
                  '${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(sheet.consent.capturedAt!))}',
                ),
            ],
            const SizedBox(height: 16),
            Text('Attachments', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            if (sheet.attachments.isEmpty)
              const Text('No attachments uploaded yet.')
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: sheet.attachments
                    .map(
                      (attachment) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.attachment, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(attachment.fileName),
                                  if (attachment.sizeBytes != null)
                                    Text(
                                      '${(attachment.sizeBytes! / 1024).toStringAsFixed(1)} KB',
                                      style: theme.textTheme.bodySmall,
                                    ),
                                ],
                              ),
                            ),
                            IconButton(
                              key: Key('deleteAttachment_${attachment.id}'),
                              icon: const Icon(Icons.delete_outline, size: 20),
                              onPressed: isSaving
                                  ? null
                                  : () => onDeleteAttachment(attachment),
                              tooltip: 'Delete attachment',
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              message,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.sticky_note_2_outlined, size: 48),
          SizedBox(height: 12),
          Text('No case sheets yet'),
          SizedBox(height: 8),
          Text('Create a visit note to capture findings.'),
        ],
      ),
    );
  }
}
