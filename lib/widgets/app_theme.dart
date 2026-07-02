import 'package:flutter/material.dart';

class AppColors {
  // Based on variables.css and web implementation
  static const Color primary = Color(0xFF007BFF); // Web Primary Blue
  static const Color primaryDark = Color(0xFF0056B3);
  static const Color accent = Color(0xFFFFA000);
  
  // Web specific colors
  static const Color searchBg = Color(0xFFFFE8D6);
  static const Color cardLightBg = Color(0xFFFFF2EC);
  static const Color mainBgLight = Color(0xFFF4F4F4);
  
  // Light Mode
  static const Color bgLight = mainBgLight;
  static const Color cardLight = cardLightBg;
  static const Color textLight = Color(0xFF333333);
  
  // Dark Mode
  static const Color bgDark = Color(0xFF121212);
  static const Color cardDark = Color(0xFF1E1E1E);
  static const Color textDark = Color(0xFFE0E0E0);
}
