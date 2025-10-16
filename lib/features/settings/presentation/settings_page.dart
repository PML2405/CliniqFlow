import 'package:flutter/material.dart';

import '../../../core/models/clinician_profile.dart';
import '../../../core/widgets/user_avatar.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    required this.profileNotifier,
    required this.themeModeNotifier,
  });

  final ValueNotifier<ClinicianProfile> profileNotifier;
  final ValueNotifier<ThemeMode> themeModeNotifier;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final TextEditingController _nameController;
  late final TextEditingController _photoController;
  late ThemeMode _themeMode;

  @override
  void initState() {
    super.initState();
    final profile = widget.profileNotifier.value;
    _nameController = TextEditingController(text: profile.name);
    _photoController = TextEditingController(text: profile.photoUrl ?? '');
    _themeMode = widget.themeModeNotifier.value;
    widget.profileNotifier.addListener(_handleProfileChanged);
  }

  @override
  void dispose() {
    widget.profileNotifier.removeListener(_handleProfileChanged);
    _nameController.dispose();
    _photoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ValueListenableBuilder<ClinicianProfile>(
        valueListenable: widget.profileNotifier,
        builder: (context, profile, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Clinician profile', style: theme.textTheme.titleMedium),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  UserAvatar(
                    displayName: profile.name,
                    photoUrl: profile.photoUrl,
                    radius: 28,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      children: [
                        TextField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Your name',
                            border: OutlineInputBorder(),
                          ),
                          textCapitalization: TextCapitalization.words,
                          onChanged: (value) => _updateProfile(
                            name: value.trim().isEmpty ? 'Clinician' : value.trim(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _photoController,
                          decoration: const InputDecoration(
                            labelText: 'Photo URL (optional)',
                            border: OutlineInputBorder(),
                            helperText: 'Provide a direct image URL. Firebase Auth avatars will override this later.',
                          ),
                          keyboardType: TextInputType.url,
                          onChanged: (value) => _updateProfile(
                            photoUrl: value.trim().isEmpty ? null : value.trim(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Text('Appearance', style: theme.textTheme.titleMedium),
              const SizedBox(height: 16),
              SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment<ThemeMode>(
                    value: ThemeMode.system,
                    label: Text('Device'),
                    icon: Icon(Icons.phone_android),
                  ),
                  ButtonSegment<ThemeMode>(
                    value: ThemeMode.light,
                    label: Text('Light'),
                    icon: Icon(Icons.light_mode),
                  ),
                  ButtonSegment<ThemeMode>(
                    value: ThemeMode.dark,
                    label: Text('Dark'),
                    icon: Icon(Icons.dark_mode),
                  ),
                ],
                selected: <ThemeMode>{_themeMode},
                onSelectionChanged: (selection) {
                  if (selection.isEmpty) {
                    return;
                  }
                  final mode = selection.first;
                  setState(() => _themeMode = mode);
                  widget.themeModeNotifier.value = mode;
                },
                showSelectedIcon: false,
              ),
            ],
          );
        },
      ),
    );
  }

  void _handleProfileChanged() {
    if (!mounted) return;
    final profile = widget.profileNotifier.value;
    if (_nameController.text != profile.name) {
      _nameController.text = profile.name;
    }
    final photoValue = profile.photoUrl ?? '';
    if (_photoController.text != photoValue) {
      _photoController.text = photoValue;
    }
    setState(() {});
  }

  void _updateProfile({String? name, String? photoUrl}) {
    final current = widget.profileNotifier.value;
    final updated = current.copyWith(
      name: name ?? current.name,
      photoUrl: photoUrl ?? current.photoUrl,
    );
    widget.profileNotifier.value = updated;
  }
}
