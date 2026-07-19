// fcm_service_stub.dart — Web stub
//
// Web 平台無 FCM，所有方法都是 no-op。

/// Web stub — FCM Token 管理
class FcmTokenService {
  static FcmTokenService? _instance;

  FcmTokenService._();

  static FcmTokenService get instance {
    _instance ??= FcmTokenService._();
    return _instance!;
  }

  Future<String?> getToken() async => null;
}

/// Web stub — FCM 訊息處理器
class FcmMessageHandler {
  static FcmMessageHandler? _instance;

  FcmMessageHandler._();

  static FcmMessageHandler get instance {
    _instance ??= FcmMessageHandler._();
    return _instance!;
  }

  Future<void> registerListeners() async {}
}