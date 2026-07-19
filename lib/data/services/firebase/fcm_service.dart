import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'firebase_core_service.dart';

/// FCM Token 管理
class FcmTokenService {
  static FcmTokenService? _instance;
  String? _cachedToken;

  FcmTokenService._();

  static FcmTokenService get instance {
    _instance ??= FcmTokenService._();
    return _instance!;
  }

  /// 取得 FCM Token（含權限請求與刷新監聽）
  Future<String?> getToken() async {
    if (_cachedToken != null) return _cachedToken;

    try {
      await FirebaseCoreService.instance.ensureInitialized();

      // Android 13+ 通知權限
      await _requestNotificationPermission();

      final messaging = FirebaseMessaging.instance;

      // Token 刷新 → 自動更新 Firestore
      messaging.onTokenRefresh.listen(_onTokenRefresh);

      _cachedToken = await messaging.getToken();
      debugPrint('[FcmToken] 取得 Token: ${_cachedToken?.substring(0, 8)}...');
      return _cachedToken;
    } catch (e) {
      debugPrint('[FcmToken] 取得 Token 失敗: $e');
      return null;
    }
  }

  Future<void> _requestNotificationPermission() async {
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      criticalAlert: false,
      provisional: false,
    );
    debugPrint('[FcmToken] 通知權限: ${settings.authorizationStatus}');
  }

  /// Token 刷新時自動更新 Firestore device_stats 中的 fcm_token 欄位
  Future<void> _onTokenRefresh(String newToken) async {
    _cachedToken = newToken;
    debugPrint('[FcmToken] Token 刷新，更新 Firestore: ${newToken.substring(0, 8)}...');
    await FirestoreDeviceStatsService.instance.reportAppActive();
  }
}

/// FCM 訊息處理器 + 本地通知顯示
class FcmMessageHandler {
  static FcmMessageHandler? _instance;
  bool _registered = false;

  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  FcmMessageHandler._();

  static FcmMessageHandler get instance {
    _instance ??= FcmMessageHandler._();
    return _instance!;
  }

  Future<void> registerListeners() async {
    if (_registered) return;
    _registered = true;

    await _initLocal();

    FirebaseMessaging.onMessage.listen(_onForeground);
    FirebaseMessaging.onMessageOpenedApp.listen(_onOpened);
    _checkInitial();

    debugPrint('[FcmHandler] 所有 FCM 監聽已註冊');
  }

  Future<void> _initLocal() async {
    const init = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );

    await _local.initialize(settings: init, onDidReceiveNotificationResponse: (_) {});

    await _local
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel(
          'fcm_channel', 'FCM 推播',
          description: 'YouBike 推播通知',
          importance: Importance.high,
          playSound: true,
        ));
  }

  void _onForeground(RemoteMessage msg) async {
    final title = msg.notification?.title ?? 'YouBike';
    final body = msg.notification?.body ?? '您有一則新訊息';
    debugPrint('[FCM] 前景通知: $title / $body');

    await _local.show(
      id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'fcm_channel', 'FCM 推播',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
        ),
      ),
    );
    debugPrint('[FCM] 前景通知已顯示 ✅');
  }

  void _onOpened(RemoteMessage msg) {
    debugPrint('[FCM] 從通知開啟 app: ${msg.data}');
  }

  Future<void> _checkInitial() async {
    final msg = await FirebaseMessaging.instance.getInitialMessage();
    if (msg != null) _onOpened(msg);
  }
}