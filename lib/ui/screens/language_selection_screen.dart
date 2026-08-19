import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:youbike/core/l10n/app_localizations.dart';
import 'package:youbike/data/services/app_config_service.dart';
import 'package:youbike/data/services/language_service.dart';
import 'package:youbike/ui/widgets/radio_dot.dart';

class LanguageSelectionScreen extends StatelessWidget {
  const LanguageSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final config = Provider.of<AppConfigService>(context);
    final languageService = Provider.of<LanguageService>(context);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: Text(l10n.settings_language_title),
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        children: [
          RadioDot(
            label: l10n.language_system_default,
            isSelected: languageService.selectedLocale == null,
            onTap: () => languageService.clearLocale(),
          ),
          const SizedBox(height: 24),
          RadioDot(
            label: l10n.lang_zh,
            isSelected: languageService.selectedLocale?.languageCode == 'zh',
            onTap: () => languageService.setLanguageCode('zh', config),
          ),
          const SizedBox(height: 24),
          RadioDot(
            label: l10n.lang_en,
            isSelected: languageService.selectedLocale?.languageCode == 'en',
            onTap: () => languageService.setLanguageCode('en', config),
          ),
        ],
      ),
    );
  }
}
