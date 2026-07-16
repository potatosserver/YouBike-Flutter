import 'package:youbike/core/utils/log_service.dart';
import 'package:latlong2/latlong.dart' hide DistanceCalculator;
import 'package:youbike/data/models/station.dart';
import 'package:youbike/data/services/api_service.dart';

/// 從 API 取得即時車輛數據並填入站點。
/// 距離由 StationSorter 統一計算，此處不重複。
class RealtimeUpdater {
  const RealtimeUpdater();

  Future<void> apply(List<Station> stations, LatLng _) async {
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
      }
    } catch (e) {
      LogService().e('RT_UPDATER', 'Realtime update failed', error: e);
    }
  }
}
