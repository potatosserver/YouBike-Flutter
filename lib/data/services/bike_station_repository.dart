import 'dart:async';

import 'package:youbike/data/models/bike_station.dart';
import 'package:youbike/data/models/moovo_station.dart';
import 'package:youbike/data/models/station.dart';
import 'package:youbike/data/services/api_service.dart';
import 'package:youbike/data/services/app_config_service.dart';
import 'package:youbike/data/services/moovo/moovo_api_client.dart';
import 'package:youbike/data/services/station_cache_service.dart';
import 'package:youbike/core/utils/connectivity_checker.dart';
import 'package:youbike/core/utils/log_service.dart';

/// 雙源 (YouBike + Moovo) Repository — API 邊界兩條各自獨立，對外單一口徑。
///
/// 快取策略（v1.3+）：
/// - 有快取 (≤24hr) → 同步立即回傳快取；UI 進場 (遮罩解除) 後再於背景刷新。
/// - 無快取 → 同步等待 API（不超時），寫入快取後回傳。
/// - 快取以 raw JSON 儲存，避免 proto/schema 演化相容性問題。
class BikeStationRepository {
  final ApiService _ybApi;
  final MoovoApiClient _moovoApi;
  final StationCacheService _cache;
  final AppConfigService? _config;

  BikeStationRepository({
    ApiService? apiService,
    MoovoApiClient? moovoApi,
    StationCacheService? cache,
    AppConfigService? config,
  })  : _ybApi = apiService ?? ApiService(),
        _moovoApi = moovoApi ?? MoovoApiClient(),
        _cache = cache ?? StationCacheService(),
        _config = config;

  // ── YouBike ─────────────────────────────────────────

  Future<List<BikeStation>?> fetchYouBikeStations() async {
    // Step 1: 嘗試讀取快取
    final cachedJson = await _cache.loadYouBike();
    if (cachedJson != null) {
      LogService().i('Repo', 'YouBike cache HIT (${cachedJson.length} stations)');
      // 流量節省模式下跳過背景刷新
      if (await _shouldSkipBgRefresh()) {
        LogService().i('Repo', 'YouBike background refresh SKIPPED (data saver)');
      } else {
        _scheduleBackgroundRefresh(_refreshYouBike);
      }
      return _deserializeYouBike(cachedJson);
    }

    LogService().i('Repo', 'YouBike cache MISS — fetching from API');
    // Step 2: 無快取 → 同步等待 API（不超時）
    return await _fetchAndCacheYouBike();
  }

  Future<List<BikeStation>?> _fetchAndCacheYouBike() async {
    try {
      final stations = await _ybApi.fetchAllStations();
      final stationBikes = stations.toBikes();

      // 序列化並寫入快取
      final jsonList = stations.map((s) => s.toJson()).toList();
      await _cache.saveYouBike(jsonList);

      return stationBikes;
    } catch (e) {
      LogService().w('Repo', 'fetchYouBikeStations failed: $e');
      return null;
    }
  }

  Future<void> _refreshYouBike() async {
    try {
      final stations = await _ybApi.fetchAllStations();
      final jsonList = stations.map((s) => s.toJson()).toList();
      await _cache.saveYouBike(jsonList);
      LogService().i('Repo', 'YouBike background refresh done');
    } catch (e) {
      LogService().w('Repo', 'YouBike background refresh failed: $e');
    }
  }

  List<BikeStation> _deserializeYouBike(List<Map<String, dynamic>> jsonList) {
    return jsonList
        .map((j) => Station.fromJson(j))
        .toList()
        .toBikes();
  }

  /// 對 [ids] (station_no) 拉即時車輛數據。
  Future<Map<String, dynamic>> fetchYouBikeRealtime(List<String> ids) {
    return _ybApi.fetchRealtimeVehicles(ids);
  }

  // ── Moovo ──────────────────────────────────────────

  Future<List<BikeStation>?> fetchMoovoStations() async {
    final cachedJson = await _cache.loadMoovo();
    if (cachedJson != null) {
      LogService().i('MoovoRepo', 'Moovo cache HIT (${cachedJson.length} stations)');
      // Moovo 不受 dsSkipCacheRefresh 限制 — 該開關僅限制 YouBike。
      _scheduleBackgroundRefresh(_refreshMoovo);
      return _deserializeMoovo(cachedJson);
    }
    LogService().i('MoovoRepo', 'Moovo cache MISS — fetching from API');
    return await _fetchAndCacheMoovo();
  }

  Future<List<BikeStation>?> _fetchAndCacheMoovo() async {
    try {
      final stations = await _moovoApi.fetchStationsForCity(0);
      if (stations == null) return null;

      final jsonList = stations.map((s) => s.toJson()).toList();
      await _cache.saveMoovo(jsonList);

      return stations.toBikes();
    } catch (e) {
      LogService().w('MoovoRepo', 'fetchMoovoStations failed: $e');
      return null;
    }
  }

  Future<void> _refreshMoovo() async {
    try {
      final stations = await _moovoApi.fetchStationsForCity(0);
      if (stations != null) {
        final jsonList = stations.map((s) => s.toJson()).toList();
        await _cache.saveMoovo(jsonList);
        LogService().i('Repo', 'Moovo background refresh done');
      }
    } catch (e) {
      LogService().w('MoovoRepo', 'Moovo background refresh failed: $e');
    }
  }

  List<BikeStation> _deserializeMoovo(List<Map<String, dynamic>> jsonList) {
    return jsonList
        .map((j) => MoovoStation.fromJson(j))
        .toList()
        .toBikes();
  }

  // ── 便利方法 ────────────────────────────────────

  /// 雙源同調，以非同步平行執行。
  Future<void> fetchAllAndApply({
    required void Function(List<BikeStation>) onYouBike,
    required void Function(List<BikeStation>) onMoovo,
  }) async {
    final results = await Future.wait([
      fetchYouBikeStations(),
      fetchMoovoStations(),
    ]);
    onYouBike(results[0] ?? <BikeStation>[]);
    onMoovo(results[1] ?? <BikeStation>[]);
  }

  /// 背景刷新任務 — 延遲到遮罩解除後才開始。
  ///
  /// 採用 `Future.delayed(Duration.zero)` 將任務推到事件佇列最尾端，
  /// 確保 `AppWrapper` 的 `finally` (設 `_isInitializing = false`) 已先執行。
  /// 兩次呼叫會進入同一個微任務週期，仍是同步排隊、非並行。
  void _scheduleBackgroundRefresh(Future<void> Function() task) {
    Future<void>.delayed(Duration.zero, task);
  }

  /// 流量節省模式是否在目前連線環境下應該生效。
  /// 總開關 OFF 或 dsCellularOnly ON + 目前非行動數據 → false。
  Future<bool> _shouldApplyDataSaver() async {
    final c = _config;
    if (c == null) return false;
    if (!c.useDataSaver) return false;
    if (c.dsCellularOnly) {
      final onCellular = await const ConnectivityChecker().isCellular();
      if (!onCellular) return false;
    }
    return true;
  }

  /// 流量節省模式下是否應跳過背景快取刷新（異步版）。
  Future<bool> _shouldSkipBgRefresh() async {
    if (!(await _shouldApplyDataSaver())) return false;
    final c = _config;
    if (c == null) return false;
    return c.dsSkipCacheRefresh;
  }
}