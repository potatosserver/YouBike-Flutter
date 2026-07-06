import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:youbike_android/services/app_state.dart';
import 'package:youbike_android/services/language_service.dart';
import 'package:youbike_android/widgets/app_theme.dart';
import 'package:youbike_android/screens/home_screen.dart';
import 'package:youbike_android/screens/settings_screen.dart';
import 'package:youbike_android/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()..init()),
        ChangeNotifierProvider(create: (_) => LanguageService()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const YouBikeApp(),
    ),
  );
}

class YouBikeApp extends StatelessWidget {
  const YouBikeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Consumer<LanguageService>(
          builder: (context, languageService, child) {
            return MaterialApp(
              title: 'YouBike',
              theme: ThemeData(
                useMaterial3: true,
                colorSchemeSeed: Colors.blue,
                brightness: Brightness.light,
              ),
              darkTheme: ThemeData(
                useMaterial3: true,
                colorSchemeSeed: Colors.blue,
                brightness: Brightness.dark,
              ),
              themeMode: themeProvider.themeMode,
              locale: languageService.appLocale,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: AppLocalizations.supportedLocales,
              home: const HomeScreen(),
              routes: {
                '/settings': (context) => const SettingsScreen(),
              },
            );
          },
        );
      },
    );
  }
}
