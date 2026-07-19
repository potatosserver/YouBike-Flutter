import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../../firebase_options.dart';

/// Firebase Core 初始化服務
///
/// 單一職責：管理 Firebase App 的初始化與生命週期。
/// 提供冪等的 [ensureInitialized]，確保 Firebase 在任何呼叫順序下只初始化一次。
///
/// Web 使用 firebase_core_stub.dart，由條件 import 排除此檔案。
class FirebaseCoreService {
  static FirebaseCoreService? _instance;
  bool _initialized = false;

  FirebaseCoreService._();

  static FirebaseCoreService get instance {
    _instance ??= FirebaseCoreService._();
    return _instance!;
  }

  bool get isInitialized => _initialized;

  /// 冪等的 Firebase 初始化
  ///
  /// - 如果已透過此 service 初始化過，直接返回
  /// - 如果 [DEFAULT] app 已存在（其他 component 初始化過），標記為已初始化
  /// - 否則執行 initializeApp
  ///
  /// 這是專案中 Firebase 初始化的唯一真實路徑。
  /// 可以在 main() 中提早呼叫，也可讓後續服務懶載，保證冪等。
  Future<void> ensureInitialized() async {
    if (_initialized) return;

    try {
      // 檢查 [DEFAULT] App 是否已存在（避免 duplicate-app 錯誤）
      if (Firebase.apps.any((app) => app.name == '[DEFAULT]')) {
        debugPrint('[FirebaseCore] [DEFAULT] App 已存在，略過 initializeApp');
        _initialized = true;
        return;
      }

      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _initialized = true;
      debugPrint('[FirebaseCore] Firebase 初始化成功');
    } catch (e, s) {
      debugPrint('[FirebaseCore] Firebase 初始化失敗: $e\n$s');
      // 不吞掉例外 — 呼叫端可以自行決定是否要 fallback
      rethrow;
    }
  }
}