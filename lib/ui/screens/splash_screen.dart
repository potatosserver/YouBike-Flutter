import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const _firstLaunchKey = 'is_first_launch';
  static const _skipLocKey = 'skip_location_permission';
  static const _skipNotifKey = 'skip_notification_permission';

  @override
  void initState() {
    super.initState();
    _decideRoute();
  }

  Future<void> _decideRoute() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirst = prefs.getBool(_firstLaunchKey) ?? true;

    if (isFirst) {
      await prefs.setBool(_firstLaunchKey, false);
      if (mounted) context.go('/welcome');
      return;
    }

    // 非首次：依序檢查定位、通知權限是否已處理（授權 或 略過）
    final skipLoc = prefs.getBool(_skipLocKey) ?? false;
    final skipNotif = prefs.getBool(_skipNotifKey) ?? false;

    final locGranted = await _isLocationGranted();
    if (!mounted) return;
    if (!locGranted && !skipLoc) {
      context.go('/permission');
      return;
    }

    final notifGranted =
        skipNotif || kIsWeb || await _isNotificationGranted();
    if (!mounted) return;
    if (!notifGranted && !skipNotif) {
      context.go('/permission/notification');
      return;
    }

    context.go('/');
  }

  Future<bool> _isLocationGranted() async {
    // 統一在 Web 走 Geolocator（與 MapViewModel 同源）。
    // 原因：permission_handler_html 的 Permission.location.status 走
    // navigator.permissions.query({name:'geolocation'})，在「使用者重設權限」
    // 場景會與 navigator.geolocation 狀態分歧，導致 splash 誤判已授予、
    // 跳過權限頁直奔首頁，最後由 MapViewModel 的 Geolocator.requestPermission()
    // 才在首頁載入時彈出瀏覽器原生詢問框。
    if (kIsWeb) {
      try {
        final p = await Geolocator.checkPermission();
        return p == LocationPermission.always ||
            p == LocationPermission.whileInUse;
      } catch (_) {
        return false;
      }
    }
    final s = await Permission.location.status;
    return s.isGranted || s.isLimited;
  }

  Future<bool> _isNotificationGranted() async {
    // Android 13+ 用 permission_handler；iOS/舊 Android 走 FCM
    final s = await Permission.notification.status;
    if (s.isGranted) return true;
    try {
      final fcmStatus =
          await FirebaseMessaging.instance.getNotificationSettings();
      return fcmStatus.authorizationStatus == AuthorizationStatus.authorized ||
          fcmStatus.authorizationStatus == AuthorizationStatus.provisional;
    } catch (e) {
      // Web 或尚未初始化 Firebase 時 fallback：假設未授予
      if (kDebugMode) debugPrint('[Splash] 通知權限檢查失敗: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
