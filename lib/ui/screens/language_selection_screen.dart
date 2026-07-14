import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:youbike_android/core/l10n/app_localizations.dart';
import 'package:youbike_android/data/services/app_config_service.dart';
import 'package:youbike_android/data/services/language_service.dart';

class LanguageSelectionScreen extends StatelessWidget {
  const LanguageSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final config = Provider.of<AppConfigService>(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.brightness == Brightness.dark ? theme.colorScheme.surface : Colors.white,
      appBar: AppBar(
        title: Text(l10n.settings_language_title),
        backgroundColor: theme.brightness == Brightness.dark ? theme.colorScheme.surface : Colors.white,
        foregroundColor: theme.brightness == Brightness.dark ? theme.colorScheme.primary : Colors.black,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        children: AppLocalizations.supportedLocales.map((locale) {
          final isSelected = config.currentLang == (locale.languageCode == 'zh' ? 'zh_TW' : 'en');
          final label = locale.languageCode == 'zh' ? "繁體中文" : "English";

          return Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: InkWell(
              onTap: () {
                config.setLanguage(locale.languageCode == 'zh' ? 'zh_TW' : 'en');
                Provider.of<LanguageService>(context, listen: false).setLocale(locale);
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
                  Text(label, style: TextStyle(
                    fontSize: 18, 
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: theme.brightness == Brightness.dark ? Colors.white : Colors.black87,
                  )),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
