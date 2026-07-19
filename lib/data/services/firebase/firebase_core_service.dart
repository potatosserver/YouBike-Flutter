import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Firebase Core 初始化服務
///
/// 單一職責：管理 Firebase App 的初始化與生命週期。
/// 提供冪等的 [ensureInitialized]。
///
/// Android / iOS 自動從 google-services.json / GoogleService-Info.plist 讀取配置，
/// 無需 firebase_options.dart（避免 API key 洩漏）。
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
  /// 在 Android 上，Firebase 會從 android/app/google-services.json 自動讀取
  /// project_id / api_key 等配置，無需傳 options。只有非原生平台才需要。
  Future<void> ensureInitialized() async {
    if (_initialized) return;

    try {
      if (Firebase.apps.any((app) => app.name == '[DEFAULT]')) {
        debugPrint('[FirebaseCore] [DEFAULT] App 已存在，略過 initializeApp');
        _initialized = true;
        return;
      }

      // 不加 options — Android 從 google-services.json 自動讀取
      await Firebase.initializeApp();
      _initialized = true;
      debugPrint('[FirebaseCore] Firebase 初始化成功（自動讀取 google-services.json）');
    } catch (e, s) {
      debugPrint('[FirebaseCore] Firebase 初始化失敗: $e\n$s');
      rethrow;
    }
  }
}