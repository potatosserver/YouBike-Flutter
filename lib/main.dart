import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:youbike_android/services/language_service.dart';
import 'package:youbike_android/screens/home_screen.dart';
import 'package:youbike_android/screens/settings_screen.dart';
import 'package:youbike_android/screens/theme_selection_screen.dart';
import 'package:youbike_android/screens/region_selection_screen.dart';
import 'package:youbike_android/screens/language_selection_screen.dart';
import 'package:youbike_android/services/theme_provider.dart';
import 'package:youbike_android/services/app_config_service.dart';
import 'package:youbike_android/viewmodels/map_view_model.dart';
import 'package:youbike_android/viewmodels/station_view_model.dart';
import 'package:youbike_android/viewmodels/loading_view_model.dart';
import 'package:youbike_android/widgets/loading_overlay.dart';
import 'package:youbike_android/l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AppConfigService()..init()),
        ChangeNotifierProvider(create: (_) => LoadingViewModel()),
        ChangeNotifierProxyProvider<AppConfigService, MapViewModel>(
          create: (_) => MapViewModel(AppConfigService()),
          update: (_, config, mapVm) => mapVm!..updateConfig(config),
        ),
        ChangeNotifierProxyProvider2<AppConfigService, MapViewModel, StationViewModel>(
          create: (_) => StationViewModel(AppConfigService(), MapViewModel(AppConfigService())),
          update: (_, config, mapVm, stationVm) => stationVm!..updateDependencies(config, mapVm),
        ),
        ChangeNotifierProvider(create: (_) => LanguageService()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Locale _getLocale(String lang) {
    if (lang == 'en') return const Locale('en', 'US');
    return const Locale('zh', 'TW');
  }

  @override
  Widget build(BuildContext context) {
    final dialogTheme = DialogThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      titleTextStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
    );

    return Consumer2<ThemeProvider, AppConfigService>(
      builder: (context, themeProvider, config, child) {
        return MaterialApp(
          title: 'YouBike',
          themeMode: themeProvider.themeMode,
          locale: _getLocale(config.currentLang),
          theme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: Colors.deepPurple,
            brightness: Brightness.light,
            dialogTheme: dialogTheme,
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: Colors.deepPurple,
            brightness: Brightness.dark,
            dialogTheme: dialogTheme,
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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final loadingVm = Provider.of<LoadingViewModel>(context, listen: false);
      final stationVm = Provider.of<StationViewModel>(context, listen: false);
      final mapVm = Provider.of<MapViewModel>(context, listen: false);
      
      loadingVm.setLoading(true);
      loadingVm.simulatePercentage();
      
      // Simulate the optimized init sequence from old AppState
      try {
        await mapVm.requestAndCenterLocation();
        await stationVm.fetchBaseData();
        await stationVm.refreshStations(isInitial: true);
      } catch (e) {
        debugPrint("Init error: $e");
      } finally {
        loadingVm.setFinished();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final loadingVm = Provider.of<LoadingViewModel>(context);
    return Stack(
      children: [
        const HomeScreen(),
        if (loadingVm.isLoading) const LoadingOverlay(),
      ],
    );
  }
}
