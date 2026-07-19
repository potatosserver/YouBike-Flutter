// firebase_service_stub.dart — Web stub
// Web 平台不安裝 Firebase，所有方法都是 no-op。

/// Web stub — Firebase 服務整合
class FirebaseService {
  static FirebaseService? _instance;
  final bool _initialized = false;

  FirebaseService._();

  static FirebaseService get instance {
    _instance ??= FirebaseService._();
    return _instance!;
  }

  bool get isInitialized => _initialized;

  Future<void> init() async {}
  Future<void> reportAppActive() async {}
  Future<void> deleteDeviceStats() async {}
}