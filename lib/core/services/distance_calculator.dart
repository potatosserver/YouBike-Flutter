import 'dart:math' as math;

/// Pure Haversine distance calculator. No state, no dependencies.
class DistanceCalculator {
  const DistanceCalculator();

  /// Returns distance in meters between two lat/lng points.
  double haversine(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000;
    final double dLat = (lat2 - lat1) * math.pi / 180;
    final double dLon = (lon2 - lon1) * math.pi / 180;
    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * math.pi / 180) *
            math.cos(lat2 * math.pi / 180) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  /// Human-readable distance label: "320m" or "1.2km".
  String format(double distance) {
    return distance < 1000
        ? '${distance.toStringAsFixed(0)}m'
        : '${(distance / 1000).toStringAsFixed(1)}km';
  }
}