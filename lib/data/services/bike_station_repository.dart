import 'package:youbike/data/models/bike_station.dart';
import 'package:youbike/data/services/api_service.dart';
import 'package:youbike/data/services/moovo/moovo_api_client.dart';
import 'package:youbike/core/utils/log_service.dart';

/// 雙源 (YouBike + Moovo) Repository — API 邊界兩條各自獨立,對外單一口徑。
///
/// Step 3 設計範圍:
/// - 暴露兩方法: [fetchYouBikeStations] / [fetchMoovoStations]
/// - 各自轉成 `List<BikeStation>` 對外
/// - 失敗時回空 list (log warning),不拋例外
/// - 舊 VM / API client 照常運作;新 VM (Step 4) 切換後透過這個 repo 取資料
class BikeStationRepository {
  final ApiService _ybApi;
  final MoovoApiClient _moovoApi;

  BikeStationRepository({
    ApiService? apiService,
    MoovoApiClient? moovoApi,
  })  : _ybApi = apiService ?? ApiService(),
        _moovoApi = moovoApi ?? MoovoApiClient();

  // ── YouBike ─────────────────────────────────────────

  /// 拉全部 YouBike 站點基礎資料 (station-min-yb2.json)。
  /// 失敗回 null。
  Future<List<BikeStation>?> fetchYouBikeStations() async {
    try {
      final stations = await _ybApi.fetchAllStations();
      return stations.toBikes();
    } catch (e) {
      LogService().w('Repo', 'fetchYouBikeStations failed: $e');
      return null;
    }
  }

  /// 對 [ids] (station_no) 拉即時車輛數據。
  Future<Map<String, dynamic>> fetchYouBikeRealtime(List<String> ids) {
    return _ybApi.fetchRealtimeVehicles(ids);
  }

  // ── Moovo ──────────────────────────────────────────

  /// 拉 Moovo 全台站點 (cityId=0 → ~459 站聚合)。
  Future<List<BikeStation>?> fetchMoovoStations() async {
    try {
      final stations = await _moovoApi.fetchStationsForCity(0);
      if (stations == null) return null;
      return stations.toBikes();
    } catch (e) {
      LogService().w('MoovoRepo', 'fetchMoovoStations failed: $e');
      return null;
    }
  }

  // ── 便利方法 ──────────────────────────────────────

  /// 兩來源同調,以非同步平行執行。[yb] 與 [mo] callback 各傳入結果。
  /// 不用等到兩邊都回來才進入 callback mode，適合在最終 Refresh flow (Step 4) 使用。
  Future<void> fetchAllAndApply({
    required void Function(List<BikeStation>) onYouBike,
    required void Function(List<BikeStation>) onMoovo,
  }) async {
    final results = await Future.wait([
      fetchYouBikeStations(),
      fetchMoovoStations(),
    ]);
    // ignore: unnecessary_cast — Dynamic list element cast needed for type safety
    onYouBike((results[0] as List<BikeStation>?) ?? []);
    // ignore: unnecessary_cast
    onMoovo((results[1] as List<BikeStation>?) ?? []);
  }
}