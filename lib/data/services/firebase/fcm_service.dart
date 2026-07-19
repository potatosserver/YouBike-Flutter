import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../device_id_service.dart';
import 'firebase_core_service.dart';

class FcmTokenService {
  static FcmTokenService? _instance;
  String? _cachedToken;

  FcmTokenService._();

  static FcmTokenService get instance {
    _instance ??= FcmTokenService._();
    return _instance!;
  }

  Future<String?> getToken() async {
    if (_cachedToken != null) return _cachedToken;

    try {
      await FirebaseCoreService.instance.ensureInitialized();
      await _requestPermission();

      final messaging = FirebaseMessaging.instance;
      messaging.onTokenRefresh.listen(_onTokenRefresh);

      _cachedToken = await messaging.getToken();
      debugPrint('[FcmToken] Token: ${_cachedToken?.substring(0, 8)}...');
      return _cachedToken;
    } catch (e) {
      debugPrint('[FcmToken] Token 失敗: $e');
      return null;
    }
  }

  Future<void> _requestPermission() async {
    final s = await FirebaseMessaging.instance.requestPermission(
      alert: true, badge: true, sound: true,
      criticalAlert: false, provisional: false,
    );
    debugPrint('[FcmToken] 權限: ${s.authorizationStatus}');
  }

  Future<void> _onTokenRefresh(String newToken) async {
    _cachedToken = newToken;
    debugPrint('[FcmToken] Token 刷新: ${newToken.substring(0, 8)}...');

    // 直接更新 Firestore 中的 fcm_token 欄位
    try {
      final deviceId = (await DeviceIdHelper.getDeviceInfo())['id']!;
      await FirebaseFirestore.instance
          .collection('device_stats')
          .doc(deviceId)
          .set({'fcm_token': newToken}, SetOptions(merge: true));
      debugPrint('[FcmToken] Firestore fcm_token 已更新 ✅');
    } catch (e) {
      debugPrint('[FcmToken] Firestore 更新失敗: $e');
    }
  }
}

// ── 訊息處理 + 前景通知 ──

class FcmMessageHandler {
  static FcmMessageHandler? _instance;
  bool _registered = false;
  final FlutterLocalNotificationsPlugin _local = FlutterLocalNotificationsPlugin();

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

    debugPrint('[FcmHandler] 監聽已註冊');
  }

  Future<void> _initLocal() async {
    await _local.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );

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
    debugPrint('[FCM] 前景: $title / $body');

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
    debugPrint('[FCM] 點擊通知: ${msg.data}');
  }

  Future<void> _checkInitial() async {
    final msg = await FirebaseMessaging.instance.getInitialMessage();
    if (msg != null) _onOpened(msg);
  }
}