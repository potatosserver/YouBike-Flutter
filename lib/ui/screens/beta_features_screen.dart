import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:youbike/core/l10n/app_localizations.dart';
import 'package:youbike/data/services/app_config_service.dart';
import 'package:youbike/ui/widgets/setting_group_card.dart';

/// Beta 版功能頁（位於 設定 → 參數 → Beta 版）。
///
/// 此頁只是各功能開關的容器，**本身不帶 master switch**。
/// 每個功能（Moovo 自行車系統、未來將增加的 Tio、YouBike 2.0 等）
/// 在各自的 SettingGroupCard 內以獨立的 Switch 呈現。
class BetaFeaturesScreen extends StatelessWidget {
  const BetaFeaturesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final config = Provider.of<AppConfigService>(context);

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: Text(l10n.beta_features_page_title),
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        elevation: 0,
        centerTitle: false,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          children: [
            SettingGroupCard(
              title: l10n.beta_providers_group_title,
              children: [
                _buildItem(
                  context: context,
                  icon: Icons.pedal_bike_outlined,
                  title: l10n.beta_moovo_provider,
                  subtitle: l10n.beta_moovo_subtitle,
                  trailing: Switch(
                    value: config.useMoovo,
                    onChanged: (val) => _handleBetaToggle(
                      context,
                      currentValue: config.useMoovo,
                      newValue: val,
                      onConfirm: () => config.setUseMoovo(val),
                    ),
                    activeTrackColor: cs.primary,
                    activeThumbColor: cs.onPrimary,
                  ),
                ),
                _buildItem(
                  context: context,
                  icon: Icons.location_pin,
                  title: l10n.beta_map_status_markers,
                  subtitle: l10n.beta_map_status_markers_subtitle,
                  trailing: Switch(
                    value: config.useMapStatusMarkers,
                    onChanged: (val) => _handleBetaToggle(
                      context,
                      currentValue: config.useMapStatusMarkers,
                      newValue: val,
                      onConfirm: () => config.setUseMapStatusMarkers(val),
                    ),
                    activeTrackColor: cs.primary,
                    activeThumbColor: cs.onPrimary,
                  ),
                ),
                _buildItem(
                  context: context,
                  icon: Icons.tune,
                  title: l10n.beta_station_filter,
                  subtitle: l10n.beta_station_filter_subtitle,
                  trailing: Switch(
                    value: config.useStationFilter,
                    onChanged: (val) => _handleBetaToggle(
                      context,
                      currentValue: config.useStationFilter,
                      newValue: val,
                      onConfirm: () => config.setUseStationFilter(val),
                    ),
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

  Future<void> _handleBetaToggle(
    BuildContext context, {
    required bool currentValue,
    required bool newValue,
    required VoidCallback onConfirm,
  }) async {
    if (!newValue) {
      onConfirm();
      return;
    }

    final l10n = AppLocalizations.of(context);
    final accepted = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.beta_features_page_title),
        content: const Text(
          '此功能還在實驗中，開啟此 Beta 功能可能導致多餘的網路流量或造成卡頓。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );

    if (accepted == true) {
      onConfirm();
    }
  }

  Widget _buildItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
  }) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(icon, color: cs.onSurfaceVariant, size: 22),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: cs.onSurface,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
            )
          : null,
      trailing: trailing,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}
