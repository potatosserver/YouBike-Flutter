import 'package:latlong2/latlong.dart' hide DistanceCalculator;
import 'package:youbike_android/core/services/distance_calculator.dart';
import 'package:youbike_android/data/models/station.dart';

/// Distance-sorts stations, places pinned on top, returns top N.
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

    // 1. Assign distance to every station
    for (final s in stations) {
      s.distance = _calc.haversine(
        refPoint.latitude, refPoint.longitude, s.lat, s.lng,
      );
    }

    // 2. Sort by distance ascending
    final sorted = List<Station>.from(stations)
      ..sort((a, b) => a.distance.compareTo(b.distance));

    // 3. Pinned first, then unpinned
    final pinned = sorted
        .where((s) => pinnedIds.contains(s.id.trim()))
        .toList();
    final normal = sorted
        .where((s) => !pinnedIds.contains(s.id.trim()))
        .toList();

    return [...pinned, ...normal].take(limit).toList();
  }
}