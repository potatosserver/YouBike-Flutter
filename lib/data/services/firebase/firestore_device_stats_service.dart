import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/foundation.dart';

import '../device_id_service.dart';
import 'firebase_core_service.dart';
import 'fcm_service.dart';

/// Firestore device_stats 文件操作
///
/// 單一職責：管理 Firestore 上 `device_stats/{deviceId}` 文件的
/// 寫入（reportAppActive）與刪除（deleteDeviceStats）。
///
/// 依賴 [FirebaseCoreService] 確保 Firebase 已初始化，
/// 依賴 [FcmTokenService] 取得 FCM Token。
///
/// Web 使用 firestore_device_stats_stub.dart，由條件 import 排除此檔案。
class FirestoreDeviceStatsService {
  static FirestoreDeviceStatsService? _instance;

  FirestoreDeviceStatsService._();

  static FirestoreDeviceStatsService get instance {
    _instance ??= FirestoreDeviceStatsService._();
    return _instance!;
  }

  /// 回報裝置活躍狀態到 Firestore
  ///
  /// 自動初始化 Firebase（冪等）、取得 FCM Token、寫入 Firestore。
  /// 失敗不拋出例外，僅 log 錯誤。
  Future<void> reportAppActive() async {
    try {
      // 確保 Firebase 已初始化（冪等）
      await FirebaseCoreService.instance.ensureInitialized();
    } catch (e) {
      debugPrint('[FirestoreDeviceStats] Firebase 初始化失敗，略過回報: $e');
      return;
    }

    try {
      final deviceData = await DeviceIdHelper.getDeviceInfo();
      final deviceId = deviceData['id']!;
      final deviceModel = deviceData['model']!;
      final fcmToken = await FcmTokenService.instance.getToken();

      final packageInfo = await PackageInfo.fromPlatform();
      final appVersion =
          '${packageInfo.version}+${packageInfo.buildNumber}';

      const String displayChannel =
          String.fromEnvironment('UPDATE_CHANNEL', defaultValue: 'github') ==
                  'google_play'
              ? 'Google Play'
              : 'GitHub';

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

      debugPrint('[FirestoreDeviceStats] 裝置活躍回報完成');
    } catch (e) {
      debugPrint('[FirestoreDeviceStats] 回報裝置活躍失敗: $e');
    }
  }

  /// 刪除 Firestore 上的裝置紀錄
  Future<void> deleteDeviceStats() async {
    // 如果沒有初始化過，跳過（沒有資料可刪）
    if (!FirebaseCoreService.instance.isInitialized) return;

    try {
      final deviceData = await DeviceIdHelper.getDeviceInfo();
      final deviceId = deviceData['id']!;

      await FirebaseFirestore.instance
          .collection('device_stats')
          .doc(deviceId)
          .delete();

      debugPrint('[FirestoreDeviceStats] 裝置紀錄已刪除');
    } catch (e) {
      debugPrint('[FirestoreDeviceStats] 刪除裝置紀錄失敗: $e');
    }
  }
}