// PermissionService — 權限檢查與請求的統一入口。
//
// 目前服務對象：Android + Web（暫不考慮 iOS）。
// - Android：permission_handler 為主
// - Web：以 kIsWeb 短路並回傳適當值
//
// 集中原本散落於 splash / permission_handler_page / settings_screen 的
// 「讀取 / 請求 / 永久拒絕 dialog」三重複邏輯。

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:youbike/core/utils/log_service.dart';
import 'package:youbike/ui/widgets/base/permission_denied_dialog.dart';

/// 略過權限引導的 SharedPreferences key，集中避免散落硬編字串。
class PermissionPrefKeys {
  PermissionPrefKeys._();

  static const String skipLocation = 'skip_location_permission';
}

/// 定位權限請求的結果分類。
enum LocationRequestResult {
  granted,
  denied,
  permanentlyDenied,
  unavailable,
}

class PermissionService {
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  /// 是否處於 Web 平台 — 權限流程需短路。
  bool get isWeb => kIsWeb;

  // ── 定位權限 ──

  /// 取得定位權限目前狀態（已授權 / 限定授權 / 否）。
  /// - Web：走 `Geolocator.checkPermission()`（與 MapViewModel 同源），
  ///        反映 `navigator.permissions.query({name:'geolocation'})` 真實狀態，
  ///        避免「重設權限後仍誤判 granted」。
  /// - Native：permission_handler。
  Future<bool> readLocationStatus() async {
    if (kIsWeb) {
      try {
        final p = await Geolocator.checkPermission();
        return p == LocationPermission.always ||
            p == LocationPermission.whileInUse;
      } catch (e) {
        LogService().w('PERM', 'web location.status query failed: $e');
        return false;
      }
    }
    final s = await Permission.location.status;
    return s.isGranted || s.isLimited;
  }

  /// 一次性請求定位權限，永久拒絕回傳讓呼叫端彈 dialog。
  /// Web：先檢查 permissions API；若尚未 grant/deny，再走 Geolocator.requestPermission()
  /// （對應 navigator.geolocation 觸發瀏覽器原生詢問框）。
  Future<LocationRequestResult> requestLocationOnce() async {
    if (kIsWeb) {
      try {
        final p = await Geolocator.checkPermission();
        // 已 granted 不再二次詢問
        if (p == LocationPermission.always || p == LocationPermission.whileInUse) {
          return LocationRequestResult.granted;
        }
        // denied / deniedForever 在 Web 都視為「使用者曾拒絕／永久拒絕」，不重彈瀏覽器詢問框（Web 無此入口）
        if (p == LocationPermission.deniedForever ||
            p == LocationPermission.unableToDetermine) {
          return LocationRequestResult.denied;
        }
        // prompt → 觸發瀏覽器原生詢問框
        final requested = await Geolocator.requestPermission();
        if (requested == LocationPermission.always ||
            requested == LocationPermission.whileInUse) {
          return LocationRequestResult.granted;
        }
        return LocationRequestResult.denied;
      } catch (e) {
        LogService().e('PERM', 'request location (web) failed', error: e);
        return LocationRequestResult.unavailable;
      }
    }
    try {
      final status = await Permission.location.status;
      if (status.isPermanentlyDenied) {
        return LocationRequestResult.permanentlyDenied;
      }
      final result = await Permission.location.request();
      if (result.isGranted || result.isLimited) {
        return LocationRequestResult.granted;
      }
      if (result.isPermanentlyDenied) {
        return LocationRequestResult.permanentlyDenied;
      }
      return LocationRequestResult.denied;
    } catch (e) {
      LogService().e('PERM', 'request location failed', error: e);
      return LocationRequestResult.unavailable;
    }
  }

  // ── 共用 UI helper ──

  /// 彈出「權限永久拒絕」對話框，引導使用者前往 App 設定。
  /// 集中於 [PermissionDeniedDialog]，原本重複於兩處的 dialog 樣板已被合併。
  void showPermanentlyDeniedDialog(BuildContext context) {
    PermissionDeniedDialog.show(context);
  }
}