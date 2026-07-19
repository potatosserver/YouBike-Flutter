import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/foundation.dart';

import 'device_id_service.dart';
import '../../firebase_options.dart';

/// Firebase 服務整合：活躍回報 + FCM Token（Android 原生）
/// Web 使用 firebase_service_stub.dart，此檔案由條件 import 排除。
class FirebaseService {
  static FirebaseService? _instance;
  bool _initialized = false;

  FirebaseService._();

  static FirebaseService get instance {
    _instance ??= FirebaseService._();
    return _instance!;
  }

  bool get isInitialized => _initialized;

  /// 初始化 Firebase（需在 main() 中呼叫）
  Future<void> init() async {
    if (_initialized) return;

    try {
      // 檢查 [DEFAULT] App 是否已存在（避免 duplicate-app 錯誤）
      if (Firebase.apps.any((app) => app.name == '[DEFAULT]')) {
        debugPrint('[FirebaseService] [DEFAULT] App 已存在，略過 initializeApp');
      } else {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      _initialized = true;
      debugPrint('[FirebaseService] Firebase 初始化成功');

      // 啟動前景訊息監聽
      _initFcmListeners();
    } catch (e) {
      debugPrint('[FirebaseService] Firebase 初始化失敗: $e');
    }
  }

  /// 回報裝置活躍狀態到 Firestore（WalkGo 模式：內部自動初始化 Firebase）
  Future<void> reportAppActive() async {
    // WalkGo 模式：如果 Firebase 沒初始化，先初始化
    if (!_initialized) {
      try {
        // 只有 firebase apps 为空时才 initializeApp
        if (Firebase.apps.isEmpty) {
          await Firebase.initializeApp(
            options: DefaultFirebaseOptions.currentPlatform,
          );
          debugPrint('[FirebaseService] reportAppActive: 動態初始化 Firebase');
        } else {
          debugPrint('[FirebaseService] reportAppActive: Firebase 已由其他组件初始化，使用現有實例');
        }
        _initialized = true;
      } catch (e, s) {
        debugPrint('[FirebaseService] reportAppActive: 初始化 Firebase 失敗: $e\n$s');
      }
    }

    try {
      final deviceData = await DeviceIdHelper.getDeviceInfo();
      final deviceId = deviceData['id']!;
      final deviceModel = deviceData['model']!;
      final fcmToken = await _getFcmToken();

      final packageInfo = await PackageInfo.fromPlatform();
      final appVersion = '${packageInfo.version}+${packageInfo.buildNumber}';

      const String displayChannel = String.fromEnvironment('UPDATE_CHANNEL', defaultValue: 'github') == 'google_play' ? 'Google Play' : 'GitHub';

      await FirebaseFirestore.instance
          .collection('device_stats')
          .doc(deviceId)
          .set({
        'last_active': FieldValue.serverTimestamp(),
        'platform': 'Android ($displayChannel)',
        'device_model': deviceModel,
        'fcm_token': fcmToken ?? '',
        'app_version': appVersion,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('[FirebaseService] 回報裝置活躍失敗: $e');
    }
  }

  /// 刪除 Firestore 上的裝置紀錄
  Future<void> deleteDeviceStats() async {
    if (!_initialized) return;

    try {
      final deviceData = await DeviceIdHelper.getDeviceInfo();
      final deviceId = deviceData['id']!;

      await FirebaseFirestore.instance
          .collection('device_stats')
          .doc(deviceId)
          .delete();

      debugPrint('[FirebaseService] 裝置紀錄已刪除');
    } catch (e) {
      debugPrint('[FirebaseService] 刪除裝置紀錄失敗: $e');
    }
  }

  /// 取得 FCM Token
  Future<String?> _getFcmToken() async {
    try {
      final messaging = FirebaseMessaging.instance;
      return await messaging.getToken();
    } catch (e) {
      debugPrint('[FirebaseService] 取得 FCM Token 失敗: $e');
      return null;
    }
  }

  /// 初始化前景 FCM 訊息監聽
  void _initFcmListeners() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('[FCM] 前景收到訊息: ${message.notification?.title}');
      debugPrint('[FCM] 內容: ${message.notification?.body}');
      debugPrint('[FCM] 資料: ${message.data}');
    });
  }
}