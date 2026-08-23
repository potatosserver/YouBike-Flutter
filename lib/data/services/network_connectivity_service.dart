import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// 網路連線監控服務
/// 自動偵測網路狀態，提供離線模式判斷
/// - 有網路 -> 線上模式
/// - 無網路 -> 離線模式
class NetworkConnectivityService with ChangeNotifier {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  bool _isOnline = true; // 預設為線上
  bool _hasInitialized = false;

  bool get isOnline => _isOnline;
  bool get isOffline => !_isOnline;
  bool get hasInitialized => _hasInitialized;

  /// 啟動監控
  Future<void> start() async {
    if (_hasInitialized) return;

    // 初始檢查
    await _checkAndUpdate();

    // 監聽變化
    _connectivitySub = _connectivity.onConnectivityChanged.listen((results) {
      final wasOnline = _isOnline;
      _isOnline = results.isNotEmpty && results.any((r) => r != ConnectivityResult.none);

      if (wasOnline != _isOnline) {
        notifyListeners();
      }
    });

    _hasInitialized = true;
  }

  /// 檢查並更新狀態
  Future<void> _checkAndUpdate() async {
    try {
      final results = await _connectivity.checkConnectivity();
      final wasOnline = _isOnline;
      _isOnline = results.isNotEmpty && results.any((r) => r != ConnectivityResult.none);

      if (wasOnline != _isOnline) {
        notifyListeners();
      }
    } catch (_) {
      // 檢查失敗視為離線
      if (_isOnline) {
        _isOnline = false;
        notifyListeners();
      }
    }
  }

  /// 強制刷新檢查
  Future<void> refresh() async {
    await _checkAndUpdate();
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    super.dispose();
  }
}