import 'dart:async';
import 'dart:convert';
import 'package:youbike_android/core/utils/log_service.dart';
import 'package:latlong2/latlong.dart' hide DistanceCalculator;
import 'package:youbike_android/core/services/card_refresh_coordinator.dart';
import 'package:youbike_android/core/services/map_move_trigger.dart';
import 'package:youbike_android/data/models/station.dart';
import 'package:youbike_android/data/services/api_service.dart';
import 'package:youbike_android/data/services/app_config_service.dart';
import 'package:youbike_android/providers/map_view_model.dart';
import 'package:youbike_android/providers/localized_view_model.dart';
import 'package:youbike_android/providers/loading_view_model.dart';

class StationViewModel extends LocalizedViewModel {
  AppConfigService config;
  MapViewModel? mapVm;
  final CardRefreshCoordinator _coordinator;

  StationViewModel(this.config, this.mapVm,
      {CardRefreshCoordinator? coordinator, MapMoveTrigger? mapTrigger})
      : _coordinator = coordinator ??
            CardRefreshCoordinator(mapMoveTrigger: mapTrigger ?? MapMoveTrigger()) {
    _wasUseLocation = config.useLocation;
    _lastPinnedIds = Set<String>.from(config.pinnedStationIds);
    config.addListener(_onConfigChanged);
    _startCountdown();
  }

  List<Station> _fullStationList = [];
  List<Station> get fullStations => _fullStationList;
  List<Station> allStations = [];
  bool isUpdating = false;

  int countdownRemaining = 60;
  Timer? _countdownTimer;
  late bool _wasUseLocation;

  /// 暴露給 HomeScreen 注入 MapController。
  MapMoveTrigger get mapTrigger => _coordinator.mapTrigger;

  void updateDependencies(AppConfigService newConfig, MapViewModel newMapVm) {
    config.removeListener(_onConfigChanged);
    config = newConfig;
    mapVm = newMapVm;
    _wasUseLocation = config.useLocation;
    _lastPinnedIds = Set<String>.from(config.pinnedStationIds);
    config.addListener(_onConfigChanged);
    notifyListeners();
  }

  late Set<String> _lastPinnedIds;

  void _onConfigChanged() {
    if (config.useLocation != _wasUseLocation) {
      _wasUseLocation = config.useLocation;
      if (config.useLocation) {
        // 開啟定位 → 立即請求 GPS → 全更新（與按下定位按鈕相同）
        _onLocationEnabled();
      } else {
        // 關閉定位 → 清除 GPS → 全更新
        mapVm?.lastKnownLocation = null;
        mapVm?.center = null;
        mapVm?.notifyListeners();
        refreshCards(moveTo: mapVm?.getEffectiveLocation());
      }
      return;
    }

    // 釘選變動 → 立即重排（不重取 API，不重算距離，不移動地圖）
    if (!_setEquals(config.pinnedStationIds, _lastPinnedIds)) {
      _lastPinnedIds = Set<String>.from(config.pinnedStationIds);
      _reorderByPin();
    }
  }

  void _reorderByPin() {
    if (allStations.isEmpty || _fullStationList.isEmpty) return;
    final pinned = <Station>[];
    final normal = <Station>[];
    for (final s in allStations) {
      if (config.pinnedStationIds.contains(s.id.trim())) {
        pinned.add(s);
      } else {
        normal.add(s);
      }
    }
    allStations = [...pinned, ...normal];
    notifyListeners();
  }

  bool _setEquals(Set<String> a, Set<String> b) =>
      a.length == b.length && a.containsAll(b);

  Future<void> _onLocationEnabled() async {
    await mapVm?.requestAndCenterLocation();
    refreshCards(moveTo: mapVm?.getEffectiveLocation());
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (countdownRemaining > 0) {
        countdownRemaining--;
        notifyListeners();
      } else {
        refreshCards();
      }
    });
  }

  Future<void> fetchBaseData(LoadingViewModel? loadingVm) async {
    try {
      final api = ApiService();
      final freshData = await api.fetchAllStations();
      if (freshData.isNotEmpty) {
        loadingVm?.updateStatus('init_syncing_stations',
            value: freshData.length, progress: 82);
        _fullStationList = freshData;
        await config.prefs?.setString(
          'cached_stations',
          jsonEncode(_fullStationList.map((s) => s.toJson()).toList()),
        );
      }
    } catch (e) {
      LogService().e('STATION', 'Base data fetch failed', error: e);
    }
  }

  void _beginRefresh() {
    isUpdating = true;
    countdownRemaining = 60;
    notifyListeners();
  }

  /// 重新排序、取得即時數據，並可選地圖移動。
  /// 觸發者：倒數歸零、手動更新按鈕、搜尋。
  Future<void> refreshCards({LatLng? moveTo}) async {
    if (_fullStationList.isEmpty) await fetchBaseData(null);
    if (_fullStationList.isEmpty) return;

    _beginRefresh();

    try {
      allStations = await _coordinator.execute(
        fullStations: _fullStationList,
        pinnedIds: config.pinnedStationIds,
        mapVm: mapVm!,
        limit: 10,
        moveTo: moveTo,
      );
    } catch (e) {
      LogService().e('STATION', 'refreshCards failed', error: e);
    } finally {
      isUpdating = false;
      notifyListeners();
    }
  }

  /// 依站名過濾，再委派給 refreshCards。
  void searchStations(String query) async {
    try {
      if (query.isEmpty) {
        await refreshCards();
        return;
      }
      final filtered = _fullStationList
          .where((s) => s.nameTw.contains(query) || s.nameEn.contains(query))
          .toList();
      if (filtered.isEmpty) {
        allStations = [];
        notifyListeners();
        return;
      }
      _beginRefresh();
      allStations = await _coordinator.execute(
        fullStations: filtered,
        pinnedIds: config.pinnedStationIds,
        mapVm: mapVm!,
        limit: 10,
        moveTo: null,
      );
    } catch (e) {
      LogService().e('STATION', 'Search failed', error: e);
    } finally {
      isUpdating = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    config.removeListener(_onConfigChanged);
    _countdownTimer?.cancel();
    super.dispose();
  }
}