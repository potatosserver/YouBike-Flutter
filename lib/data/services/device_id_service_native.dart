import 'dart:convert';
import 'dart:developer' as developer;
import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';

/// 裝置唯一識別碼產生器（Android 原生）
/// Web 使用 device_id_service_stub.dart，此檔案由條件 import 排除。
class DeviceIdHelper {
  /// 取得裝置的安全 ID 與型號資訊
  static Future<Map<String, String>> getDeviceInfo() async {
    String secureId = "fallback_${DateTime.now().millisecondsSinceEpoch}";
    String model = "Unknown Device";

    try {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;

      // Android ID → SHA256 作為裝置唯一碼
      final rawId = androidInfo.id;
      if (rawId.isNotEmpty) {
        secureId = _toSha256(rawId);
      }

      // 裝置型號（品牌 + 型號）
      model = "${androidInfo.brand} ${androidInfo.model}";
    } catch (e) {
      developer.log('取得裝置資訊失敗: $e', name: 'DeviceIdHelper');
    }

    return {
      'id': secureId,
      'model': model,
    };
  }

  /// 單純取得裝置 ID（保持向下相容）
  static Future<String> getSecureDeviceId() async {
    final info = await getDeviceInfo();
    return info['id']!;
  }

  static String _toSha256(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}