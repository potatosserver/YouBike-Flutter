import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:youbike_android/services/language_service.dart';
import 'package:youbike_android/widgets/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Verification Tests', () {
    test('LanguageService should load and set locale', () async {
      SharedPreferences.setMockInitialValues({});
      final service = LanguageService();
      
      // Initial state (should be system or first supported)
      expect(service.appLocale, isNotNull);
      
      // Set to English
      await service.setLocale(const Locale('en'));
      expect(service.selectedLocale?.languageCode, 'en');
      expect(service.appLocale.languageCode, 'en');
    });

    test('ThemeProvider should load and set theme mode', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = ThemeProvider();
      
      // Initial state
      expect(provider.themeMode, ThemeMode.system);
      
      // Set to Dark
      provider.setThemeMode(ThemeMode.dark);
      expect(provider.themeMode, ThemeMode.dark);
    });
  });
}
