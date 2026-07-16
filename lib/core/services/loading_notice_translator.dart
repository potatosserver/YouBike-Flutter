import 'package:youbike/core/l10n/app_localizations.dart';

/// 將載入通知 key 透過 AppLocalizations 對應到本地化顯示字串。
/// 無任何硬編碼 — 全部來自 ARB。
class LoadingNoticeTranslator {
  const LoadingNoticeTranslator();

  String translate(String key, AppLocalizations l10n, {int? value}) {
    switch (key) {
      case 'init_starting':
        return l10n.init_starting;
      case 'init_requesting_permission':
        return l10n.init_requesting_permission;
      case 'init_verifying_permission':
        return l10n.init_verifying_permission;
      case 'init_locating':
        return l10n.init_locating;
      case 'init_map_engine':
        return l10n.init_map_engine;
      case 'init_map_tiles':
        return l10n.init_map_tiles;
      case 'init_syncing':
        return l10n.init_syncing;
      case 'init_syncing_stations':
        return l10n.init_syncing_stations(value ?? 0);
      case 'init_clustering':
        return l10n.init_clustering;
      case 'init_updating':
        return l10n.init_updating;
      case 'init_success':
        return l10n.init_success;
      default:
        return key;
    }
  }
}
