import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:youbike_android/services/app_state.dart';
import 'package:youbike_android/models/station.dart';

class MockApiService {
  List<Station> fetchAllStations() {
    return List.generate(100, (i) => Station(
      id: 'S$i',
      nameTw: 'Station $i',
      nameEn: 'Station $i',
      addressTw: 'Addr $i',
      addressEn: 'Addr $i',
      lat: 22.0 + (i * 0.01),
      lng: 120.0 + (i * 0.01),
    ));
  }
  
  Future<Map<String, dynamic>> fetchRealtimeVehicles(List<String> ids) async {
    return {for (var id in ids) id: {'available_2_0': 1, 'available_e': 1, 'empty_spaces': 1}};
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppState Logic Verification', () {
    late AppState appState;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      appState = AppState();
      // Manually inject some stations to avoid real API calls in this logic test
      appState.allStations = List.generate(100, (i) => Station(
        id: 'S$i',
        nameTw: 'Station $i',
        nameEn: 'Station $i',
        addressTw: 'Addr $i',
        addressEn: 'Addr $i',
        lat: 22.0 + (i * 0.01),
        lng: 120.0 + (i * 0.01),
      ));
      appState.lastKnownLocation = const LatLng(22.0, 120.0);
    });

    test('searchStations should prioritize pinned stations and limit to 50', () async {
      // Pin station S99 (the furthest one)
      appState.pinnedStationIds = {'S99'};
      
      // Search with keyword (matches all in this mock)
      await appState.searchStations('Station');
      
      expect(appState.allStations.first.id, 'S99', reason: 'Pinned station should be first');
      expect(appState.allStations.length, 50, reason: 'Search results should be limited to 50');
    });

    test('searchStations with empty query should limit to 10', () async {
      await appState.searchStations('');
      expect(appState.allStations.length, 10, reason: 'Empty search should limit to 10');
    });
  });
}
