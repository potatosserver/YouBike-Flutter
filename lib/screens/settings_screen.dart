import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../services/app_config_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final config = Provider.of<AppConfigService>(context);
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.brightness == Brightness.dark ? const Color(0xFF121212) : const Color(0xFFF8F9FA),
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
            _buildSettingsGroup(
              context,
              title: l10n.param_settings,
              children: [
                _buildWalkGoItem(
                  context,
                  icon: Icons.palette_outlined,
                  title: l10n.settings_theme,
                  trailing: const Icon(Icons.chevron_right, size: 22, color: Colors.grey),
                  onTap: () => Navigator.pushNamed(context, '/theme-selection'),
                ),
                _buildWalkGoItem(
                  context,
                  icon: Icons.map_outlined,
                  title: l10n.settings_region,
                  trailing: const Icon(Icons.chevron_right, size: 22, color: Colors.grey),
                  onTap: () => Navigator.pushNamed(context, '/region-selection'),
                ),
                _buildWalkGoItem(
                  context,
                  icon: Icons.language_outlined,
                  title: l10n.settings_language,
                  trailing: const Icon(Icons.chevron_right, size: 22, color: Colors.grey),
                  onTap: () => Navigator.pushNamed(context, '/language-selection'),
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

  Widget _buildSettingsGroup(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
          child: Text(
            title,
            style: TextStyle(
              color: theme.brightness == Brightness.dark ? Colors.grey[400] : Colors.grey[600],
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: theme.brightness == Brightness.dark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            // Removed 'shape' to fix the Material assertion crash
            child: Column(
              children: children,
            ),
          ),
        ),
      ],
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
