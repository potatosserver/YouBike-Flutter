import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:youbike_android/services/app_state.dart';
import 'package:youbike_android/services/language_service.dart';
import 'package:youbike_android/services/theme_provider.dart';
import 'package:youbike_android/screens/home_screen.dart';
import 'package:youbike_android/screens/settings_screen.dart';
import 'package:youbike_android/screens/theme_selection_screen.dart';
import 'package:youbike_android/screens/region_selection_screen.dart';
import 'package:youbike_android/screens/language_selection_screen.dart';
import 'package:youbike_android/widgets/loading_overlay.dart';
import 'package:youbike_android/l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize instances but DO NOT await init() here.
  // We let MainWrapper handle init() to ensure LoadingOverlay is visible.
  final appState = AppState();
  final langService = LanguageService();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AppState>.value(value: appState),
        ChangeNotifierProvider<LanguageService>.value(value: langService),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Consumer<LanguageService>(
          builder: (context, langService, child) {
            return MaterialApp(
              title: 'YouBike Android',
              debugShowCheckedModeBanner: false,
              themeMode: themeProvider.themeMode,
              
              theme: ThemeData(
                useMaterial3: true,
                brightness: Brightness.light,
                scaffoldBackgroundColor: const Color(0xFFF4F4F4),
                colorScheme: const ColorScheme.light(
                  primary: Color(0xFF007BFF),
                  onPrimary: Colors.white,
                  surface: Colors.white,
                  onSurface: Color(0xFF333333),
                ),
                appBarTheme: const AppBarTheme(
                  backgroundColor: Color(0xFF007BFF),
                  foregroundColor: Colors.white,
                  elevation: 0,
                ),
              ),
              
              darkTheme: ThemeData(
                useMaterial3: true,
                brightness: Brightness.dark,
                scaffoldBackgroundColor: const Color(0xFF333333),
                colorScheme: const ColorScheme.dark(
                  primary: Color(0xFF90CAF9),
                  onPrimary: Color(0xFF121212),
                  surface: Color(0xFF222222),
                  onSurface: Colors.white,
                ),
                appBarTheme: const AppBarTheme(
                  backgroundColor: Color(0xFF222222),
                  foregroundColor: Color(0xFF90CAF9),
                  elevation: 0,
                ),
              ),
              
              locale: langService.appLocale,
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
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
      ],
    );
  }
}
