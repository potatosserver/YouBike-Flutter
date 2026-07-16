import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:youbike/core/l10n/app_localizations.dart';

class LanguageService with ChangeNotifier {
  static const String _languageCodeKey = 'languageCode';

  Locale? _selectedLocale;
  final Locale _systemLocale = PlatformDispatcher.instance.locale;

  /// 使用者明確選擇的 locale。若為 null 表示使用系統預設。
  Locale? get selectedLocale => _selectedLocale;

  /// App 實際使用的 locale。依序回退：使用者選擇 → 系統 → 第一個支援的 locale。
  Locale get appLocale {
    final localeToUse = _selectedLocale ?? _systemLocale;

    // 檢查支援的 locale 是否匹配
    for (var supportedLocale in AppLocalizations.supportedLocales) {
      if (supportedLocale.languageCode == localeToUse.languageCode) {
        return supportedLocale;
      }
    }

    // 中文特殊處理：將 zh_TW、zh_CN 等映射到支援的 zh
    if (localeToUse.languageCode.startsWith('zh')) {
      return AppLocalizations.supportedLocales.firstWhere(
          (l) => l.languageCode == 'zh',
          orElse: () => AppLocalizations.supportedLocales.first);
    }

    return AppLocalizations.supportedLocales.first;
  }

  LanguageService() {
    loadLocale();
  }

  /// 從儲存載入語言偏好。
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

  /// 儲存新的語言偏好。
  Future<void> setLocale(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    // 僅儲存語言代碼，不含地區碼
    _selectedLocale = Locale(locale.languageCode);
    await prefs.setString(_languageCodeKey, locale.languageCode);
    notifyListeners();
  }

  /// 清除已儲存的語言偏好，恢復系統預設。
  Future<void> clearLocale() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_languageCodeKey);
    _selectedLocale = null;
    notifyListeners();
  }
}
