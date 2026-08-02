import 'dart:async';
import 'dart:js_interop';

import 'package:youbike/core/utils/log_service.dart';
import 'package:youbike/data/services/station_cache_storage.dart';

/// Web (Chrome / Firefox / Safari) 實作 — 透過瀏覽器 `localStorage`。
///
/// 4MB JSON 在 localStorage 5MB 配額內（單站 key），超出時 localStorage 會拋
/// QuotaExceededError，本層 catch 後只記 log、不拋出。
///
/// 為何自行定義 extension type 而非 `package:web` 高階 wrapper？
/// 在 Flutter 3.44 `--wasm` (SkWasm / dart2wasm) 模式下，
/// `web.window.localStorage.getItem(key)` 的回傳因為 JS string ↔ wasm 邊界
/// 型別處理丟失，導致 cache 永遠 MISS（CanvasKit / dart2js 模式正常）。
/// 本實作改走 `dart:js_interop` 的低階 extension type 顯式收 JSString，
/// 在兩個 renderer 都行為一致。
extension type _Storage._(JSObject _) implements JSObject {
  external JSAny? getItem(JSString key);
  external JSAny? setItem(JSString key, JSString value);
}

@JS('localStorage')
external _Storage get _localStorage;

/// Web 平台實作 — 自有 extension type 顯式處理 wasm 邊界。
class LocalStorageCacheStorage implements IStationCacheStorage {
  @override
  Future<String?> read(String key) async {
    try {
      final result = _localStorage.getItem(key.toJS);
      // JS null/undefined → Dart null；JS string → Dart string。
      if (result == null) return null;
      return (result as JSString).toDart;
    } catch (e) {
      LogService().w('CacheStorage', 'localStorage read $key failed: $e');
      return null;
    }
  }

  @override
  Future<void> write(String key, String value) async {
    try {
      _localStorage.setItem(key.toJS, value.toJS);
    } catch (e) {
      // QuotaExceededError / SecurityError (隱私模式) → 靜默，caller 視為 MISS。
      LogService().w('CacheStorage', 'localStorage write $key failed: $e');
    }
  }
}

/// Conditional import 入口 — web 平台使用本檔 factory。
IStationCacheStorage createStorage() => LocalStorageCacheStorage();
