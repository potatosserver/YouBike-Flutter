// connectivity_checker_native.dart — 原生平台（Android / iOS）實作
//
// 透過 connectivity_plus 的 ConnectivityManager（Android）/ Reachability（iOS）
// 精確區分 cellular / wifi / ethernet / none。

import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

/// 原生平台的 [ConnectivityChecker] 實作。
class ConnectivityChecker {
  const ConnectivityChecker();

  /// 回傳 true 表示目前連線是行動數據（cellular），不是 WiFi 或無連線。
  Future<bool> isCellular() async {
    try {
      final results = await Connectivity().checkConnectivity();
      // v6+ 回傳 List<ConnectivityResult>
      return results.contains(ConnectivityResult.mobile);
    } catch (_) {
      // 無法偵測狀態時保守處理 → 視同非行動數據
      return false;
    }
  }

  /// 監聽連線狀態變化的 stream。
  /// 原生平台：由 Connectivity.onConnectivityChanged 提供。
  Stream<void> get onConnectivityChanged =>
      Connectivity().onConnectivityChanged.map((_) {});
}