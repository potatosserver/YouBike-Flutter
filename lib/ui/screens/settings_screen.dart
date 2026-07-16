import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youbike/core/l10n/app_localizations.dart';
import 'package:youbike/data/services/app_config_service.dart';
import 'package:youbike/ui/widgets/setting_group_card.dart';
import 'package:youbike/ui/widgets/changelog_dialog.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _version = '...';

  @override
  void initState() {
    super.initState();
    _initVersion();
  }

  Future<void> _initVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() => _version = packageInfo.version);
      }
    } catch (_) {
      if (mounted) setState(() => _version = 'Error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = Provider.of<AppConfigService>(context);
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: Text(l10n.settings_title),
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        elevation: 0,
        centerTitle: false,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
          children: [
            // ── 參數設定 ──
            SettingGroupCard(
              title: l10n.param_settings,
              children: [
                _buildItem(
                  icon: Icons.palette_outlined,
                  title: l10n.settings_theme,
                  trailing: Icon(Icons.chevron_right,
                      size: 22, color: cs.onSurfaceVariant),
                  onTap: () => context.push('/theme-selection'),
                ),
                _buildItem(
                  icon: Icons.map_outlined,
                  title: l10n.settings_region,
                  trailing: Icon(Icons.chevron_right,
                      size: 22, color: cs.onSurfaceVariant),
                  onTap: () => context.push('/region-selection'),
                ),
                _buildItem(
                  icon: Icons.language_outlined,
                  title: l10n.settings_language,
                  trailing: Icon(Icons.chevron_right,
                      size: 22, color: cs.onSurfaceVariant),
                  onTap: () => context.push('/language-selection'),
                ),
                _buildItem(
                  icon: Icons.location_on_outlined,
                  title: l10n.settings_location,
                  trailing: Switch(
                    value: config.useLocation,
                    onChanged: (val) => config.setUseLocation(val),
                    activeTrackColor: cs.primary,
                    activeThumbColor: cs.onPrimary,
                  ),
                  onTap: null,
                ),
              ],
            ),

            // ── 關於 ──
            SettingGroupCard(
              title: l10n.about,
              children: [
                _buildItem(
                  icon: Icons.article_outlined,
                  title: l10n.settings_logs,
                  trailing: Icon(Icons.chevron_right,
                      size: 22, color: cs.onSurfaceVariant),
                  onTap: () => context.push('/app-logs'),
                ),
                _buildItem(
                  icon: Icons.info_outline,
                  title: l10n.about_youbike,
                  trailing: Icon(Icons.chevron_right,
                      size: 22, color: cs.onSurfaceVariant),
                  onTap: () => _showAboutDialog(),
                ),
                _buildItem(
                  icon: Icons.code,
                  title: l10n.github_source_code,
                  trailing: Icon(Icons.open_in_new,
                      size: 20, color: cs.onSurfaceVariant),
                  onTap: () async {
                    final url = Uri.parse(
                      'https://github.com/potatosserver/YouBike-Flutter',
                    );
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url,
                          mode: LaunchMode.externalApplication);
                    }
                  },
                ),
                _buildItem(
                  icon: Icons.system_update_outlined,
                  title: l10n.check_for_updates,
                  onTap: () {
                    Fluttertoast.showToast(msg: l10n.latest_version_installed);
                  },
                ),
                _buildItem(
                  icon: Icons.description_outlined,
                  title: l10n.view_changelog,
                  onTap: () => ChangelogDialog.show(context),
                ),
              ],
            ),

            // ── 重設 App ──
            SettingGroupCard(
              title: l10n.app_reset,
              children: [
                _buildItem(
                  icon: Icons.replay_outlined,
                  title: l10n.rerun_setup,
                  onTap: () => context.go('/welcome'),
                ),
                _buildItem(
                  icon: Icons.delete_forever_outlined,
                  title: l10n.clear_data_button,
                  subtitle: l10n.app_reset_desc,
                  iconColor: cs.error,
                  titleColor: cs.error,
                  subtitleColor: cs.error.withAlpha(180),
                  onTap: () => _showClearDataDialog(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItem({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    Color? iconColor,
    Color? titleColor,
    Color? subtitleColor,
  }) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(icon, color: iconColor ?? cs.onSurfaceVariant, size: 22),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: titleColor ?? cs.onSurface,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(
                fontSize: 13,
                color: subtitleColor ?? cs.onSurfaceVariant,
              ),
            )
          : null,
      trailing: trailing,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  void _showAboutDialog() {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.about_youbike),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.about_youbike_content,
                  style: theme.textTheme.bodyMedium),
              const SizedBox(height: 20),
              _buildAboutRow(icon: Icons.code, text: l10n.github_source_code),
              const SizedBox(height: 12),
              _buildAboutRow(
                  icon: Icons.badge_outlined, text: l10n.developer_label),
              const SizedBox(height: 12),
              _buildAboutRow(
                  icon: Icons.info_outline, text: l10n.version_label(_version)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.close),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutRow({required IconData icon, required String text}) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 20, color: cs.onSurfaceVariant),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: cs.onSurface, fontSize: 14),
          ),
        ),
      ],
    );
  }

  void _showClearDataDialog() {
    final l10n = AppLocalizations.of(context);
    final router = GoRouter.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.clear_data_confirm_title),
        content: Text(l10n.clear_data_confirm_content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              if (ctx.mounted) {
                Navigator.pop(ctx);
                router.go('/welcome');
              }
            },
            child: Text(
              l10n.confirm,
              style: TextStyle(color: Theme.of(ctx).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }
}
