import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:youbike_android/services/app_state.dart';
import 'package:youbike_android/services/language_service.dart';
import 'package:youbike_android/screens/home_screen.dart';
import 'package:youbike_android/screens/settings_screen.dart';
import 'package:youbike_android/screens/theme_selection_screen.dart';
import 'package:youbike_android/screens/region_selection_screen.dart';
import 'package:youbike_android/screens/language_selection_screen.dart';
import 'package:youbike_android/services/theme_provider.dart';
import 'package:youbike_android/widgets/loading_overlay.dart';
import 'package:youbike_android/l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final appState = AppState();
  final langService = LanguageService();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => appState),
        ChangeNotifierProvider(create: (_) => langService),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Helper to convert appState lang string to Flutter Locale
  Locale _getLocale(String lang) {
    if (lang == 'en') return const Locale('en', 'US');
    return const Locale('zh', 'TW');
  }

  @override
  Widget build(BuildContext context) {
    // Listen to both ThemeProvider and AppState for language/theme changes
    return Consumer2<ThemeProvider, AppState>(
      builder: (context, themeProvider, appState, child) {
        return MaterialApp(
          title: 'YouBike',
          themeMode: themeProvider.themeMode,
          locale: _getLocale(appState.currentLang), // CRITICAL: Link lang state to MaterialApp
          theme: ThemeData(
            brightness: Brightness.light,
            primaryColor: const Color(0xFF007BFF),
            scaffoldBackgroundColor: const Color(0xFFF5F5F5),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            primaryColor: const Color(0xFF90CAF9),
            scaffoldBackgroundColor: const Color(0xFF121212),
            useMaterial3: true,
          ),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('zh', 'TW'),
            Locale('en', 'US'),
          ],
          home: const MainWrapper(),
          routes: {
            '/settings': (context) => const SettingsScreen(),
            '/theme-selection': (context) => const ThemeSelectionScreen(),
            '/region-selection': (context) => const RegionSelectionScreen(),
            '/language-selection': (context) => const LanguageSelectionScreen(),
          },
        );
      },
    );
  }
}

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AppState>(context, listen: false).init();
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    return Stack(
      children: [
        const HomeScreen(),
        if (appState.isLoading) const LoadingOverlay(),
        // Font Warmer: Forces Material Icons to load before baking occurs
        Opacity(
          opacity: 0.0,
          child: Column(
            children: [
              Text(String.fromCharCode(Icons.directions_bike.codePoint), 
                   style: const TextStyle(fontFamily: 'MaterialIcons')),
              Text(String.fromCharCode(Icons.star.codePoint), 
                   style: const TextStyle(fontFamily: 'MaterialIcons')),
            ],
          ),
        ),
        ],
    );
  }
}
