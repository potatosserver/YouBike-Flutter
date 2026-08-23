import 'dart:convert';

import 'package:youbike/core/utils/log_service.dart';
import 'package:youbike/data/services/station_cache_storage.dart';
// 條件式 import — Web (dart2js / dart2wasm / SkWasm) 走 localStorage，
// Native (Android/iOS/Desktop) 走 File I/O。
// 注意：要用 `dart.library.js_interop` 而非 `dart.library.html`，
// 後者在 Flutter 3.24+ 已 deprecated 且在 dart2wasm 下不被識別為 true。
import 'package:youbike/data/services/station_cache_storage_io.dart'
    if (dart.library.js_interop) 'package:youbike/data/services/station_cache_storage_web.dart'
    show createStorage;

/// 站點快取服務 — 將 YouBike / Moovo 基礎資料序列化後寫入儲存層。
///
/// 策略：
/// - 儲存層：native → `path_provider` + File；web → `localStorage`
/// - 過期：24 小時
/// - 序列化：JSON envelope `{ cached_at, data }`
class StationCacheService {
  static const _youbikeKey = 'youbike_stations.json';
  static const _moovoKey = 'moovo_stations.json';
  static const _maxAge = Duration(hours: 24);

  // 平台實作由 conditional import 注入，明確指定介面型態以維護編譯期安全。
  final IStationCacheStorage _storage;

  StationCacheService({IStationCacheStorage? storage})
      : _storage = storage ?? createStorage();

  // ── YouBike ───────────────────────────────────────

  Future<List<Map<String, dynamic>>?> loadYouBike({bool ignoreExpiry = false}) async {
    return _read(_youbikeKey, _maxAge, ignoreExpiry: ignoreExpiry);
  }

  Future<void> saveYouBike(List<Map<String, dynamic>> data) async {
    await _write(_youbikeKey, data);
  }

  // ── Moovo ─────────────────────────────────────────

  Future<List<Map<String, dynamic>>?> loadMoovo({bool ignoreExpiry = false}) async {
    return _read(_moovoKey, _maxAge, ignoreExpiry: ignoreExpiry);
  }

  Future<void> saveMoovo(List<Map<String, dynamic>> data) async {
    await _write(_moovoKey, data);
  }

  // ── internals ─────────────────────────────────────

  Future<List<Map<String, dynamic>>?> _read(
      String key, Duration maxAge, {bool ignoreExpiry = false}) async {
    final raw = await _storage.read(key);
    if (raw == null) return null;

    try {
      final envelope = jsonDecode(raw) as Map<String, dynamic>;

      final cachedAtRaw = envelope['cached_at'] as String?;
      final cachedAt = cachedAtRaw != null
          ? DateTime.tryParse(cachedAtRaw)
          : null;

      if (cachedAt == null) {
        return null;
      }

      // 統一轉為 UTC 計算時間差，防止時區轉換異常導致計算出負數或誤判過期
      final age = DateTime.now().toUtc().difference(cachedAt.toUtc());
      
      // 離線模式忽略過期檢查
      if (!ignoreExpiry && (age > maxAge || age.isNegative)) {
        LogService().i(
            'Cache', '$key expired (age ${age.inMinutes}m > max ${maxAge.inHours}h)');
        return null;
      }

      final items = envelope['data'];
      if (items is! List) return null;

      // 顯式轉換型態 Map<String, dynamic>.from(e)，避免使用 .cast<>() 觸發潛在的 TypeError
      return items
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (e) {
      LogService().w('Cache', 'parse $key failed: $e');
      return null;
    }
  }

  Future<void> _write(String key, List<Map<String, dynamic>> data) async {
    final envelope = {
      'cached_at': DateTime.now().toUtc().toIso8601String(),
      'data': data,
    };
    final encoded = jsonEncode(envelope);
    await _storage.write(key, encoded);
    LogService().i('Cache', 'saved $key (${data.length} items)');
  }
}