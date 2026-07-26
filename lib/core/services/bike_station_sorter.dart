import 'package:latlong2/latlong.dart' hide DistanceCalculator;

import 'package:youbike/core/services/distance_calculator.dart';
import 'package:youbike/data/models/bike_station.dart';
import 'package:youbike/data/models/station.dart';

/// 統一 BikeStation 的排序 + 距離計算 + 釘選置頂 — 取代兩源分離的邏輯。
///
/// Step 2 設計範圍 (最小可驗證範圍):
/// - 新增本 class，提供 [sortByDistance] (吃 `List<BikeStation>`)。
/// - 保留 [sortAndPick] (吃 `Station`) 作為相容性橋接，內部呼叫 [sortByDistance] 相同邏輯。
/// - 步結尾不修改任何 call-site — 既有的 StationSorter / MoovoViewModel 仍運作相同。
/// Step 4 (合併 VM) 時會統一呼叫 本 class。
///
/// DistanceCalculator 部署 (常數、Haversine) 沿用舊 `DistanceCalculator`。
class BikeStationSorter {
  final DistanceCalculator _calc;

  const BikeStationSorter({DistanceCalculator? distanceCalculator})
      : _calc = distanceCalculator ?? const DistanceCalculator();

  /// 對於一批 [BikeStation]，計算各站的距離、依距離升序、釘選置頂、
  /// 主力取前 [limit] 名。
  ///
  /// [refPoint] 為參考點（GPS or region default），釘選者不計入 limit 名限量。
  List<BikeStation> sortByDistance({
    required List<BikeStation> stations,
    required LatLng refPoint,
    required Set<String> pinnedIds,
    int limit = 20,
  }) {
    if (stations.isEmpty) return [];

    // 計算各站距離並存入 BikeStation.distance (直接 mutate 底層)。
    for (final s in stations) {
      s.distance = _calc.haversine(
        refPoint.latitude,
        refPoint.longitude,
        s.lat,
        s.lng,
      );
    }

    final sorted = [...stations]
      ..sort((a, b) => a.distance.compareTo(b.distance));

    final pinned = sorted.where((s) => pinnedIds.contains(s.id)).toList();
    final normal = sorted.where((s) => !pinnedIds.contains(s.id)).toList();

    return [...pinned, ...normal.take(limit)];
  }

  // ── 舊式橋接（deprecated, 內部轉調）─────────────────────

  /// 舊 Station-only 入口。在 Step 4 之前繼續用此 method 以便
  /// CardRefreshCoordinator 維持相容。Step 4 後會將此 method 移除。
  @Deprecated('使用 BikeStationSorter.sortByDistance() 取代')
  List<Station> sortAndPick(
    List<Station> stations,
    LatLng refPoint,
    Set<String> pinnedIds, {
    int limit = 20,
  }) {
    if (stations.isEmpty) return [];

    // 透過 Station.toBike() 轉為 BikeStation，使用同一個 sorter。
    final bikes = stations.map((s) => s.toBike()).toList();
    final sorted = sortByDistance(
      stations: bikes,
      refPoint: refPoint,
      pinnedIds: pinnedIds,
      limit: limit,
    );

    // 轉回原始 Station — 因為舊 API 回傳的是 Station 列表。
    // 注意：外層可能也會依賴原始 Station 型別做其他操作，
    // 所以將 `raw` 取回以維持 穩定性。
    return sorted
        .map((b) => b.rawStation!)
        .toList();
  }
}