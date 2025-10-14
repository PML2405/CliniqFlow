import 'package:flutter/material.dart';

import '../models/patient_profile.dart';
import 'patient_directory_controller.dart';

class PatientEditPage extends StatefulWidget {
  const PatientEditPage({
    super.key,
    required this.controller,
    this.initialProfile,
  });

  final PatientDirectoryController controller;
  final PatientProfile? initialProfile;

  @override
  State<PatientEditPage> createState() => _PatientEditPageState();
}

class _PatientEditPageState extends State<PatientEditPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _uidController;
  late final TextEditingController _nameController;
  late final TextEditingController _ageController;
  late final TextEditingController _addressController;
  late final TextEditingController _occupationController;
  late final TextEditingController _emailController;
  late final TextEditingController _residentialPhoneController;
  late final TextEditingController _officePhoneController;
  late final TextEditingController _emergencyNameController;
  late final TextEditingController _emergencyRelationController;
  late final TextEditingController _emergencyMobileController;
  late final TextEditingController _emergencyOfficeController;
  late final TextEditingController _referredByController;
  late final TextEditingController _generalHistoryController;
  late final TextEditingController _allergiesController;
  late final TextEditingController _medicationsController;
  late final TextEditingController _habitsController;
  late final TextEditingController _pastHistoryController;

  late DateTime _registrationDate;
  DateTime? _dateOfBirth;
  String? _sex;
  bool _isSaving = false;

  PatientProfile get _initial => widget.initialProfile ?? PatientProfile.empty();

  @override
  void initState() {
    super.initState();
    final profile = _initial;
    _registrationDate = profile.registrationDate;
    _dateOfBirth = profile.dateOfBirth;
    _sex = profile.sex;

    _uidController = TextEditingController(text: profile.patientUid);
    _nameController = TextEditingController(text: profile.fullName);
    _ageController = TextEditingController(text: profile.age?.toString() ?? '');
    _addressController = TextEditingController(text: profile.contactInfo.address ?? '');
    _occupationController = TextEditingController(text: profile.contactInfo.occupation ?? '');
    _emailController = TextEditingController(text: profile.contactInfo.email ?? '');
    _residentialPhoneController = TextEditingController(text: profile.contactInfo.residentialPhone ?? '');
    _officePhoneController = TextEditingController(text: profile.contactInfo.officePhone ?? '');
    _emergencyNameController = TextEditingController(text: profile.emergencyContact.name ?? '');
    _emergencyRelationController = TextEditingController(text: profile.emergencyContact.relation ?? '');
    _emergencyMobileController = TextEditingController(text: profile.emergencyContact.mobilePhone ?? '');
    _emergencyOfficeController = TextEditingController(text: profile.emergencyContact.officePhone ?? '');
    _referredByController = TextEditingController(text: profile.medicalHistory.referredBy ?? '');
    _generalHistoryController = TextEditingController(text: profile.medicalHistory.generalHistory ?? '');
    _allergiesController = TextEditingController(text: profile.medicalHistory.allergies ?? '');
    _medicationsController = TextEditingController(text: profile.medicalHistory.currentMedications ?? '');
    _habitsController = TextEditingController(text: profile.medicalHistory.habits.join(', '));
    _pastHistoryController = TextEditingController(text: profile.medicalHistory.pastHealthHistory ?? '');
  }

  @override
  void dispose() {
    _uidController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    _addressController.dispose();
    _occupationController.dispose();
    _emailController.dispose();
    _residentialPhoneController.dispose();
    _officePhoneController.dispose();
    _emergencyNameController.dispose();
    _emergencyRelationController.dispose();
    _emergencyMobileController.dispose();
    _emergencyOfficeController.dispose();
    _referredByController.dispose();
    _generalHistoryController.dispose();
    _allergiesController.dispose();
    _medicationsController.dispose();
    _habitsController.dispose();
    _pastHistoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialProfile != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit patient' : 'Add patient'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSectionTitle(context, 'Patient details'),
                _buildTextField(
                  controller: _uidController,
                  label: 'Patient UID',
                  textInputAction: TextInputAction.next,
                ),
                _buildTextField(
                  controller: _nameController,
                  label: 'Full name',
                  validator: _required,
                  textInputAction: TextInputAction.next,
                ),
                _buildDateTile(
                  label: 'Registration date',
                  valueText: _formatDate(_registrationDate),
                  onTap: () => _pickDate(
                    context,
                    initial: _registrationDate,
                    onSelected: (value) => setState(() => _registrationDate = value),
                  ),
                ),
                _buildDateTile(
                  label: 'Date of birth',
                  valueText: _dateOfBirth != null ? _formatDate(_dateOfBirth!) : 'Select',
                  onTap: () => _pickDate(
                    context,
                    initial: _dateOfBirth ?? DateTime.now(),
                    firstDate: DateTime(1900),
                    onSelected: (value) => setState(() => _dateOfBirth = value),
                  ),
                  allowNull: true,
                ),
                _buildTextField(
                  controller: _ageController,
                  label: 'Age',
                  keyboardType: TextInputType.number,
                  validator: _numeric,
                  textInputAction: TextInputAction.next,
                ),
                DropdownButtonFormField<String>(
                  initialValue: _sex,
                  decoration: const InputDecoration(labelText: 'Sex'),
                  items: const [
                    DropdownMenuItem(value: 'Male', child: Text('Male')),
                    DropdownMenuItem(value: 'Female', child: Text('Female')),
                    DropdownMenuItem(value: 'Other', child: Text('Other')),
                  ],
                  onChanged: (value) => setState(() => _sex = value),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle(context, 'Contact information'),
                _buildTextField(
                  controller: _addressController,
                  label: 'Address',
                  maxLines: 3,
                ),
                _buildTextField(
                  controller: _occupationController,
                  label: 'Occupation',
                  textInputAction: TextInputAction.next,
                ),
                _buildTextField(
                  controller: _emailController,
                  label: 'Email',
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                ),
                _buildTextField(
                  controller: _residentialPhoneController,
                  label: 'Residential phone',
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                ),
                _buildTextField(
                  controller: _officePhoneController,
                  label: 'Office phone',
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 24),
                _buildSectionTitle(context, 'Emergency contact'),
                _buildTextField(
                  controller: _emergencyNameController,
                  label: 'Name',
                  textInputAction: TextInputAction.next,
                ),
                _buildTextField(
                  controller: _emergencyRelationController,
                  label: 'Relation',
                  textInputAction: TextInputAction.next,
                ),
                _buildTextField(
                  controller: _emergencyMobileController,
                  label: 'Mobile phone',
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                ),
                _buildTextField(
                  controller: _emergencyOfficeController,
                  label: 'Office phone',
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 24),
                _buildSectionTitle(context, 'Medical history'),
                _buildTextField(
                  controller: _referredByController,
                  label: 'Referred by',
                  textInputAction: TextInputAction.next,
                ),
                _buildTextField(
                  controller: _generalHistoryController,
                  label: 'General history',
                  maxLines: 3,
                ),
                _buildTextField(
                  controller: _allergiesController,
                  label: 'Allergies',
                  maxLines: 2,
                ),
                _buildTextField(
                  controller: _medicationsController,
                  label: 'Current medications',
                  maxLines: 2,
                ),
                _buildTextField(
                  controller: _habitsController,
                  label: 'Habits (comma separated)',
                ),
                _buildTextField(
                  controller: _pastHistoryController,
                  label: 'Past health history',
                  maxLines: 3,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _isSaving ? null : _onSave,
                  icon: _isSaving
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save),
                  label: Text(_isSaving ? 'Saving...' : 'Save patient'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }
    return null;
  }

  String? _numeric(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    final parsed = int.tryParse(value.trim());
    if (parsed == null) {
      return 'Enter a valid number';
    }
    if (parsed < 0) {
      return 'Must be positive';
    }
    return null;
  }

  Future<void> _pickDate(
    BuildContext context, {
    required DateTime initial,
    DateTime? firstDate,
    DateTime? lastDate,
    required ValueChanged<DateTime> onSelected,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: firstDate ?? DateTime(2000),
      lastDate: lastDate ?? DateTime(2100),
    );
    if (picked != null) {
      onSelected(picked);
    }
  }

  Widget _buildDateTile({
    required String label,
    required String valueText,
    required VoidCallback onTap,
    bool allowNull = false,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: Text(valueText),
      trailing: IconButton(
        icon: const Icon(Icons.calendar_today),
        onPressed: onTap,
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    TextInputAction? textInputAction,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(labelText: label),
        keyboardType: keyboardType,
        validator: validator,
        textInputAction: textInputAction,
        maxLines: maxLines,
      ),
    );
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final profile = _initial.copyWith(
      patientUid: _uidController.text.trim(),
      fullName: _nameController.text.trim(),
      registrationDate: _registrationDate,
      dateOfBirth: _dateOfBirth,
      age: _ageController.text.trim().isEmpty
          ? null
          : int.parse(_ageController.text.trim()),
      sex: _sex,
      contactInfo: _initial.contactInfo.copyWith(
        address: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
        occupation: _occupationController.text.trim().isEmpty
            ? null
            : _occupationController.text.trim(),
        email: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        residentialPhone: _residentialPhoneController.text.trim().isEmpty
            ? null
            : _residentialPhoneController.text.trim(),
        officePhone: _officePhoneController.text.trim().isEmpty
            ? null
            : _officePhoneController.text.trim(),
      ),
      emergencyContact: _initial.emergencyContact.copyWith(
        name: _emergencyNameController.text.trim().isEmpty
            ? null
            : _emergencyNameController.text.trim(),
        relation: _emergencyRelationController.text.trim().isEmpty
            ? null
            : _emergencyRelationController.text.trim(),
        mobilePhone: _emergencyMobileController.text.trim().isEmpty
            ? null
            : _emergencyMobileController.text.trim(),
        officePhone: _emergencyOfficeController.text.trim().isEmpty
            ? null
            : _emergencyOfficeController.text.trim(),
      ),
      medicalHistory: _initial.medicalHistory.copyWith(
        referredBy: _referredByController.text.trim().isEmpty
            ? null
            : _referredByController.text.trim(),
        generalHistory: _generalHistoryController.text.trim().isEmpty
            ? null
            : _generalHistoryController.text.trim(),
        allergies: _allergiesController.text.trim().isEmpty
            ? null
            : _allergiesController.text.trim(),
        currentMedications: _medicationsController.text.trim().isEmpty
            ? null
            : _medicationsController.text.trim(),
        habits: _habitsController.text
            .split(',')
            .map((habit) => habit.trim())
            .where((habit) => habit.isNotEmpty)
            .toList(),
        pastHealthHistory: _pastHistoryController.text.trim().isEmpty
            ? null
            : _pastHistoryController.text.trim(),
      ),
      updatedAt: DateTime.now(),
    );

    try {
      await widget.controller.savePatient(profile);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save patient: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}
