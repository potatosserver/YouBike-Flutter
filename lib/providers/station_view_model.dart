import 'dart:async';
import 'dart:convert';
import 'package:youbike/core/utils/log_service.dart';
import 'package:latlong2/latlong.dart' hide DistanceCalculator;
import 'package:youbike/core/services/card_refresh_coordinator.dart';
import 'package:youbike/core/services/map_move_trigger.dart';
import 'package:youbike/core/services/station_sorter.dart';
import 'package:youbike/data/models/station.dart';
import 'package:youbike/data/services/api_service.dart';
import 'package:youbike/data/services/app_config_service.dart';
import 'package:youbike/providers/map_view_model.dart';
import 'package:youbike/providers/localized_view_model.dart';
import 'package:youbike/providers/loading_view_model.dart';

/// Marker emitted by [_inFlightRefresh] when a refresh is cancelled because
/// a newer request has taken its place. Callers can ignore / treat this as
/// a quiet "never happened" instead of log-spamming an error.
class _CancelledRefresh implements Exception {
  const _CancelledRefresh();
  @override
  String toString() => 'refresh cancelled by newer request';
}

/// Hard caps that respect what the /tw2/parkingInfo server actually
/// hands us back. The server paginates its `data` at `per_page=20` and
/// rejects payloads above ~50 station_no entries with HTTP 422, so:
///  - Non-search ("n nearest") mode surfaces 20 stations — one full
///    server page, in a single POST.
///  - Search mode surfaces 40 stations (= two complete server pages).
///    That number is intentionally picked so the realtime API walk
///    splits into exactly two 20-station POSTs, each landing in a single
///    server page without any silent truncation between them.
const int kNonSearchMax = 20;
const int kSearchMax = 40;
/// Render-side cap: how many stations _executeRefresh surfaces into the
/// panel after sortAndPick. Mirrors what line 178 / 248 / 256 in the
/// docstring assume. Pinned stays the same as kNonSearchMax.
const int kStationPanelMax = kNonSearchMax;

class StationViewModel extends LocalizedViewModel {
  AppConfigService config;
  MapViewModel? mapVm;
  final CardRefreshCoordinator _coordinator;

  StationViewModel(this.config, this.mapVm,
      {CardRefreshCoordinator? coordinator, MapMoveTrigger? mapTrigger})
      : _coordinator = coordinator ??
            CardRefreshCoordinator(
                mapMoveTrigger: mapTrigger ?? MapMoveTrigger()) {
    _wasUseLocation = config.useLocation;
    _lastPinnedIds = Set<String>.from(config.pinnedStationIds);
    config.addListener(_onConfigChanged);
    _startCountdown();
  }

  List<Station> _fullStationList = [];
  List<Station> get fullStations => _fullStationList;
  List<Station> allStations = [];
  bool isUpdating = false;

  /// Active search query. When non-empty, the 60s cycle and the manual
  /// refresh button keep refreshing the filtered list instead of
  /// collapsing back to "n nearest stations".
  String _activeQuery = '';
  String get activeQuery => _activeQuery;

  /// Bumped on every fresh refresh entry. The async refresh path captures
  /// the value at entry and re-checks before mutating `allStations` /
  /// `isUpdating`. A newer request that runs to completion first will
  /// "poison" any older in-flight refresh's effect — without this, a slow
  /// stale response could overwrite the newer one and bounce the panel
  /// back to the previous query.
  int _refreshGeneration = 0;

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
  /// 觸發者：倒數歸零、手動更新按鈕、釘選/定位 live change。
  /// 若使用者處於搜尋狀態 (_activeQuery 非空)，會自動套用同一個關鍵字，
  /// 避免搜尋的卡片結果被「距離最近前 N 名」洗掉。
  /// 面板 / API 數量上限：
  ///   - 搜尋模式: kSearchMax (40) — 拆成 two 20 個 station batch 走 server pagination
  ///   - 無搜尋: kStationPanelMax (20) — 「最近 N 名」模式下, 一個完整 server 頁
  Future<void> refreshCards({LatLng? moveTo}) async {
    final stations = _activeQuery.isEmpty
        ? _fullStationList
        : _filterStations(_activeQuery);
    await _executeRefresh(stations: stations, moveTo: moveTo);
  }

  /// 設定目前搜尋關鍵字，清空時還原成 n+20 最近站。
  /// Query is held in [_activeQuery] so the 60-second cycle and the manual
  /// refresh button keep refreshing the same filter result.
  ///
  /// Search order is intentionally "distance-first, query-second":
  ///   1. name-filter candidates from the full list
  ///   2. sort those candidates by `StationSorter.sortAndPick` against the
  ///      effective ref point -> take kSearchMax (40), so the 40 are the
  ///      *closest* name-matching stations, not just the first 40 in the
  ///      api's natural (station_no) order
  ///   3. hand those 40 to `_executeRefresh` where the coordinator will
  ///      sort+pin-by-priority and pick 20 to render. The realtime API
  ///      walk then splits 20 into two 20-batches -> two complete server
  ///      pages.
  Future<void> setQuery(String query) async {
    _activeQuery = query;
    if (query.isEmpty) {
      await refreshCards();
      return;
    }
    final filtered = _filterStations(query);
    if (filtered.isEmpty) {
      allStations = [];
      notifyListeners();
      return;
    }
    // Distance-first: pick the kSearchMax closest name matches. Pinned
    // stations are honored as a priority slice inside this set so a
    // pinned "台大" stays visible when searching "台".
    final refPoint = mapVm?.getEffectiveLocation();
    final byDistance = refPoint == null
        ? filtered
        : StationSorter().sortAndPick(
            filtered,
            refPoint,
            config.pinnedStationIds,
            limit: kSearchMax,
          );
    await _executeRefresh(stations: byDistance);
  }

  List<Station> _filterStations(String query) {
    return _fullStationList
        .where((s) => s.nameTw.contains(query) || s.nameEn.contains(query))
        .toList();
  }

  Future<void> _executeRefresh(
      {required List<Station> stations, LatLng? moveTo}) async {
    if (_fullStationList.isEmpty) await fetchBaseData(null);
    if (_fullStationList.isEmpty) return;

    // Bump generation on entry. Any older in-flight refresh will fail the
    // generation check below and silently dismiss its own result.
    final myGen = ++_refreshGeneration;

    _beginRefresh();

    try {
      // Two cap rules, by mode:
      //  * Non-search ("n nearest"): pass the *entire* _fullStationList to
      //    sortAndPick so the truly closest stations can be discovered.
      //    cap with kStationPanelMax (20) only via sortAndPick's `limit`.
      //    Slicing here would pre-trim by station_no order and silently
      //    exclude, say, every southern station for a non-Taipei user.
      //  * Search: setQuery has already constrained the hits to kSearchMax
      //    (40) — that number is intentionally picked so that the realtime
      //    API walk falls into exactly TWO 20-station POST batches, hitting
      //    two complete server pages without any silent truncation.
      //    We let all 40 candidates pass through and rely on the
      //    kStationPanelMax `limit` to keep the panel tidy at 20.
      final candidates = await _coordinator.execute(
        fullStations: stations,
        pinnedIds: config.pinnedStationIds,
        mapVm: mapVm!,
        limit: kStationPanelMax,
        moveTo: moveTo,
      );

      // Bail-out barrier: a newer refresh already entered while we were
      // awaiting. Drop our result so the newer one wins; also avoid the
      // noisy LogService().e in the catch path further down.
      if (myGen != _refreshGeneration) {
        throw const _CancelledRefresh();
      }

      allStations = candidates;
    } on _CancelledRefresh {
      // Quiet — this is the expected outcome when a newer refresh takes
      // over. Do not log error, do not touch `isUpdating`, do not notify.
    } catch (e) {
      LogService().e('STATION', 'Refresh failed', error: e);
    } finally {
      if (myGen == _refreshGeneration) {
        isUpdating = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    config.removeListener(_onConfigChanged);
    _countdownTimer?.cancel();
    super.dispose();
  }
}
