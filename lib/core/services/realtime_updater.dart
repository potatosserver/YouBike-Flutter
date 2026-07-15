import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart' hide DistanceCalculator;
import 'package:youbike_android/core/services/distance_calculator.dart';
import 'package:youbike_android/data/models/station.dart';
import 'package:youbike_android/data/services/api_service.dart';

/// Fetches realtime vehicle data from the API and applies it + distance to stations.
class RealtimeUpdater {
  final DistanceCalculator _calc;

  RealtimeUpdater({DistanceCalculator? calculator})
      : _calc = calculator ?? const DistanceCalculator();

  Future<void> apply(List<Station> stations, LatLng refPoint) async {
    if (stations.isEmpty) return;

    try {
      final api = ApiService();
      final vehicleData = await api.fetchRealtimeVehicles(
        stations.map((s) => s.id).toList(),
      );

      for (final s in stations) {
        if (vehicleData.containsKey(s.id)) {
          final data = vehicleData[s.id] as Map<String, dynamic>;
          s.availableBikes = data['available_2_0'] ?? 0;
          s.availableElectricBikes = data['available_e'] ?? 0;
          s.emptySpaces = data['empty_spaces'] ?? 0;
        }
        s.distance = _calc.haversine(
          refPoint.latitude, refPoint.longitude, s.lat, s.lng,
        );
      }
    } catch (e) {
      debugPrint('RealtimeUpdater error: $e');
    }
  }
}