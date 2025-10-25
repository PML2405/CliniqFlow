import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../patients/models/patient_profile.dart';
import '../models/prescription.dart';
import '../services/prescription_pdf_service.dart';
import 'prescription_controller.dart';
import 'prescription_form_page.dart';

/// Page displaying prescription history for a patient
class PrescriptionListPage extends StatefulWidget {
  const PrescriptionListPage({
    required this.controller,
    required this.patient,
    super.key,
  });

  final PrescriptionController controller;
  final PatientProfile patient;

  @override
  State<PrescriptionListPage> createState() => _PrescriptionListPageState();
}

class _PrescriptionListPageState extends State<PrescriptionListPage> {
  final _pdfService = PrescriptionPdfService();
  bool _isGeneratingPdf = false;

  @override
  void initState() {
    super.initState();
    widget.controller.initialize(widget.patient.id);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text('Prescriptions'),
          ),
          floatingActionButton: FloatingActionButton.extended(
            key: const Key('createPrescriptionButton'),
            icon: const Icon(Icons.add),
            label: const Text('New prescription'),
            onPressed: () => _navigateToCreatePrescription(context),
          ),
          body: ListenableBuilder(
            listenable: widget.controller,
            builder: (context, _) {
              return _buildContent();
            },
          ),
        ),
        if (_isGeneratingPdf)
          Container(
            color: Colors.black54,
            child: const Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Generating PDF...'),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildContent() {
    final state = widget.controller.state;
    final error = widget.controller.errorMessage;

    if (state == PrescriptionViewState.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state == PrescriptionViewState.error && error != null) {
      return _ErrorView(
        message: error,
        onRetry: () => widget.controller.initialize(widget.patient.id),
      );
    }

    final prescriptions = widget.controller.prescriptions;
    if (prescriptions.isEmpty) {
      return const _EmptyView();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: prescriptions.length,
      itemBuilder: (context, index) {
        final prescription = prescriptions[index];
        return _PrescriptionCard(
          prescription: prescription,
          onTap: () => _viewPrescription(context, prescription),
          onEdit: () => _editPrescription(context, prescription),
          onDelete: () => _deletePrescription(context, prescription),
        );
      },
    );
  }

  Future<void> _navigateToCreatePrescription(BuildContext context) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => PrescriptionFormPage(
          controller: widget.controller,
          patient: widget.patient,
        ),
      ),
    );

    if (result == true && mounted) {
      // Prescription was created successfully
    }
  }

  void _viewPrescription(BuildContext context, Prescription prescription) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => _PrescriptionDetailsSheet(
          prescription: prescription,
          scrollController: scrollController,
          onEdit: () {
            Navigator.pop(context);
            _editPrescription(context, prescription);
          },
          onDelete: () {
            Navigator.pop(context);
            _deletePrescription(context, prescription);
          },
          onPrint: () {
            Navigator.pop(context);
            _printPrescription(context, prescription);
          },
          onShare: () {
            Navigator.pop(context);
            _sharePrescription(context, prescription);
          },
        ),
      ),
    );
  }

  Future<void> _editPrescription(
    BuildContext context,
    Prescription prescription,
  ) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => PrescriptionFormPage(
          controller: widget.controller,
          patient: widget.patient,
          prescription: prescription,
        ),
      ),
    );

    if (result == true && mounted) {
      // Prescription was updated successfully
    }
  }

  Future<void> _deletePrescription(
    BuildContext context,
    Prescription prescription,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete prescription'),
        content: Text(
          'Are you sure you want to delete the prescription from '
          '${DateFormat.yMMMd().format(prescription.prescriptionDate)}?',
        ),
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

    if (confirmed == true && mounted) {
      try {
        await widget.controller.deletePrescription(prescription.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Prescription deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete prescription: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _printPrescription(
    BuildContext context,
    Prescription prescription,
  ) async {
    setState(() => _isGeneratingPdf = true);
    try {
      final pdfBytes = await _pdfService.generatePrescriptionPdf(prescription);
      await Printing.layoutPdf(
        onLayout: (format) async => pdfBytes,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to print prescription: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGeneratingPdf = false);
      }
    }
  }

  Future<void> _sharePrescription(
    BuildContext context,
    Prescription prescription,
  ) async {
    setState(() => _isGeneratingPdf = true);
    try {
      final pdfBytes = await _pdfService.generatePrescriptionPdf(prescription);
      final tempDir = await getTemporaryDirectory();
      final fileName = 'prescription_${prescription.patientUid}_'
          '${DateFormat('yyyyMMdd').format(prescription.prescriptionDate)}.pdf';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(pdfBytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Prescription for ${prescription.patientName}',
        text: 'Prescription from ${prescription.doctorName} dated '
            '${DateFormat.yMMMd().format(prescription.prescriptionDate)}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share prescription: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGeneratingPdf = false);
      }
    }
  }
}

class _PrescriptionCard extends StatelessWidget {
  const _PrescriptionCard({
    required this.prescription,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final Prescription prescription;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat.yMMMd();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          prescription.doctorName,
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dateFormat.format(prescription.prescriptionDate),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: onEdit,
                        tooltip: 'Edit prescription',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: onDelete,
                        tooltip: 'Delete prescription',
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(
                    avatar: const Icon(Icons.medication, size: 16),
                    label: Text('${prescription.items.length} medication(s)'),
                    visualDensity: VisualDensity.compact,
                  ),
                  if (prescription.caseSheetId != null)
                    Chip(
                      avatar: const Icon(Icons.note_outlined, size: 16),
                      label: const Text('Linked to case sheet'),
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrescriptionDetailsSheet extends StatelessWidget {
  const _PrescriptionDetailsSheet({
    required this.prescription,
    required this.scrollController,
    required this.onEdit,
    required this.onDelete,
    required this.onPrint,
    required this.onShare,
  });

  final Prescription prescription;
  final ScrollController scrollController;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onPrint;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat.yMMMd();

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: theme.colorScheme.outlineVariant,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Prescription Details',
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dateFormat.format(prescription.prescriptionDate),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(16),
              children: [
                _InfoSection(
                  title: 'Patient',
                  content: prescription.patientName,
                ),
                const SizedBox(height: 16),
                _InfoSection(
                  title: 'Doctor',
                  content: prescription.doctorName,
                ),
                const SizedBox(height: 24),
                Text(
                  'Medications',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                ...prescription.items.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  return _MedicationCard(
                    item: item,
                    index: index + 1,
                  );
                }),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onPrint,
                        icon: const Icon(Icons.print),
                        label: const Text('Print'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onShare,
                        icon: const Icon(Icons.share),
                        label: const Text('Share'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit),
                        label: const Text('Edit'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete),
                        label: const Text('Delete'),
                        style: FilledButton.styleFrom(
                          backgroundColor: theme.colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({
    required this.title,
    required this.content,
  });

  final String title;
  final String content;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          content,
          style: theme.textTheme.bodyLarge,
        ),
      ],
    );
  }
}

class _MedicationCard extends StatelessWidget {
  const _MedicationCard({
    required this.item,
    required this.index,
  });

  final PrescriptionItem item;
  final int index;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  child: Text(
                    '$index',
                    style: theme.textTheme.labelLarge,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.drugName,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _MedicationDetail(
              icon: Icons.medication,
              label: 'Dosage',
              value: item.dosage,
            ),
            const SizedBox(height: 8),
            _MedicationDetail(
              icon: Icons.schedule,
              label: 'Frequency',
              value: item.frequency,
            ),
            const SizedBox(height: 8),
            _MedicationDetail(
              icon: Icons.calendar_today,
              label: 'Duration',
              value: item.duration,
            ),
            if (item.notes != null && item.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              _MedicationDetail(
                icon: Icons.note,
                label: 'Notes',
                value: item.notes!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MedicationDetail extends StatelessWidget {
  const _MedicationDetail({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.medication_outlined,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No prescriptions yet',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Create a prescription to get started',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
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
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: theme.colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Error loading prescriptions',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
