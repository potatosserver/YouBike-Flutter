import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart' hide DistanceCalculator;

import 'package:youbike/core/services/bike_station_mixer.dart';
import 'package:youbike/core/services/bike_station_sorter.dart';
import 'package:youbike/core/services/map_move_trigger.dart';
import 'package:youbike/core/services/realtime_updater.dart';
import 'package:youbike/core/utils/log_service.dart';
import 'package:youbike/data/models/bike_station.dart';
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
    _lastPinnedIds = Set<String>.from(config.pinnedStationIds);
    config.addListener(_onConfigChanged);
    _startCountdown();
  }

  /// 外部 (home / splash) 在使用前呼喚,讓資料與 GPS 先準備好。
  Future<void> boot() async {
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
  List<BikeStation> _fullBikes = [];
  List<BikeStation> get allBikes => _fullBikes;

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
  Set<String> _lastPinnedIds = {};

  LatLng _refPoint() => _mapVm?.getEffectiveLocation() ?? _regionCenter();

  LatLng _regionCenter() {
    final entry = _config.regions[_config.selectedRegion];
    if (entry != null)
      return LatLng(entry['lat'] as double, entry['lng'] as double);
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
      // re-sort — keep current count, don't expand
      _panelBikes = _sorter.sortByDistance(
        stations: _panelBikes,
        refPoint: _refPoint(),
        pinnedIds: _config.pinnedStationIds,
        limit: _activeQuery.isEmpty ? 20 : 40,
      );
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
      _sortPanel();

      final rawYB = [
        for (final b in _panelBikes)
          if (b.source == BikeStationSource.youbike) b.rawStation!,
      ];
      if (rawYB.isNotEmpty) {
        await _realtime.apply(rawYB, _refPoint());
        // re-sort — keep pinned at top, preserve current count
        _panelBikes = _sorter.sortByDistance(
          stations: _panelBikes,
          refPoint: _refPoint(),
          pinnedIds: _config.pinnedStationIds,
          limit: _panelBikes.length.clamp(1, 20),
        );
      }
    } catch (e) {
      LogService().w('BikeVM', 'refresh failed: $e');
    }

    _isLoading = false;
    notifyListeners();

    if (moveTo != null) {
      _trigger.fire(moveTo);
    }
  }

  void focusStation(BikeStation bs) {
    _trigger.fire(LatLng(bs.lat, bs.lng));
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
    _wasUseLocation = _config.useLocation;
    _lastPinnedIds = Set<String>.from(_config.pinnedStationIds);

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
    if (pinChanged) _reorderByPin();
  }

  Future<void> _onLocationEnabled() async {
    await _mapVm?.requestAndCenterLocation();
    refresh();
  }

  void _reorderByPin() {
    if (_panelBikes.isEmpty) return;
    final pinned = <BikeStation>[], normal = <BikeStation>[];
    for (final s in _panelBikes)
      (_config.pinnedStationIds.contains(s.id) ? pinned : normal).add(s);
    _panelBikes = [...pinned, ...normal];
    notifyListeners();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_countdown > 0) { _countdown--; notifyListeners(); } else refresh();
    });
  }

  bool _setEquals(Set<String> a, Set<String> b) => a.length == b.length && a.containsAll(b);

  @override
  void dispose() {
    _config.removeListener(_onConfigChanged);
    _countdownTimer?.cancel();
    super.dispose();
  }
}