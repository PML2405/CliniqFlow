import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppPreferences {
  AppPreferences(this._prefs);

  static const _clinicianNameKey = 'clinician_name';
  static const _themeModeKey = 'theme_mode';

  final SharedPreferences _prefs;

  String loadClinicianName() {
    return _prefs.getString(_clinicianNameKey) ?? 'Clinician';
  }

  Future<void> saveClinicianName(String name) async {
    await _prefs.setString(_clinicianNameKey, name.trim().isEmpty ? 'Clinician' : name.trim());
  }

  ThemeMode loadThemeMode() {
    final stored = _prefs.getString(_themeModeKey);
    if (stored == null) {
      return ThemeMode.system;
    }
    switch (stored) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> saveThemeMode(ThemeMode mode) async {
    final value = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await _prefs.setString(_themeModeKey, value);
  }

  static Future<AppPreferences> instance() async {
    final prefs = await SharedPreferences.getInstance();
    return AppPreferences(prefs);
  }
}
