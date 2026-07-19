// firebase_core_stub.dart — Web stub
// Web 平台不安裝 Firebase，所有方法都是 no-op。

/// Web stub — Firebase Core 初始化服務
class FirebaseCoreService {
  static FirebaseCoreService? _instance;
  final bool _initialized = false;

  FirebaseCoreService._();

  static FirebaseCoreService get instance {
    _instance ??= FirebaseCoreService._();
    return _instance!;
  }

  bool get isInitialized => _initialized;

  Future<void> ensureInitialized() async {}
}