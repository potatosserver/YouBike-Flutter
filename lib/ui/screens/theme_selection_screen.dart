import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:youbike/core/l10n/app_localizations.dart';
import 'package:youbike/core/theme/theme_provider.dart';
import 'package:youbike/ui/widgets/radio_dot.dart';

class ThemeSelectionScreen extends StatelessWidget {
  const ThemeSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final currentMode = Provider.of<ThemeProvider>(context).themeMode;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: Text(l10n.settings_theme),
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        children: [
          RadioDot(
            label: '系統預設',
            isSelected: currentMode == ThemeMode.system,
            onTap: () => Provider.of<ThemeProvider>(context, listen: false)
                .setThemeMode(ThemeMode.system),
          ),
          const SizedBox(height: 24),
          RadioDot(
            label: '淺色模式',
            isSelected: currentMode == ThemeMode.light,
            onTap: () => Provider.of<ThemeProvider>(context, listen: false)
                .setThemeMode(ThemeMode.light),
          ),
          const SizedBox(height: 24),
          RadioDot(
            label: '深色模式',
            isSelected: currentMode == ThemeMode.dark,
            onTap: () => Provider.of<ThemeProvider>(context, listen: false)
                .setThemeMode(ThemeMode.dark),
          ),
        ],
      ),
    );
  }
}
