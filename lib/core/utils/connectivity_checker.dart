import 'package:connectivity_plus/connectivity_plus.dart';

/// 偵測目前裝置連線類型，供流量節省模式使用。
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
}