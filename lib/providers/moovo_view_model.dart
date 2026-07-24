import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart' hide DistanceCalculator;
import 'package:youbike/core/services/distance_calculator.dart';
import 'package:youbike/core/services/map_move_trigger.dart';
import 'package:youbike/core/utils/log_service.dart';
import 'package:youbike/data/models/moovo_station.dart';
import 'package:youbike/data/services/app_config_service.dart';
import 'package:youbike/data/services/moovo/moovo_api_client.dart';
import 'package:youbike/providers/map_view_model.dart';

/// 站點 ViewModel。
///
/// 設計上完全平行於 `StationViewModel`:
/// - 只讀自身狀態,UI 直接 `Provider.of<MoovoViewModel>(context)`
/// - 訂閱 [AppConfigService.useMoovo]:
///   - false → 清空 stations、不再 fetch
///   - true  → fetch `?cityId=0&withCache=true` 拿全台 459 個聚合站
///
/// **2026-07 API 實測發現**:Moovo 對任何 cityId 都回同一個全台 pool,
/// 因此不需要 per-city closest-city 算法 — 一次 fetch 即拿到完整 station 清單。
/// 距離 ref point 沿用 `MapMoveTrigger.refPoint` 跟 YouBike 一致。
class MoovoViewModel extends ChangeNotifier {
  /// 全台 Moovo fetch 的固定 cityId。詳見類別 doc comment。
  static const int _twAllCitiesId = 0;
  MoovoViewModel({
    required AppConfigService config,
    required MapMoveTrigger mapTrigger,
    MapViewModel? mapViewModel,
    MoovoApiClient? apiClient,
  })  : _config = config,
        _mapTrigger = mapTrigger,
        _mapVm = mapViewModel,
        _api = apiClient ?? MoovoApiClient() {
    // 距離 anchor 跟 YouBike **同源**:用 mapVm.getEffectiveLocation()
    // (GPS first, 選定 region 預設 fallback)。這樣 boot 第一次畫面就有
    // 合理的距離數值,user 拖地圖也**不會改** Moovo 的 anchor
    // (YouBike 也是這樣行為)。
    _refPoint = _mapVm?.getEffectiveLocation();
    _wasEnabled = _config.useMoovo;
    _config.addListener(_onConfigChanged);
    // 不再訂閱 MapMoveTrigger — 該 trigger 旨在給面板 re-card-refresh 訊號,
    // 距離 anchor 已由 mapVm 統一提供。
    _mapVm?.addListener(_onRefPointChanged);
    if (_wasEnabled) {
      // fire-and-forget; UI reflects via stations getter
      refresh();
    }
  }

  final AppConfigService _config;

  /// 仍由 main.dart 註入 `mapTrigger` 共享 trigger context
  /// (與 StationVM 共用, 知道彼此的 trigger surface)。
  /// 不再主動訂閱此 trigger — 距離 anchor 由 [_mapVm] 提供。
  // ignore: unused_field
  final MapMoveTrigger _mapTrigger;
  final MapViewModel? _mapVm;
  final MoovoApiClient _api;
  final DistanceCalculator _calc = const DistanceCalculator();

  /// 觸發最近城市算法的「ref point」(地圖中心或 GPS,跟 YouBike 同源)。
  LatLng? _refPoint;

  // ── 公開唯讀狀態 ──────────────────────────────────────────────

  List<MoovoStation> _stations = const [];
  bool _isLoading = false;
  Object? _lastError;
  late bool _wasEnabled;

  List<MoovoStation> get stations => _stations;
  Map<String, MoovoStation> get stationsById =>
      {for (final s in _stations) s.id: s};

  bool get isReady => _stations.isNotEmpty;
  bool get isLoading => _isLoading;
  Object? get lastError => _lastError;

  // ── 跨城搜尋 (台灣所有車站都能搜) ─────────────────────────

  /// 「全台 stations」已 fetch,搜尋純本地過濾 — 不必再發多 city HTTP。
  /// 對 `_stations` 做 name/address (zh-TW + en) 大小寫不分匹配。
  ///
  /// 為何保留方法簽名:讓 `search_panel` 不需要 adapter 轉介面、API 仍然
  /// 是「Future<List<MoovoStation>>」以保持一致,實作改為純本地過濾。
  Future<List<MoovoStation>> searchAcrossCities(String q) async {
    final query = q.trim().toLowerCase();
    if (query.isEmpty) return const [];
    final hits = _stations.where((s) {
      if (s.nameTw.toLowerCase().contains(query)) return true;
      if (s.nameEn.toLowerCase().contains(query)) return true;
      final addr = s.address;
      if (addr != null && addr.toLowerCase().contains(query)) return true;
      return false;
    }).toList();
    return hits;
  }

  /// 空 query 或 query 切換時清掉 last search。
  /// 之後 searchAcrossCities() 仍然是本地 `_stations` 重算,無快取。
  void clearCrossSearch() {
    // 不再持有 cross-search cache,這裡保留做外部接口。
  }

  /// 計算「帶距離」的副本,給卡片/側欄排序用。
  /// 距離 anchor = [_refPoint] (null 時 fallback 0.0)。
  List<MoovoStation> get stationsWithDistance {
    final r = _refPoint;
    return _stations.map((s) {
      final d = r == null
          ? 0.0
          : _calc.haversine(r.latitude, r.longitude, s.lat, s.lon);
      return MoovoStation(
        id: s.id,
        nameTw: s.nameTw,
        nameEn: s.nameEn,
        lat: s.lat,
        lon: s.lon,
        radius: s.radius,
        bikeCount: s.bikeCount,
        ebikeCount: s.ebikeCount,
        maxCapacity: s.maxCapacity,
        maxCapacityIsFallback: s.maxCapacityIsFallback,
        distance: d,
      );
    }).toList(growable: false);
  }

  // ── 主流程 ──────────────────────────────────────────────────

  Future<void> refresh() async {
    if (!_config.useMoovo) {
      _clearAll();
      return;
    }
    if (_isLoading) return;
    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      // 永遠一次 fetch 全台 459 站。
      final fetched = await _api.fetchStationsForCity(_twAllCitiesId);
      if (fetched != null) {
        _stations = fetched;
      } else {
        _lastError = 'stations unavailable';
      }
    } catch (e) {
      _lastError = e;
      LogService().w('MoovoVM', 'refresh failed: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── 內部 ──────────────────────────────────────────────────

  /// 視圖模型被關閉(`Provider` dispose 時)解除訂閱。
  @override
  void dispose() {
    _config.removeListener(_onConfigChanged);
    _mapVm?.removeListener(_onRefPointChanged);
    super.dispose();
  }

  void _onConfigChanged() {
    final enabled = _config.useMoovo;
    if (enabled == _wasEnabled) return;
    _wasEnabled = enabled;
    if (enabled) {
      refresh();
    } else {
      _clearAll();
    }
  }

  void _onRefPointChanged() {
    // 跟 YouBike 完全同源 — anchor 永遠來自 mapVm.getEffectiveLocation()
    // (GPS first -> 選定 region 預設)。得到 dev 要在 GPS / region 變動時刷 及 useLocation toggle。
    final next = _mapVm?.getEffectiveLocation();
    if (next == _refPoint) return;
    _refPoint = next;
    if (!_config.useMoovo) return;
    notifyListeners();
  }

  void _clearAll() {
    final dirty = _stations.isNotEmpty || _lastError != null;
    _stations = const [];
    _lastError = null;
    if (dirty) notifyListeners();
  }
}
