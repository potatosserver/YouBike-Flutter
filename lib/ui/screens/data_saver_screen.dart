import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:youbike/core/l10n/app_localizations.dart';
import 'package:youbike/data/services/app_config_service.dart';
import 'package:youbike/ui/widgets/setting_group_card.dart';

/// 流量節省模式子選項頁面。
///
/// 由 [SettingsScreen] 的流量節省入口導航至此。
/// 頁面有兩個層次的灰化邏輯：
/// 1. 總開關 OFF → 所有子項目全灰（subtitle 仍顯示各自原有訊息）
/// 2. 總開關 ON → 各子項目依自身條件灰化
class DataSaverScreen extends StatefulWidget {
  const DataSaverScreen({super.key});

  @override
  State<DataSaverScreen> createState() => _DataSaverScreenState();
}

class _DataSaverScreenState extends State<DataSaverScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final config = Provider.of<AppConfigService>(context);

    // 總開關狀態
    final bool masterOn = config.useDataSaver;

    // 各子項的灰化條件（僅總開關 ON 時才有意義）
    final bool moovoAvailable = config.useMoovo;
    final bool moovoFullyDisabled =
        !moovoAvailable || config.dsDisableMoovo;
    final bool statusMarkersAvailable = config.useMapStatusMarkers;

    // 當總開關 OFF，所有子項完全灰色（除總開關本體）
    // 當總開關 ON，各項依各自邏輯
    bool itemEnabled(int child) {
      if (!masterOn) return false; // 總關 → 全部灰
      switch (child) {
        case 0: // 跳過背景快取刷新：永遠可用
          return true;
        case 1: // 關閉 Moovo 自行車系統
          return moovoAvailable;
        case 2: // 關閉 Moovo 即時數據更新
          if (!moovoAvailable) return false;
          if (config.dsDisableMoovo) return false;
          return true;
        case 3: // 關閉站點圖釘標記
          return statusMarkersAvailable;
        case 4: // 僅在行動數據時生效
          return true;
        default:
          return true;
      }
    }

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: Text(l10n.data_saver_options_title),
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        elevation: 0,
        centerTitle: false,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          children: [
            // ── 卡片一：主開關 + 僅在行動數據時生效 ──
            SettingGroupCard(
              title: l10n.data_saver_title,
              children: [
                _buildItem(
                  context: context,
                  icon: Icons.data_saver_on,
                  title: l10n.data_saver_title,
                  subtitle: masterOn
                      ? l10n.data_saver_subtitle
                      : l10n.data_saver_subtitle,
                  enabled: true,
                  trailing: Switch(
                    value: masterOn,
                    onChanged: (val) => config.setUseDataSaver(val),
                    activeTrackColor: cs.primary,
                    activeThumbColor: cs.onPrimary,
                  ),
                ),
                _buildItem(
                  context: context,
                  icon: Icons.signal_cellular_alt,
                  title: l10n.data_saver_cellular_only_title,
                  subtitle: l10n.data_saver_cellular_only_subtitle,
                  enabled: itemEnabled(4),
                  trailing: Switch(
                    value: config.dsCellularOnly,
                    onChanged: itemEnabled(4)
                        ? (val) => config.setDsCellularOnly(val)
                        : null,
                    activeTrackColor: cs.primary,
                    activeThumbColor: cs.onPrimary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── 卡片二：底下 4 個子項目 ──
            SettingGroupCard(
              title: l10n.data_saver_options_title,
              children: [
                // 跳過背景快取刷新
                _buildItem(
                  context: context,
                  icon: Icons.cached_outlined,
                  title: l10n.data_saver_ds_skip_cache_refresh_title,
                  subtitle: l10n.data_saver_ds_skip_cache_refresh_subtitle,
                  enabled: itemEnabled(0),
                  trailing: Switch(
                    value: config.dsSkipCacheRefresh,
                    onChanged: itemEnabled(0)
                        ? (val) => config.setDsSkipCacheRefresh(val)
                        : null,
                    activeTrackColor: cs.primary,
                    activeThumbColor: cs.onPrimary,
                  ),
                ),
                // 關閉 Moovo 自行車系統
                _buildItem(
                  context: context,
                  icon: Icons.pedal_bike_outlined,
                  title: l10n.data_saver_ds_disable_moovo_title,
                  subtitle: moovoAvailable
                      ? l10n.data_saver_ds_disable_moovo_subtitle
                      : l10n.data_saver_needs_moovo,
                  enabled: itemEnabled(1),
                  trailing: Switch(
                    value: config.dsDisableMoovo,
                    onChanged: itemEnabled(1)
                        ? (val) => config.setDsDisableMoovo(val)
                        : null,
                    activeTrackColor: cs.primary,
                    activeThumbColor: cs.onPrimary,
                  ),
                ),
                // 關閉 Moovo 即時數據更新
                _buildItem(
                  context: context,
                  icon: Icons.sync_disabled_outlined,
                  title: l10n.data_saver_ds_skip_moovo_realtime_title,
                  subtitle: moovoFullyDisabled
                      ? l10n.data_saver_needs_moovo
                      : l10n.data_saver_ds_skip_moovo_realtime_subtitle,
                  enabled: itemEnabled(2),
                  trailing: Switch(
                    value: config.dsSkipMoovoRealtime,
                    onChanged: itemEnabled(2)
                        ? (val) => config.setDsSkipMoovoRealtime(val)
                        : null,
                    activeTrackColor: cs.primary,
                    activeThumbColor: cs.onPrimary,
                  ),
                ),
                // 關閉站點圖釘標記
                _buildItem(
                  context: context,
                  icon: Icons.location_pin,
                  title: l10n.data_saver_ds_disable_status_markers_title,
                  subtitle: statusMarkersAvailable
                      ? l10n.data_saver_ds_disable_status_markers_subtitle
                      : l10n.data_saver_needs_status_markers,
                  enabled: itemEnabled(3),
                  trailing: Switch(
                    value: config.dsDisableStatusMarkers,
                    onChanged: itemEnabled(3)
                        ? (val) => config.setDsDisableStatusMarkers(val)
                        : null,
                    activeTrackColor: cs.primary,
                    activeThumbColor: cs.onPrimary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    bool enabled = true,
  }) {
    final cs = Theme.of(context).colorScheme;
    final op = enabled ? 1.0 : 0.38;
    return ListTile(
      leading: Opacity(
        opacity: op,
        child: Icon(icon, color: cs.onSurfaceVariant, size: 22),
      ),
      title: Opacity(
        opacity: op,
        child: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: cs.onSurface,
          ),
        ),
      ),
      subtitle: subtitle != null
          ? Opacity(
              opacity: op,
              child: Text(
                subtitle,
                style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
              ),
            )
          : null,
      trailing: trailing != null
          ? Opacity(opacity: op, child: trailing)
          : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}