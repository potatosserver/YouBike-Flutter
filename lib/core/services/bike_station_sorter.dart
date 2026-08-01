import 'package:latlong2/latlong.dart' hide DistanceCalculator;

import 'package:youbike/core/services/distance_calculator.dart';
import 'package:youbike/data/models/bike_station.dart';

/// 統一 BikeStation 的排序 + 距離計算 + 釘選置頂。
class BikeStationSorter {
  final DistanceCalculator _calc;

  const BikeStationSorter({DistanceCalculator? distanceCalculator})
      : _calc = distanceCalculator ?? const DistanceCalculator();

  /// 對一批 [BikeStation] 計算並寫回 `distance` 欄位。
  /// 純距離計算,不排序、不分流;給需要在分流前先算距離的場景使用
  /// (例: `_sortPanel()` 在 pinned/rest 分組前,確保 pinned 站點也有新鮮距離)。
  void calculateDistance({
    required List<BikeStation> stations,
    required LatLng refPoint,
  }) {
    for (final s in stations) {
      s.distance = _calc.haversine(
        refPoint.latitude,
        refPoint.longitude,
        s.lat,
        s.lng,
      );
    }
  }

  /// 對於一批 [BikeStation],計算各站的距離、依距離升序、釘選置頂、
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
}