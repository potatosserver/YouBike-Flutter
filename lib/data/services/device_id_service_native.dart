import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:android_id/android_id.dart';
import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';

/// 裝置唯一識別碼產生器（Android 原生）
class DeviceIdHelper {
  static const _androidIdPlugin = AndroidId();

  /// 取得裝置的安全 ID 與型號資訊
  static Future<Map<String, String>> getDeviceInfo() async {
    String secureId = "fallback_${DateTime.now().millisecondsSinceEpoch}";
    String model = "Unknown Device";

    try {
      final deviceInfo = DeviceInfoPlugin();
      // ⭕ 修正 1：正確 await 取得 AndroidDeviceInfo 物件
      final androidInfo = await deviceInfo.androidInfo;

      // 裝置型號（品牌 + 型號）
      model = "${androidInfo.brand} ${androidInfo.model}";

      // ⭕ 修正 2：改用 android_id 套件拿真正的 Settings.Secure.ANDROID_ID
      if (Platform.isAndroid) {
        final String? rawAndroidId = await _androidIdPlugin.getId();
        if (rawAndroidId != null && rawAndroidId.isNotEmpty) {
          secureId = _toSha256(rawAndroidId);
        }
      }
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