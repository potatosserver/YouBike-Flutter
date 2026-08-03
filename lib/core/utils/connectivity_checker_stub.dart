// connectivity_checker_stub.dart — Web platform stub
//
// Web 上 connectivity_plus 只回 wifi/none，無法區分 cellular。
// 改用 dart:js_interop 直接讀取 navigator.connection.effectiveType，
// 若不可用則 fallback 到 navigator.onLine 的 boolean（永遠回 false 表示非 cellular）。
//
// 注意：不用 dart:html / EventStreamProvider — 確保 dart2wasm 相容。

import 'dart:async';
import 'dart:js_interop';

@JS('navigator.connection')
external _NetworkInformation? get _navigatorConnection;

@JS()
@staticInterop
class _NetworkInformation {}

extension on _NetworkInformation {
  @JS('effectiveType')
  external JSString? get effectiveType;
}

/// Web 平台的 [ConnectivityChecker] 實作。
class ConnectivityChecker {
  const ConnectivityChecker();

  static final _sc = StreamController<void>.broadcast();

  /// 回傳 true 表示目前連線是行動數據（cellular）。
  ///
  /// Web：讀取 navigator.connection.effectiveType，
  /// 回傳 cellular / slow-2g / 2g / 3g 時為 true；
  /// 若 API 不可用，保守回 false。
  Future<bool> isCellular() async {
    try {
      final conn = _navigatorConnection;
      if (conn == null) return false;
      final type = conn.effectiveType?.toDart;
      if (type == null) return false;
      // cellular / slow-2g / 2g / 3g 為行動數據，4g / 5g / wifi / ethernet 為非行動
      // 注意：4g/5g 在桌面瀏覽器上可能是透過 USB tethering，
      // 但瀏覽器無法分辨，保守回 false。
      switch (type) {
        case 'cellular':
        case 'slow-2g':
        case '2g':
        case '3g':
          return true;
        default:
          return false;
      }
    } catch (_) {
      return false;
    }
  }

  /// 監聽連線狀態變化的 stream。
  /// Web 平台的 online/offline 為粗粒度 (onLine boolean)，
  /// 不區分 wifi vs cellular，因此此 stream 僅供 API 一致化，無回調。
  Stream<void> get onConnectivityChanged => _sc.stream;
}