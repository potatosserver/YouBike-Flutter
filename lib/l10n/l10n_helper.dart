
import 'package:flutter/material.dart';
import 'app_localizations.dart';

class L10n {
  static String t(BuildContext context, String key, [Map<String, String>? args]) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return key;

    // Use the getters directly from the generated AppLocalizations
    // to avoid maintaining a manual switch-case mapping.
    
    // This is a simplified helper. For a production app, we'd 
    // use the generated getters directly in the UI.
    switch (key) {
      case 'searchPlaceholder': return l10n.searchPlaceholder;
      case 'updatingIn': return l10n.updatingIn(args?['sec'] ?? '0');
      case 'routeNotFound': return l10n.routeNotFound;
      case 'electricBikeError': return l10n.electricBikeError(args?['err'] ?? 'Error');
      case 'noElectricBikes': return l10n.noElectricBikes;
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
      case 'autoRefresh': return l10n.autoRefresh;
      case 'loading': return l10n.loading;
      case 'paramSettings': return l10n.param_settings;
      case 'about': return l10n.about;
      case 'appReset': return l10n.app_reset;
      default: return key;
    }
  }
}
