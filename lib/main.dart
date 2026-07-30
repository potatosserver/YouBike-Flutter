import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:youbike/data/services/language_service.dart';
import 'package:youbike/core/theme/theme_provider.dart';
import 'package:youbike/data/services/app_config_service.dart';
import 'package:youbike/core/utils/log_service.dart';
import 'package:youbike/providers/map_view_model.dart';

import 'package:youbike/providers/loading_view_model.dart';
import 'package:youbike/providers/bike_station_view_model.dart';
import 'package:youbike/ui/app.dart';
import 'package:youbike/data/services/firebase_service.dart';
import 'package:youbike/data/services/bike_station_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final log = LogService();
  log.i('APP_START', 'Initializing YouBike-Android startup sequence...');

  // 1. 預先初始化全局配置
  final configService = AppConfigService();
  await configService.init();

  final languageService = LanguageService();
  await languageService.loadLocale();

  // 2. 初始化 Firebase + App Check + FCM
  try {
    log.i('APP_START', 'Initializing Firebase...');
    await FirebaseCoreService.instance.ensureInitialized();
    log.i('APP_START', 'Firebase 初始化完成');

    // 🛡️ 啟用 App Check 防護盾
    log.i('APP_START', 'Activating App Check...');
    
    await FirebaseAppCheck.instance.activate(
      // 根據新版規範，傳入對應的 Provider 類別實例
      providerAndroid: kDebugMode 
          ? const AndroidDebugProvider() 
          : const AndroidPlayIntegrityProvider(),
      providerApple: const AppleAppAttestProvider(),
    );
    log.i('APP_START', 'App Check 已啟用，當前模式: ${kDebugMode ? "Debug" : "Play Integrity"}');

    // 🔑 獲取 FCM Token
    final token = await FcmTokenService.instance.getToken();
    if (token != null) {
      log.i('APP_START', 'FCM Token: ${token.substring(0, 12)}...');
    } else {
      log.w('APP_START', '⚠️ FCM Token 獲取失敗');
    }
  } catch (e) {
    log.w('APP_START', 'Firebase/AppCheck 初始化失敗: $e');
  }

  // 3. 註冊 FCM 訊息監聽
  await FcmMessageHandler.instance.registerListeners();

  log.i('APP_START',
      'Configuration, Locale, and Firebase ready. currentLang: ${configService.currentLang}');

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider.value(value: configService),
        ChangeNotifierProvider(create: (_) => LoadingViewModel()),
        ChangeNotifierProxyProvider<AppConfigService, MapViewModel>(
          create: (_) => MapViewModel(configService),
          update: (_, config, mapVm) => mapVm!..updateConfig(config),
        ),
        
        ChangeNotifierProvider.value(value: languageService),
        // BikeStation VM — unified source for the search panel.
        ChangeNotifierProvider<BikeStationViewModel>(
          create: (ctx) => BikeStationViewModel(
            config: configService,
            repository: BikeStationRepository(),
            mapVm: ctx.read<MapViewModel>(),
          ),
        ),
      ],
      child: const MyApp(),
    ),
  );
}