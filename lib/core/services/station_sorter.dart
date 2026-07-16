import 'package:latlong2/latlong.dart' hide DistanceCalculator;
import 'package:youbike/core/services/distance_calculator.dart';
import 'package:youbike/data/models/station.dart';

/// 依距離排序站點，釘選置頂，回傳前 N 筆。
class StationSorter {
  final DistanceCalculator _calc;

  StationSorter({DistanceCalculator? calculator})
      : _calc = calculator ?? const DistanceCalculator();

  List<Station> sortAndPick(
    List<Station> stations,
    LatLng refPoint,
    Set<String> pinnedIds, {
    int limit = 10,
  }) {
    if (stations.isEmpty) return [];

    for (final s in stations) {
      s.distance = _calc.haversine(
        refPoint.latitude,
        refPoint.longitude,
        s.lat,
        s.lng,
      );
    }

    final sorted = List<Station>.from(stations)
      ..sort((a, b) => a.distance.compareTo(b.distance));

    final pinned =
        sorted.where((s) => pinnedIds.contains(s.id.trim())).toList();
    final normal =
        sorted.where((s) => !pinnedIds.contains(s.id.trim())).toList();

    return [...pinned, ...normal.take(limit)].toList();
  }
}
