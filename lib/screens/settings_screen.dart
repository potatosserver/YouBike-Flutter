import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../services/app_state.dart';
import '../services/language_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final langService = Provider.of<LanguageService>(context);
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionTitle(l10n.darkMode), // Temporary title for group
          SwitchListTile(
            title: Text(l10n.darkMode),
            subtitle: Text(appState.isDarkMode ? "Dark" : "Light"),
            value: appState.isDarkMode,
            onChanged: (val) => appState.toggleDarkMode(),
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 24),
          _buildSectionTitle(l10n.language),
          ListTile(
            title: Text(l10n.language),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(langService.appLocale.languageCode.toUpperCase()),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
            onTap: () => _showLanguageSelector(context, langService),
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  void _showLanguageSelector(BuildContext context, LanguageService langService) {
    const List<Locale> supported = AppLocalizations.supportedLocales;
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text("Select Language", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              ...supported.map((locale) {
                final isSelected = langService.appLocale == locale;
                return ListTile(
                  title: Text(locale.languageCode == 'zh' ? "繁體中文" : "English"),
                  trailing: isSelected ? const Icon(Icons.check, color: Colors.blue) : null,
                  onTap: () {
                    langService.setLocale(locale);
                    Navigator.pop(context);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
