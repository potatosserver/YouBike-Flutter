import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../services/language_service.dart';

class SettingsPanel extends StatelessWidget {
  const SettingsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.8,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                LanguageService.getText('settings_title', appState.currentLang),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const Divider(height: 30),
              _buildSettingItem(
                context,
                icon: Icons.location_on,
                label: LanguageService.getText('region_select', appState.currentLang),
                child: DropdownButton<String>(
                  value: appState.currentRegion,
                  isExpanded: true,
                  items: AppState.regionCoordinates.keys.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value), // Simplified: In real app, map key to display name
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    if (newValue != null) appState.setRegion(newValue);
                  },
                ),
              ),
              _buildSettingItem(
                context,
                icon: Icons.my_location,
                label: LanguageService.getText('location_service', appState.currentLang),
                child: Switch(
                  value: appState.isFollowingUser,
                  onChanged: (value) => appState.setFollowingUser(value),
                ),
              ),
              _buildSettingItem(
                context,
                icon: Icons.dark_mode,
                label: LanguageService.getText('dark_mode', appState.currentLang),
                child: Switch(
                  value: appState.isDarkMode,
                  onChanged: (value) => appState.toggleDarkMode(value),
                ),
              ),
              _buildSettingItem(
                context,
                icon: Icons.language,
                label: LanguageService.getText('lang_toggle', appState.currentLang),
                child: Switch(
                  value: appState.currentLang == 'en',
                  onChanged: (value) => appState.setLanguage(value ? 'en' : 'zh'),
                ),
              ),
              const Spacer(),
              Center(
                child: Text(
                  "YouBike Android v1.0",
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingItem(BuildContext context, {required IconData icon, required String label, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey),
          const SizedBox(width: 15),
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 16)),
          ),
          child,
        ],
      ),
    );
  }
}
