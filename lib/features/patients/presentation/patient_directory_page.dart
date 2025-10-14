import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/patient_profile.dart';
import 'patient_directory_controller.dart';
import 'patient_edit_page.dart';

enum _PatientAction { edit, delete }

class PatientDirectoryPage extends StatefulWidget {
  const PatientDirectoryPage({super.key});

  @override
  State<PatientDirectoryPage> createState() => _PatientDirectoryPageState();
}

class _PatientDirectoryPageState extends State<PatientDirectoryPage> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    final controller = context.read<PatientDirectoryController>();
    _searchController = TextEditingController(text: controller.searchQuery);
    _searchController.addListener(() {
      controller.setSearchQuery(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PatientDirectoryController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Patients'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.person_add),
        label: const Text('Add patient'),
        onPressed: () => _openEditor(context, controller, null),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildSearchField(context),
              const SizedBox(height: 16),
              Expanded(child: _buildContent(controller)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField(BuildContext context) {
    return TextField(
      controller: _searchController,
      decoration: const InputDecoration(
        labelText: 'Search patients',
        prefixIcon: Icon(Icons.search),
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _buildContent(PatientDirectoryController controller) {
    if (controller.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.errorMessage != null) {
      return _ErrorState(
        message: controller.errorMessage!,
        onRetry: controller.refresh,
      );
    }

    final patients = controller.patients;
    if (patients.isEmpty) {
      return const _EmptyState();
    }

    return RefreshIndicator(
      onRefresh: controller.refresh,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: patients.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final patient = patients[index];
          return ListTile(
            leading: _buildAvatar(patient),
            title: Text(patient.fullName),
            subtitle: Text(_buildSubtitle(patient)),
            onTap: () => _openEditor(context, controller, patient),
            trailing: PopupMenuButton<_PatientAction>(
              onSelected: (action) {
                switch (action) {
                  case _PatientAction.edit:
                    _openEditor(context, controller, patient);
                    break;
                  case _PatientAction.delete:
                    _confirmDelete(context, controller, patient);
                    break;
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: _PatientAction.edit,
                  child: ListTile(
                    leading: Icon(Icons.edit),
                    title: Text('Edit'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                PopupMenuItem(
                  value: _PatientAction.delete,
                  child: ListTile(
                    leading: Icon(Icons.delete_outline),
                    title: Text('Delete'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAvatar(PatientProfile patient) {
    final initials = patient.fullName.isNotEmpty
        ? patient.fullName.trim()[0].toUpperCase()
        : '?';
    return CircleAvatar(
      child: Text(initials),
    );
  }

  String _buildSubtitle(PatientProfile patient) {
    final details = <String>[
      if (patient.patientUid.isNotEmpty) 'UID: ${patient.patientUid}',
      if (patient.primaryPhone.isNotEmpty) 'Phone: ${patient.primaryPhone}',
    ];
    return details.join(' • ');
  }

  Future<void> _openEditor(
    BuildContext context,
    PatientDirectoryController controller,
    PatientProfile? patient,
  ) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PatientEditPage(
          controller: controller,
          initialProfile: patient,
        ),
      ),
    );

    if (result == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(patient == null
              ? 'Patient created successfully'
              : 'Patient updated successfully'),
        ),
      );
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    PatientDirectoryController controller,
    PatientProfile patient,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete patient'),
        content: Text(
          'Are you sure you want to delete ${patient.fullName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await controller.deletePatient(patient.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Patient deleted')),
          );
        }
      } catch (error) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete patient: $error')),
          );
        }
      }
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.person_outline, size: 48),
          const SizedBox(height: 12),
          Text(
            'No patients yet',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Add the first patient to get started.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48),
          const SizedBox(height: 12),
          Text(
            'Something went wrong',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.tonalIcon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Try again'),
          ),
        ],
      ),
    );
  }
}
