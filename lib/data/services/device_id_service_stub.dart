// device_id_service_stub.dart — Web stub
// Web 無裝置資訊可用，直接回 fallback。

/// Web stub — 裝置唯一識別碼
class DeviceIdHelper {
  static Future<Map<String, String>> getDeviceInfo() async {
    return {
      'id': 'web_${DateTime.now().millisecondsSinceEpoch}',
      'model': 'Web Browser',
    };
  }

  static Future<String> getSecureDeviceId() async {
    final info = await getDeviceInfo();
    return info['id']!;
  }
}