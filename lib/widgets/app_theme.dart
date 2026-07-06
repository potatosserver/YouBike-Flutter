import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppColors {
  static const Color primary = Colors.blue;
  static const Color accent = Colors.blueAccent;
  static const Color backgroundLight = Color(0xFFF5F5F5);
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceLight = Colors.white;
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color error = Colors.redAccent;
  static const Color success = Colors.greenAccent;
  static const Color warning = Colors.orangeAccent;
  static const Color textPrimaryLight = Color(0xFF212121);
  static const Color textPrimaryDark = Color(0xFFEEEEEE);
  
  // Specific colors needed by widgets
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color cardDark = Color(0xFF2C2C2C);
  static const Color stationCardBg = Color(0xFFF8F9FA);
}

class ThemeProvider with ChangeNotifier {
  static const String _themeModeKey = 'themeMode';

  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  ThemeProvider() {
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final modeString = prefs.getString(_themeModeKey);
    if (modeString == 'light') {
      _themeMode = ThemeMode.light;
    } else if (modeString == 'dark') {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.system;
    }
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, mode.name);
    notifyListeners();
  }
}
