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
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'YouBike',
      themeMode: ThemeMode.system,
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
