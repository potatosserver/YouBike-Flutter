import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:youbike_android/core/theme/theme_provider.dart';
import 'package:youbike_android/data/services/app_config_service.dart';
import 'package:youbike_android/core/l10n/app_localizations.dart';
import 'package:youbike_android/core/router/app_router.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  /// 標準化語言代碼對應
  static const Map<String, Locale> _localeMap = {
    'en': Locale('en'),
    'zh': Locale('zh'),
  };

  /// 支持的語言列表
  static const List<Locale> supportedLocales = [
    Locale('zh'),
    Locale('en'),
  ];

  /// 獲取對應的 Locale
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
              seedColor: Colors.deepPurple,
              brightness: Brightness.light,
              surface: Colors.white,
              onSurface: Colors.black87,
            ),
            dialogTheme: dialogTheme,
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.deepPurple,
              brightness: Brightness.dark,
              surface: const Color(0xFF121212),
              onSurface: Colors.white,
            ),
            dialogTheme: dialogTheme,
          ),

          // 本地化配置
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
