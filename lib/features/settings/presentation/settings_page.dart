import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    required this.nameNotifier,
    required this.themeModeNotifier,
  });

  final ValueNotifier<String> nameNotifier;
  final ValueNotifier<ThemeMode> themeModeNotifier;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final TextEditingController _controller;
  late ThemeMode _themeMode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.nameNotifier.value);
    _themeMode = widget.themeModeNotifier.value;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Clinician profile', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Your name',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
              onChanged: (value) => widget.nameNotifier.value = value.trim().isEmpty ? 'Clinician' : value.trim(),
            ),
            const SizedBox(height: 32),
            Text('Appearance', style: Theme.of(context).textTheme.titleMedium),
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
        ),
      ),
    );
  }
}
