// firebase_service_compat.dart — 向後相容 wrapper（平台適配）
//
// 提供舊版 FirebaseService class，將方法轉發到細粒度模組。
// 平台適配策略：
//   - Web：import stub（無 Firebase 依賴）
//   - 原生：import 實作
//
// 此檔案會由 firebase_service.dart 祭出，對上層透明。

import 'firebase/firebase_core_stub.dart' if (dart.library.io) 'firebase/firebase_core_service.dart';
import 'firebase/firestore_device_stats_stub.dart' if (dart.library.io) 'firebase/firestore_device_stats_service.dart';

/// Firebase 服務整合（向後相容 wrapper）
///
/// 所有方法直接轉發到對應的細粒度模組。
/// 新程式碼建議直接使用：
///   - [FirebaseCoreService]
///   - [FirestoreDeviceStatsService]
///   - [FcmTokenService]
///   - [FcmMessageHandler]
class FirebaseService {
  static FirebaseService? _instance;

  FirebaseService._();

  static FirebaseService get instance {
    _instance ??= FirebaseService._();
    return _instance!;
  }

  bool get isInitialized => FirebaseCoreService.instance.isInitialized;

  /// 初始化 Firebase
  Future<void> init() => FirebaseCoreService.instance.ensureInitialized();

  /// 回報裝置活躍到 Firestore
  Future<void> reportAppActive() =>
      FirestoreDeviceStatsService.instance.reportAppActive();

  /// 刪除 Firestore 上的裝置紀錄
  Future<void> deleteDeviceStats() =>
      FirestoreDeviceStatsService.instance.deleteDeviceStats();
}