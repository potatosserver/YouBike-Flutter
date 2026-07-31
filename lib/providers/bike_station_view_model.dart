import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart' hide DistanceCalculator;

import 'package:youbike/core/services/bike_station_mixer.dart';
import 'package:youbike/core/services/bike_station_sorter.dart';
import 'package:youbike/core/services/map_move_trigger.dart';
import 'package:youbike/core/services/realtime_updater.dart';
import 'package:youbike/core/utils/log_service.dart';
import 'package:youbike/data/models/bike_station.dart';
import 'package:youbike/data/models/station.dart';
import 'package:youbike/data/services/app_config_service.dart';
import 'package:youbike/data/services/bike_station_repository.dart';
import 'package:youbike/providers/map_view_model.dart';

/// 統一的 ViewModel — YouBike + Moovo 共用一個 refresh cycle。
///
/// 兩個清單:
/// - [allBikes] 全量站池不分來源 → 地圖圖釘
/// - [panelItems] 限筆顯示清單 (依距離 / 搜尋) → 面板卡片
class BikeStationViewModel extends ChangeNotifier {
  // ── 建構 ──────────────────────────────────────

  BikeStationViewModel({
    required AppConfigService config,
    required BikeStationRepository repository,
    MapViewModel? mapVm,
    MapMoveTrigger? trigger,
  })  : _config = config,
        _repo = repository,
        _mapVm = mapVm,
        _trigger = trigger ?? MapMoveTrigger() {
    _wasUseLocation = config.useLocation;
    _wasUseMoovo = config.useMoovo;
    _wasUseMapStatusMarkers = config.useMapStatusMarkers;
    _lastPinnedIds = Set<String>.from(config.pinnedStationIds);
    config.addListener(_onConfigChanged);
    _startCountdown();
  }

  /// 外部 (home / splash) 在使用前呼喚,讓資料與 GPS 先準備好。
  /// 呼叫端若已 bootDone 會直接 return（單一入口、防重覆）。
  Future<void> boot() async {
    if (_bootDone) return; // ← 單一入口防護
    if (_config.useLocation) {
      await _mapVm?.requestAndCenterLocation();
    }
    await fetchBaseData();
  }

  final AppConfigService _config;
  final BikeStationRepository _repo;
  final MapViewModel? _mapVm;
  final MapMoveTrigger _trigger;

  MapMoveTrigger get mapTrigger => _trigger;

  final BikeStationSorter _sorter = const BikeStationSorter();
  final RealtimeUpdater _realtime = const RealtimeUpdater();

  // ── Observable ──────────────────────────────────────

  /// 全量站池 — 地圖圖釘餵此池。
  /// 每當即時數據寫入後遞增，供 UI 層判斷是否需要重建 markers（不複製 list）。
  int _dataVersion = 0;

  /// 給 ClusteredMarkerLayer 精確偵測即時數據變動。
  int get dataVersion => _dataVersion;
  List<BikeStation> _fullBikes = [];
  List<BikeStation> get allBikes => _fullBikes;

  /// O(N) 線性搜尋 — 給 [RealtimeStatusManager] 把 station id 反查回 [BikeStation]。
  /// 站池規模約數百,線性搜尋成本遠低於建表維護成本,維持簡單。
  BikeStation? byId(String id) {
    for (final b in _fullBikes) {
      if (b.id == id) return b;
    }
    return null;
  }

  // 當前顯示列表 — 面板用 (限筆）
  List<BikeStation> _panelBikes = [];
  List<BikeStation> get panelBikes => _panelBikes;

  /// 面板用的 [BikeStationItem] 列表。
  List<BikeStationItem> get panelItems {
    final lang = _config.currentLang;
    return [ for (final b in _panelBikes) BikeStationItem.fromBike(b, lang: lang) ];
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _bootDone = false;
  bool get bootDone => _bootDone;

  int _countdown = 60;
  int get countdownRemaining => _countdown;

  String _activeQuery = '';
  String get activeQuery => _activeQuery;

  // ── Private ──────────────────────────────────────────────────

  Timer? _countdownTimer;
  late bool _wasUseLocation;
  late bool _wasUseMoovo;
  late bool _wasUseMapStatusMarkers;
  Set<String> _lastPinnedIds = {};

  /// 站點級即時請求 TTL 快取：記錄每個站點最後一次 fetchRealtimeForVisible 的時間。
  /// key = station id, value = last fetch DateTime。30 秒內不會重複請求同一站點。
  final Map<String, DateTime> _lastRealtimeFetch = {};

  LatLng _refPoint() => _mapVm?.getEffectiveLocation() ?? _regionCenter();

  LatLng _regionCenter() {
    final entry = _config.regions[_config.selectedRegion];
    if (entry != null) {
      return LatLng(entry['lat'] as double, entry['lng'] as double);
    }
    return const LatLng(25.048, 121.517);
  }

  // ════════════════════════ Boot ══════════════════════════════

  Future<void> fetchBaseData() async {
    if (_isLoading) return;
    _isLoading = true;
    notifyListeners();

    try {
      final yb = await _repo.fetchYouBikeStations();
      final mo = (_config.useMoovo) ? await _repo.fetchMoovoStations() : null;

      final all = <BikeStation>{ if (yb != null) ...yb, if (mo != null) ...mo };
      _fullBikes = all.toList();

      _sortPanel();
    } catch (e) {
      LogService().w('BikeVM', 'base fetch failed: $e');
      // 資料拉取失敗 → 不設 bootDone，讓 HomeScreen 繼續顯示 loading。
      // 下一次 60s countdown 歸零時 refresh() 會被 _fullBikes.isEmpty guard 擋住，
      // 唯一的路徑是使用者重開 App 或是 config 變動觸發 _onLocationEnabled。
      _isLoading = false;
      notifyListeners();
      return; // ← 關鍵：若失敗就中斷，不往下設 bootDone
    }

    _isLoading = false;
    _bootDone = true;
    notifyListeners();

    _fillRealtimeBg();
  }

  void _sortPanel() {
    final pinned = <BikeStation>[];
    final rest = <BikeStation>[];
    final pinnedIds = _config.pinnedStationIds;
    for (final b in _fullBikes) {
      if (pinnedIds.contains(b.id)) {
        pinned.add(b);
      } else {
        rest.add(b);
      }
    }
    // pinned 優先，再從 rest 補到總共 20
    _panelBikes = [
      ...pinned,
      for (final b in _sorter.sortByDistance(
            stations: rest,
            refPoint: _refPoint(),
            pinnedIds: {},
            limit: 20 - pinned.length,
          ))
        b,
    ];
  }

  Future<void> _fillRealtimeBg() async {
    final rawYB = [ for (final b in _panelBikes) if (b.source == BikeStationSource.youbike) b.rawStation! ];
    if (rawYB.isEmpty) return;
    try {
      await _realtime.apply(rawYB, _refPoint());
      _dataVersion++;
      notifyListeners();
    } catch (e) {
      LogService().w('BikeVM', 'realtime failed: $e');
    }
  }

  // ═══════════════ Refresh ════════════════════════════════════

  Future<void> refresh({LatLng? moveTo}) async {
    if (_isLoading) return;
    if (_fullBikes.isEmpty) return; // 還沒 boot 完不做事
    _isLoading = true;
    _countdown = 60;
    notifyListeners();

    try {
      // 搜尋模式 — 重複用 setQuery 的篩選邏輯，不跳回預設 20 張
      if (_activeQuery.isNotEmpty) {
        final hits = _fullBikes.where(
          (s) => s.nameTw.contains(_activeQuery) || s.nameEn.contains(_activeQuery),
        ).toList();
        if (hits.isNotEmpty) {
          _panelBikes = _sorter.sortByDistance(
            stations: hits,
            refPoint: _refPoint(),
            pinnedIds: _config.pinnedStationIds,
            limit: 40, // 和 setQuery 一致
          );
        } // 若 hits 空 — 保持目前的 panelBikes（如果之前有結果）或空白
      } else {
        _sortPanel();
      }

      final rawYB = [
        for (final b in _panelBikes)
          if (b.source == BikeStationSource.youbike) b.rawStation!,
      ];
      if (rawYB.isNotEmpty) {
        await _realtime.apply(rawYB, _refPoint());
      }
    } catch (e) {
      LogService().w('BikeVM', 'refresh failed: $e');
    }

    _dataVersion++;
    _isLoading = false;
    notifyListeners();

    if (moveTo != null) {
      _trigger.fire(moveTo);
    }
  }

  /// 給 [RealtimeStatusManager] 用的 id-only 入口 —
  /// 由 marker 自我宣告「我現在是 unclustered」後,manager 集滿一批 id 後呼叫本方法。
  ///
  /// 與 [fetchRealtimeForVisible] 的差異:
  /// - 不再依賴「地圖層幫我算 visibleBounds」
  /// - 不再依賴「zoom>=16 才呼叫」 — 即使 zoom=10,只要某 marker 是孤立的,
  ///   它就會被 mount 並註冊,進而拿到自己的即時狀態。
  /// - 一律走 30s TTL + 上限 30 站,避免極端情況爆量。
  Future<void> fetchRealtimeForIds(List<String> ids) async {
    if (ids.isEmpty) return;

    final now = DateTime.now();
    final staleIds = <String>[];
    for (final id in ids) {
      final last = _lastRealtimeFetch[id];
      if (last == null || now.difference(last).inSeconds >= 30) {
        staleIds.add(id);
      }
    }
    if (staleIds.isEmpty) return;

    // 把 id 翻成 raw Station — 沒有 rawStation 代表該站已被池子移除(罕見但可能)。
    final rawStations = <Station>[];
    for (final id in staleIds) {
      final b = byId(id);
      if (b == null) continue;
      if (b.source != BikeStationSource.youbike) continue;
      if (b.rawStation == null) continue;
      rawStations.add(b.rawStation!);
      if (rawStations.length >= 30) break; // 防爆 — 與舊版 visibleYB 行為一致
    }
    if (rawStations.isEmpty) return;

    try {
      await _realtime.apply(rawStations, _refPoint());
      for (final id in staleIds) {
        _lastRealtimeFetch[id] = now;
      }
      _dataVersion++;
      notifyListeners();
    } catch (e) {
      LogService().w('BikeVM', 'realtime ids fetch failed: $e');
    }
  }

  /// 給 MapView 在畫面穩定後，對可視範圍內的非聚合圖釘站點請求即時狀態。
  /// 僅在 `useMapStatusMarkers` 啟用時才應呼叫。
  Future<void> fetchRealtimeForVisible(List<BikeStation> visibleYB) async {
    final now = DateTime.now();
    final staleIds = <String>[];
    for (final b in visibleYB) {
      final last = _lastRealtimeFetch[b.id];
      if (last == null || now.difference(last).inSeconds >= 30) {
        staleIds.add(b.id);
      }
    }
    if (staleIds.isEmpty) return;

    final rawYB = visibleYB
        .where((b) => staleIds.contains(b.id))
        .map((b) => b.rawStation!)
        .toList();
    if (rawYB.isEmpty) return;

    try {
      await _realtime.apply(rawYB, _refPoint());
      for (final id in staleIds) {
        _lastRealtimeFetch[id] = now;
      }
      _dataVersion++;
      notifyListeners();
    } catch (e) {
      LogService().w('BikeVM', 'realtime visible failed: $e');
    }
  }

  void focusStation(BikeStation bs) {
    _trigger.fire(LatLng(bs.lat, bs.lng));
  }

  /// 針對單一站點立即更新即時數據（僅限 YouBike）。
  /// 用於圖釘點擊後，確保彈窗顯示的是最新數據。
  Future<void> refreshStation(BikeStation bs) async {
    if (bs.source != BikeStationSource.youbike || bs.rawStation == null) return;

    try {
      // 僅針對該站點發送即時數據請求
      await _realtime.apply([bs.rawStation!], _refPoint());
      // 通知 UI 更新（彈窗會重新讀取 bs 的最新數值）
      _dataVersion++;
      notifyListeners();
    } catch (e) {
      LogService().w('BikeVM', 'single station refresh failed');
    }
  }

  void setQuery(String q) {
    _activeQuery = q.trim();
    if (q.isEmpty) {
      _sortPanel();
      _fillRealtimeBg();
      return;
    }
    // filter from full pool
    final hits = _fullBikes.where(
      (s) => s.nameTw.contains(_activeQuery) || s.nameEn.contains(_activeQuery),
    ).toList();
    if (hits.isEmpty) {
      _panelBikes = [];
      notifyListeners();
      return;
    }
    _panelBikes = _sorter.sortByDistance(
      stations: hits, refPoint: _refPoint(), pinnedIds: _config.pinnedStationIds, limit: 20);
    _fillRealtimeBg();
  }

  // ═══════════════ Config 監聽 ══════════════════════════════════

  void _onConfigChanged() {
    final locChanged = _config.useLocation != _wasUseLocation;
    final pinChanged = !_setEquals(_config.pinnedStationIds, _lastPinnedIds);
    final moovoChanged = _config.useMoovo != _wasUseMoovo;
    final statusMarkerChanged = _config.useMapStatusMarkers != _wasUseMapStatusMarkers;
    _wasUseLocation = _config.useLocation;
    _wasUseMoovo = _config.useMoovo;
    _wasUseMapStatusMarkers = _config.useMapStatusMarkers;
    _lastPinnedIds = Set<String>.from(_config.pinnedStationIds);

    if (statusMarkerChanged) {
      if (_config.useMapStatusMarkers) {
        _lastRealtimeFetch.clear(); // 啟用時清除歷史快取鎖定，確保立即抓取即時數據
      }
      _dataVersion++;
      notifyListeners();
    }

    if (locChanged) {
      if (_config.useLocation) {
        unawaited(_onLocationEnabled());
      } else {
        _mapVm?.lastKnownLocation = null;
        _mapVm?.center = null;
        _mapVm?.notifyListeners();
        refresh();
      }
      return;
    }
    if (moovoChanged) {
      if (_config.useMoovo && _bootDone) {
        unawaited(_loadMoovoIntoPool());
      } else if (_config.useMoovo) {
        // boot hasn't finished yet — boot will read the new useMoovo value
      } else {
        _removeMoovoFromPool();
      }
      return;
    }
    if (pinChanged) _reorderByPin();
  }

  Future<void> _onLocationEnabled() async {
    await _mapVm?.requestAndCenterLocation();
    refresh();
  }

  void _reorderByPin() {
    if (_panelBikes.isEmpty) return;
    final pinned = <BikeStation>[], normal = <BikeStation>[];
    for (final s in _panelBikes) {
      (_config.pinnedStationIds.contains(s.id) ? pinned : normal).add(s);
    }
    _panelBikes = [...pinned, ...normal];
    notifyListeners();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_countdown > 0) {
        _countdown--;
        notifyListeners();
      } else {
        refresh();
      }
    });
  }

  bool _setEquals(Set<String> a, Set<String> b) => a.length == b.length && a.containsAll(b);

  Future<void> _loadMoovoIntoPool() async {
    try {
      final mo = await _repo.fetchMoovoStations();
      if (mo != null) {
        // merge into _fullBikes — guard against duplicates
        final existingIds = _fullBikes.map((b) => b.id).toSet();
        final fresh = mo.where((b) => !existingIds.contains(b.id)).toList();
        if (fresh.isNotEmpty) {
          _fullBikes = [..._fullBikes, ...fresh];
          _sortPanel();
          _fillRealtimeBg();
        }
      }
    } catch (e) {
      LogService().w('BikeVM', 'loadMoovoIntoPool failed: $e');
    }
  }

  void _removeMoovoFromPool() {
    _fullBikes = _fullBikes.where((b) => b.source != BikeStationSource.moovo).toList();
    _sortPanel();
    notifyListeners();
  }

  @override
  void dispose() {
    _config.removeListener(_onConfigChanged);
    _countdownTimer?.cancel();
    super.dispose();
  }
}