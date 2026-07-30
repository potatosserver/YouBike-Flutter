import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youbike/core/config/app_environment.dart';
import 'package:youbike/core/l10n/app_localizations.dart';
import 'package:youbike/core/services/update_checker_service.dart';
import 'package:youbike/data/services/app_config_service.dart';
import 'package:youbike/ui/widgets/setting_group_card.dart';
import 'package:youbike/ui/widgets/changelog_dialog.dart';
import 'package:youbike/ui/widgets/base/confirm_dialog.dart';
import 'package:youbike/ui/widgets/github_update_alert_dialog.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with WidgetsBindingObserver {
  String _version = '...';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initVersion();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _initVersion() async {
    // AppConfigService.init() 已 cache 好 appVersion；直接讀並剝掉 buildNumber。
    final config = Provider.of<AppConfigService>(context, listen: false);
    final version = config.appVersion.split('+').first;
    if (mounted) setState(() => _version = version.isEmpty ? '0.0.0' : version);
  }

  @override
  Widget build(BuildContext context) {
    final config = Provider.of<AppConfigService>(context);
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final channel = AppEnvironment.updateChannel.toLowerCase();
    final showUpdateButton =
        channel == 'google_play' || channel == 'github' || channel == 'test';
    const showGooglePlayButton = true;

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
                  icon: Icons.science_outlined,
                  title: l10n.beta_features_page_title,
                  trailing: Icon(Icons.chevron_right,
                      size: 22, color: cs.onSurfaceVariant),
                  onTap: () => context.push('/beta-features'),
                ),
              ],
            ),

            // ── 權限 ──
            SettingGroupCard(
              title: l10n.permission_group_title,
              children: [
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
                    try {
                      await launchUrl(url, mode: LaunchMode.externalApplication);
                    } catch (e) {
                      debugPrint('Error launching GitHub URL: $e');
                    }
                  },
                ),
                if (showUpdateButton)
                  _buildItem(
                    icon: Icons.system_update_outlined,
                    title: l10n.check_for_updates,
                    onTap: () async {
                      await _checkForUpdates();
                    },
                  ),
                if (showGooglePlayButton)
                  _buildItem(
                    leading: const FaIcon(FontAwesomeIcons.googlePlay, size: 22),
                    title: l10n.open_google_play,
                    trailing: Icon(Icons.open_in_new,
                        size: 20, color: cs.onSurfaceVariant),
                    onTap: () async {
                      if (channel == 'google_play') {
                        await _openGooglePlayStore();
                      } else {
                        _showCbtGuideDialog();
                      }
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
    IconData? icon,
    Widget? leading,
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
      leading: leading ?? Icon(icon, color: iconColor ?? cs.onSurfaceVariant, size: 22),
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

  Future<void> _checkForUpdates() async {
    final service = UpdateCheckerService();
    final l10n = AppLocalizations.of(context);
    // 由 AppConfigService 提供已 cache 的版號（取代原本 PackageInfo.fromPlatform()）。
    final config = Provider.of<AppConfigService>(context, listen: false);
    final versionOnly =
        config.appVersion.split('+').first; // '1.0.1+2' → '1.0.1'

    try {
      Fluttertoast.showToast(msg: l10n.checking_for_updates);
      final result = await service.checkForUpdate(currentVersion: versionOnly);
      Fluttertoast.cancel();
      if (!mounted) return;
      await _handleUpdateResult(result, l10n);
    } catch (error) {
      if (!mounted) return;
      Fluttertoast.showToast(
        msg: '${l10n.update_check_failed}: ${error.toString()}',
      );
    }
  }

  Future<void> _handleUpdateResult(
    UpdateCheckResult result,
    AppLocalizations l10n,
  ) async {
    final localContext = context;
    final service = UpdateCheckerService();

    if (result.hasError) {
      final errorMessage = result.errorMessage?.replaceFirst(
            'Exception: ',
            '',
          ) ??
          l10n.update_check_failed;
      Fluttertoast.showToast(
        msg: '${l10n.update_check_failed}: $errorMessage',
      );
      return;
    }

    if (result.hasGooglePlayUpdate && result.playUpdateInfo != null) {
      await service.startGooglePlayUpdate(result.playUpdateInfo!);
      return;
    }

    if (result.isLatest) {
      Fluttertoast.showToast(msg: l10n.latest_version_installed);
      return;
    }

    // 這裡原本是顯示簡單的 AlertDialog，現在改用統一的 GithubUpdateAlertDialog
    final latestRelease = await service.getLatestGithubRelease();
    if (latestRelease != null) {
      await GithubUpdateAlertDialog.show(localContext, latestRelease);
    } else {
      // fallback: 如果無法獲取 release 詳細資訊，顯示基礎版本資訊
      await showDialog<void>(
        context: localContext,
        builder: (ctx) {
          return AlertDialog(
            title: Text(l10n.check_for_updates),
            content: Text(
              'New version available: ${result.latestVersion}\nCurrent version: ${result.currentVersion}',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  if (ctx.mounted) {
                    Navigator.of(ctx).pop();
                  }
                },
                child: Text(l10n.close),
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> _openGooglePlayStore() async {
    const packageName = 'com.potatosserver.youbike';
    final webUri = Uri.parse(
      'https://play.google.com/store/apps/details?id=$packageName',
    );

    // On web, directly open the Google Play web page in a new tab.
    // url_launcher_web only supports platformDefault mode and http/https schemes.
    if (kIsWeb) {
      await launchUrl(webUri, mode: LaunchMode.platformDefault);
      return;
    }

    // On Android, try market:// scheme first, fallback to web URL
    final marketUri = Uri.parse('market://details?id=$packageName');
    if (await canLaunchUrl(marketUri)) {
      await launchUrl(marketUri, mode: LaunchMode.externalApplication);
    } else {
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    }
  }

  void _showCbtGuideDialog() {
    final l10n = AppLocalizations.of(context);
    final cbtUrl = Uri.parse('https://youbike.pages.dev/CBT_Guide');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.cbt_guide_title),
        content: Text(l10n.cbt_guide_content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.close),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await launchUrl(cbtUrl,
                    mode: LaunchMode.externalApplication);
              } catch (e) {
                debugPrint('Error launching CBT Guide URL: $e');
              }
            },
            child: Text(l10n.cbt_guide_open),
          ),
        ],
      ),
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
                  icon: Icons.info_outline,
                  text: l10n.version_label(_version)),
              const SizedBox(height: 12),
              _buildAboutRow(
                  icon: Icons.network_check, text: 'Channel: ${AppEnvironment.displayChannel}'),
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
    ConfirmDialog.show(
      context,
      title: l10n.clear_data_confirm_title,
      content: l10n.clear_data_confirm_content,
      confirmLabel: l10n.confirm,
      cancelLabel: l10n.cancel,
      danger: true,
      onConfirm: () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
        if (mounted) router.go('/welcome');
      },
    );
  }
}