import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:youbike/data/services/language_service.dart';
import 'package:youbike/core/theme/theme_provider.dart';
import 'package:youbike/data/services/app_config_service.dart';
import 'package:youbike/core/utils/log_service.dart';
import 'package:youbike/providers/map_view_model.dart';
import 'package:youbike/providers/station_view_model.dart';
import 'package:youbike/providers/loading_view_model.dart';
import 'package:youbike/ui/app.dart';
import 'package:youbike/data/services/firebase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final log = LogService();
  log.i('APP_START', 'Initializing YouBike-Android startup sequence...');

  // 1. 預先初始化全局配置
  final configService = AppConfigService();
  await configService.init();

  final languageService = LanguageService();
  await languageService.loadLocale();

  // 2. 初始化 Firebase + 獲取 FCM Token（必須在註冊監聽前）
  try {
    log.i('APP_START', 'Initializing Firebase...');
    await FirebaseService.instance.init();
    log.i('APP_START', 'Firebase 初始化完成');

    // 🔑 獲取 FCM Token — 沒有 Token 就無法收到推播
    final token = await FcmTokenService.instance.getToken();
    if (token != null) {
      log.i('APP_START', 'FCM Token 獲取成功: ${token.substring(0, 12)}...');
    } else {
      log.w('APP_START', '⚠️ FCM Token 獲取失敗，無法接收推播');
    }
  } catch (e) {
    log.w('APP_START', 'Firebase 初始化失敗（可能是 Web 或配置錯誤）: $e');
  }

  // 3. 註冊 FCM 訊息監聽（前景 / 背景點擊 / 冷啟動）
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
        ChangeNotifierProxyProvider2<AppConfigService, MapViewModel,
            StationViewModel>(
          create: (_) => StationViewModel(configService, null),
          update: (_, config, mapVm, stationVm) {
            stationVm!.updateDependencies(config, mapVm);
            return stationVm;
          },
        ),
        ChangeNotifierProvider.value(value: languageService),
      ],
      child: const MyApp(),
    ),
  );
}