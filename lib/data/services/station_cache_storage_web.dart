import 'dart:async';

import 'package:web/web.dart' as web;
import 'package:youbike/core/utils/log_service.dart';
import 'package:youbike/data/services/station_cache_storage.dart';

/// Web (Chrome / Firefox / Safari) 實作 — 透過瀏覽器 `localStorage`。
///
/// 4MB JSON 在 localStorage 5MB 配額內（單站 key），超出時 localStorage 會拋
/// QuotaExceededError，本層 catch 後只記 log、不拋出。
class LocalStorageCacheStorage implements IStationCacheStorage {
  // 同步 API；包成 Future 以滿足介面契約（避免任何 caller 端 await 變數失效）。
  @override
  Future<String?> read(String key) async {
    try {
      // ignore: invalid_use_of_internal_member
      final value = web.window.localStorage.getItem(key);
      return value;
    } catch (e) {
      LogService().w('CacheStorage', 'localStorage read $key failed: $e');
      return null;
    }
  }

  @override
  Future<void> write(String key, String value) async {
    try {
      web.window.localStorage.setItem(key, value);
    } catch (e) {
      // QuotaExceededError / SecurityError (隱私模式) → 靜默，caller 視為 MISS。
      LogService().w('CacheStorage', 'localStorage write $key failed: $e');
    }
  }
}

/// Conditional import 入口 — web 平台使用本檔 factory。
IStationCacheStorage createStorage() => LocalStorageCacheStorage();
