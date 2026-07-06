import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_localizations.dart';

class LanguageService with ChangeNotifier {
  static const String _languageCodeKey = 'languageCode';

  Locale? _selectedLocale;
  final Locale _systemLocale = PlatformDispatcher.instance.locale;

  /// The locale explicitly selected by the user. This is `null` if the user wants to use the system default.
  Locale? get selectedLocale => _selectedLocale;

  /// The actual locale the app should use. It falls back to the system locale and then to the first supported locale.
  Locale get appLocale {
    final localeToUse = _selectedLocale ?? _systemLocale;

    // Check if a supported locale's language code matches the determined locale's language code.
    for (var supportedLocale in AppLocalizations.supportedLocales) {
      if (supportedLocale.languageCode == localeToUse.languageCode) {
        return supportedLocale; // Return the supported locale (e.g., 'zh' instead of 'zh_CN')
      }
    }

    // If no match is found, fall back to the first supported locale (usually English).
    return AppLocalizations.supportedLocales.first;
  }

  LanguageService() {
    loadLocale();
  }

  /// Loads the saved language preference from storage.
  Future<void> loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(_languageCodeKey);
    if (languageCode != null && languageCode.isNotEmpty) {
      _selectedLocale = Locale(languageCode);
    } else {
      _selectedLocale = null;
    }
    notifyListeners();
  }

  /// Saves a new language preference.
  Future<void> setLocale(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    // Only store the language code, not the country code.
    _selectedLocale = Locale(locale.languageCode);
    await prefs.setString(_languageCodeKey, locale.languageCode);
    notifyListeners();
  }

  /// Clears the saved language preference, reverting to the system default.
  Future<void> clearLocale() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_languageCodeKey);
    _selectedLocale = null;
    notifyListeners();
  }
}
