import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../services/app_state.dart';

class ThemeSelectionScreen extends StatelessWidget {
  const ThemeSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final appState = Provider.of<AppState>(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings_theme),
        backgroundColor: theme.brightness == Brightness.dark ? theme.colorScheme.surface : Colors.white,
        foregroundColor: theme.brightness == Brightness.dark ? theme.colorScheme.primary : Colors.black,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        children: [
          _buildOption(context, title: "系統預設", mode: ThemeMode.system, isSelected: appState.isDarkMode == false), // Simplified logic for demo
          const SizedBox(height: 24),
          _buildOption(context, title: "淺色模式", mode: ThemeMode.light, isSelected: appState.isDarkMode == false),
          const SizedBox(height: 24),
          _buildOption(context, title: "深色模式", mode: ThemeMode.dark, isSelected: appState.isDarkMode == true),
        ],
      ),
    );
  }

  Widget _buildOption(BuildContext context, {required String title, required ThemeMode mode, required bool isSelected}) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () {
        Provider.of<AppState>(context, listen: false).toggleDarkMode();
        Navigator.pop(context);
      },
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? theme.colorScheme.primary : Colors.grey,
                width: 2,
              ),
            ),
            child: Center(
              child: isSelected 
                ? Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ) 
                : null,
            ),
          ),
          const SizedBox(width: 16),
          Text(title, style: TextStyle(
            fontSize: 18, 
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: theme.brightness == Brightness.dark ? Colors.white : Colors.black87,
          )),
        ],
      ),
    );
  }
}
