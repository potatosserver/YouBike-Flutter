import 'package:flutter/material.dart';
import 'package:youbike_android/core/l10n/app_localizations.dart';

/// L10n 助手類別，提供簡潔的本地化訪問方式
extension L10nExtension on BuildContext {
  /// 直接透過 context 訪問本地化字串
  ///
  /// 使用方式：
  /// ```dart
  /// Text(context.l10n.init_starting)
  /// ```
  AppLocalizations get l10n => AppLocalizations.of(this);
}

/// 全局 L10n 助手 (用於沒有 context 的地方)
class L10n {
  static AppLocalizations? _instance;

  static void setInstance(AppLocalizations instance) {
    _instance = instance;
  }

  static AppLocalizations get instance => _instance!;
}
