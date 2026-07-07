import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../services/app_state.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
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
              title: "參數設定",
              children: [
                _buildWalkGoItem(
                  context,
                  icon: Icons.palette_outlined,
                  title: "主題模式",
                  trailing: const Icon(Icons.chevron_right, size: 22, color: Colors.grey),
                  onTap: () => Navigator.pushNamed(context, '/theme-selection'),
                ),
                _buildWalkGoItem(
                  context,
                  icon: Icons.map_outlined,
                  title: "預設區域",
                  trailing: const Icon(Icons.chevron_right, size: 22, color: Colors.grey),
                  onTap: () => Navigator.pushNamed(context, '/region-selection'),
                ),
                _buildWalkGoItem(
                  context,
                  icon: Icons.language_outlined,
                  title: "語言設定",
                  trailing: const Icon(Icons.chevron_right, size: 22, color: Colors.grey),
                  onTap: () => Navigator.pushNamed(context, '/language-selection'),
                ),
                _buildWalkGoItem(
                  context,
                  icon: Icons.location_on_outlined,
                  title: "啟用啟動自動定位",
                  trailing: Switch(
                    value: appState.useLocation,
                    onChanged: (val) => appState.setUseLocation(val),
                    activeThumbColor: theme.colorScheme.primary,
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
