
import 'package:flutter/material.dart';
import 'app_localizations.dart';

class L10n {
  static String t(BuildContext context, String key, [Map<String, String>? args]) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return key;
    
    switch (key) {
      case 'searchPlaceholder': return l10n.searchPlaceholder;
      case 'updating': return '更新中...';
      case 'autoRefresh': return '後更新';
      case 'sec': return '秒';
      case 'updatingIn': return l10n.updatingIn(args?['sec'] ?? '0');
      case 'routeNotFound': return l10n.routeNotFound;
      case 'electricBikeError': return l10n.electricBikeError(args?['err'] ?? 'Error');
      case 'noElectricBikes': return l10n.noElectricBikes;
      case 'electricBikeDetailsTitle': return '電輔車詳情';
      case 'bikeNumber': return l10n.bikeNumber;
      case 'pillarNumber': return l10n.pillarNumber;
      case 'ok': return l10n.ok;
      case 'distance': return l10n.distance;
      case 'address': return l10n.address;
      case 'availableBikes': return l10n.availableBikes;
      case 'availableElectricBikes': return l10n.availableElectricBikes;
      case 'emptySpaces': return l10n.emptySpaces;
      case 'settings': return l10n.settings;
      case 'darkMode': return l10n.darkMode;
      case 'language': return l10n.language;
      case 'loading': return l10n.loading;
      case 'paramSettings': return l10n.param_settings;
      case 'about': return l10n.about;
      case 'appReset': return l10n.app_reset;
      case 'locationTrackingEnabled': return '位置追蹤已開啟';
      case 'navigationUnavailable': return '導航服務不可用';
      case 'noStationsFound': return '找不到符合的站點';
      default: return key;
    }
  }
}
