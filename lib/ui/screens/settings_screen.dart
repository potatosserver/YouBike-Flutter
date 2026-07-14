import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:youbike_android/core/l10n/app_localizations.dart';
import 'package:youbike_android/data/services/app_config_service.dart';
import 'package:youbike_android/ui/widgets/setting_group_card.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final config = Provider.of<AppConfigService>(context);
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.brightness == Brightness.dark ? const Color(0xFF121212) : Colors.white,
      appBar: AppBar(
        title: Text(l10n.settings_title),
        backgroundColor: theme.brightness == Brightness.dark ? const Color(0xFF1E1E1E) : Colors.white,
        foregroundColor: theme.brightness == Brightness.dark ? Colors.white : Colors.black,
        elevation: 0,
        centerTitle: false,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
          children: [
            SettingGroupCard(
              title: l10n.param_settings,
              children: [
                _buildWalkGoItem(
                  context,
                  icon: Icons.palette_outlined,
                  title: l10n.settings_theme,
                  trailing: const Icon(Icons.chevron_right, size: 22, color: Colors.grey),
                  onTap: () => context.push('/theme-selection'),
                ),
                _buildWalkGoItem(
                  context,
                  icon: Icons.map_outlined,
                  title: l10n.settings_region,
                  trailing: const Icon(Icons.chevron_right, size: 22, color: Colors.grey),
                  onTap: () => context.push('/region-selection'),
                ),
                _buildWalkGoItem(
                  context,
                  icon: Icons.language_outlined,
                  title: l10n.settings_language,
                  trailing: const Icon(Icons.chevron_right, size: 22, color: Colors.grey),
                  onTap: () => context.push('/language-selection'),
                ),
                _buildWalkGoItem(
                  context,
                  icon: Icons.location_on_outlined,
                  title: l10n.settings_location,
                  trailing: Switch(
                    value: config.useLocation,
                    onChanged: (val) => config.setUseLocation(val),
                    activeTrackColor: theme.brightness == Brightness.dark ? const Color(0xFF90CAF9) : const Color(0xFF4A90E2),
                    activeThumbColor: Colors.white,
                  ),
                  onTap: null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWalkGoItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(
        icon, 
        color: theme.brightness == Brightness.dark ? Colors.white70 : Colors.black54,
        size: 22,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: theme.brightness == Brightness.dark ? Colors.white : Colors.black87,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      trailing: trailing,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}
