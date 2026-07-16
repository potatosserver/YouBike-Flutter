import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:youbike/core/theme/theme_provider.dart';
import 'package:youbike/core/theme/brand_colors.dart';
import 'package:youbike/data/services/app_config_service.dart';
import 'package:youbike/core/l10n/app_localizations.dart';
import 'package:youbike/core/router/app_router.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static const Map<String, Locale> _localeMap = {
    'en': Locale('en'),
    'zh': Locale('zh'),
  };

  static const List<Locale> supportedLocales = [
    Locale('zh'),
    Locale('en'),
  ];

  Locale _getLocale(String lang) => _localeMap[lang] ?? const Locale('zh');

  @override
  Widget build(BuildContext context) {
    final dialogTheme = DialogThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      titleTextStyle:
          const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
    );

    return Consumer2<ThemeProvider, AppConfigService>(
      builder: (context, themeProvider, config, child) {
        return MaterialApp.router(
          title: 'YouBike',
          themeMode: themeProvider.themeMode,
          locale: _getLocale(config.currentLang),
          routerConfig: AppRouter.router,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: BrandColors.orange,
              brightness: Brightness.light,
            ),
            dialogTheme: dialogTheme,
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: BrandColors.orange,
              brightness: Brightness.dark,
            ),
            dialogTheme: dialogTheme,
          ),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: supportedLocales,
        );
      },
    );
  }
}
