import 'package:cliniqflow/core/preferences/app_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('AppPreferences', () {
    late SharedPreferences prefs;
    late AppPreferences appPreferences;

    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      prefs = await SharedPreferences.getInstance();
      appPreferences = AppPreferences(prefs);
    });

    test('loadClinicianName returns default when unset or blank', () async {
      expect(appPreferences.loadClinicianName(), 'Clinician');

      await appPreferences.saveClinicianName('   ');
      expect(appPreferences.loadClinicianName(), 'Clinician');
      expect(prefs.getString('clinician_name'), 'Clinician');
    });

    test('saveClinicianName trims and persists value', () async {
      await appPreferences.saveClinicianName('  Dr. Jane Doe  ');
      expect(appPreferences.loadClinicianName(), 'Dr. Jane Doe');
      expect(prefs.getString('clinician_name'), 'Dr. Jane Doe');
    });

    test('load and save clinician photo url handles trimming and removal', () async {
      await prefs.setString('clinician_photo', '  https://example.com/photo.png  ');
      expect(appPreferences.loadClinicianPhotoUrl(), 'https://example.com/photo.png');

      await appPreferences.saveClinicianPhotoUrl('   https://cdn.example.com/avatar.jpg  ');
      expect(prefs.getString('clinician_photo'), 'https://cdn.example.com/avatar.jpg');

      await appPreferences.saveClinicianPhotoUrl('   ');
      expect(prefs.containsKey('clinician_photo'), isFalse);
      expect(appPreferences.loadClinicianPhotoUrl(), isNull);

      await appPreferences.saveClinicianPhotoUrl(null);
      expect(prefs.containsKey('clinician_photo'), isFalse);
    });

    test('theme mode persistence maps values correctly', () async {
      expect(appPreferences.loadThemeMode(), ThemeMode.system);

      await prefs.setString('theme_mode', 'light');
      expect(appPreferences.loadThemeMode(), ThemeMode.light);

      await prefs.setString('theme_mode', 'dark');
      expect(appPreferences.loadThemeMode(), ThemeMode.dark);

      await prefs.setString('theme_mode', 'unknown');
      expect(appPreferences.loadThemeMode(), ThemeMode.system);

      await appPreferences.saveThemeMode(ThemeMode.light);
      expect(prefs.getString('theme_mode'), 'light');

      await appPreferences.saveThemeMode(ThemeMode.dark);
      expect(prefs.getString('theme_mode'), 'dark');

      await appPreferences.saveThemeMode(ThemeMode.system);
      expect(prefs.getString('theme_mode'), 'system');
    });
  });
}
