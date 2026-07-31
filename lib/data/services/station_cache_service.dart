import 'dart:convert';

import 'package:youbike/core/utils/log_service.dart';
import 'package:youbike/data/services/station_cache_storage.dart';
// 條件式 import — 提供 [createStorage()] 根據平台回傳對應實作。
import 'package:youbike/data/services/station_cache_storage_native.dart';

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

  // 平台實作由 conditional import 注入。
  // ignore: prefer_typing_uninitialized_variables
  late final IStationCacheStorage _storage;

  StationCacheService({IStationCacheStorage? storage}) {
    _storage = storage ?? createStorage();
  }

  // ── YouBike ───────────────────────────────────────

  Future<List<Map<String, dynamic>>?> loadYouBike() async {
    return _read(_youbikeKey, _maxAge);
  }

  Future<void> saveYouBike(List<Map<String, dynamic>> data) async {
    await _write(_youbikeKey, data);
  }

  // ── Moovo ─────────────────────────────────────────

  Future<List<Map<String, dynamic>>?> loadMoovo() async {
    return _read(_moovoKey, _maxAge);
  }

  Future<void> saveMoovo(List<Map<String, dynamic>> data) async {
    await _write(_moovoKey, data);
  }

  // ── internals ─────────────────────────────────────

  Future<List<Map<String, dynamic>>?> _read(
      String key, Duration maxAge) async {
    final raw = await _storage.read(key);
    if (raw == null) return null;

    try {
      final envelope = jsonDecode(raw) as Map<String, dynamic>;

      final cachedAt =
          DateTime.tryParse(envelope['cached_at'] as String? ?? '') ??
              DateTime(2000);
      final age = DateTime.now().difference(cachedAt);
      if (age > maxAge) {
        LogService().i(
            'Cache', '$key expired (age ${age.inMinutes}m > max ${maxAge.inHours}h)');
        return null;
      }

      final items = envelope['data'];
      if (items is! List) return null;
      return items.cast<Map<String, dynamic>>();
    } catch (e) {
      LogService().w('Cache', 'parse $key failed: $e');
      return null;
    }
  }

  Future<void> _write(String key, List<Map<String, dynamic>> data) async {
    final envelope = {
      'cached_at': DateTime.now().toIso8601String(),
      'data': data,
    };
    final encoded = jsonEncode(envelope);
    await _storage.write(key, encoded);
    LogService().i('Cache', 'saved $key (${data.length} items)');
  }
}
