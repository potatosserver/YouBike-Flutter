import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:youbike_android/data/models/station.dart';
import 'package:youbike_android/data/services/api_service.dart';
import 'package:youbike_android/data/services/app_config_service.dart';
import 'package:youbike_android/providers/map_view_model.dart';
import 'package:youbike_android/providers/localized_view_model.dart';
import 'package:youbike_android/providers/loading_view_model.dart';

class StationViewModel extends LocalizedViewModel {
  AppConfigService config;
  MapViewModel? mapVm; // 改為可空
  StationViewModel(this.config, this.mapVm) {
    _startCountdown();
  }

  List<Station> _fullStationList = []; 
  List<Station> get fullStations => _fullStationList;
  List<Station> allStations = [];
  bool isUpdating = false;
  
  int countdownRemaining = 60;
  Timer? _countdownTimer;

  void updateDependencies(AppConfigService newConfig, MapViewModel newMapVm) {
    config = newConfig;
    mapVm = newMapVm;
    notifyListeners();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (countdownRemaining > 0) {
        countdownRemaining--;
        notifyListeners();
      } else {
        refreshStations();
      }
    });
  }

  Future<void> fetchBaseData(LoadingViewModel? loadingVm) async {
    try {
      final api = ApiService();
      final freshData = await api.fetchAllStations();
      if (freshData.isNotEmpty) {
        // 回報真實站點數量到載入畫面
        loadingVm?.updateStatus('init_syncing_stations', value: freshData.length);
        
        _fullStationList = freshData;
        final cacheData = jsonEncode(_fullStationList.map((s) => s.toJson()).toList());
        await config.prefs?.setString('cached_stations', cacheData);
      }
    } catch (e) {
      debugPrint("Base data fetch error: $e");
    }
  }

  Future<void> updateRealtimeData([List<Station>? targets]) async {
    final targetList = targets ?? allStations;
    if (targetList.isEmpty) return;
    try {
      final api = ApiService();
      final vehicleData = await api.fetchRealtimeVehicles(targetList.map((s) => s.id).toList());
      final referencePoint = mapVm?.lastKnownLocation ?? mapVm?.getEffectiveLocation() ?? const LatLng(25.0330, 121.5654);
      
      for (var s in targetList) {
        if (vehicleData.containsKey(s.id)) {
          final data = vehicleData[s.id] as Map<String, dynamic>;
          s.availableBikes = data['available_2_0'] ?? 0;
          s.availableElectricBikes = data['available_e'] ?? 0;
          s.emptySpaces = data['empty_spaces'] ?? 0;
        }
        s.distance = _calculateDistance(referencePoint.latitude, referencePoint.longitude, s.lat, s.lng);
      }
      if (targets == null) notifyListeners();
    } catch (e) {
      debugPrint("Realtime update error: $e");
    }
  }


  Future<void> refreshStations({bool isInitial = false}) async {
    isUpdating = true;
    countdownRemaining = 60; // Reset countdown to 60
    notifyListeners();
    try {
      if (isInitial) {
        if (_fullStationList.isEmpty) await fetchBaseData(null);
        
        final referencePoint = mapVm?.lastKnownLocation ?? mapVm?.getEffectiveLocation() ?? const LatLng(25.0330, 121.5654);
        final sorted = List<Station>.from(_fullStationList);
        sorted.sort((a, b) {
          final distA = _calculateDistance(referencePoint.latitude, referencePoint.longitude, a.lat, a.lng);
          final distB = _calculateDistance(referencePoint.latitude, referencePoint.longitude, b.lat, b.lng);
          return distA.compareTo(distB);
        });
        allStations = _applyPrioritySort(sorted).take(10).toList();
      }
      await updateRealtimeData();
    } catch (e) {
      debugPrint("Refresh error: $e");
    } finally {
      isUpdating = false;
      notifyListeners();
    }
  }


  void searchStations(String query) async {
    try {
      List<Station> resultList;
      if (query.isEmpty) { 
        resultList = _applyPrioritySort(_fullStationList).take(10).toList(); 
      } else {
        final filtered = _fullStationList.where((s) => s.nameTw.contains(query) || s.nameEn.contains(query)).toList();
        resultList = _applyPrioritySort(filtered).take(10).toList();
      }
      await updateRealtimeData(resultList);
      allStations = resultList;
    } catch (e) {
      debugPrint("Search error: $e");
    } finally {
      notifyListeners();
    }
  }

  List<Station> _applyPrioritySort(List<Station> stations) {
    final referencePoint = mapVm?.lastKnownLocation ?? mapVm?.getEffectiveLocation() ?? const LatLng(25.0330, 121.5654);
    final sortedByDist = List<Station>.from(stations);
    sortedByDist.sort((a, b) {
      final distA = _calculateDistance(referencePoint.latitude, referencePoint.longitude, a.lat, a.lng);
      final distB = _calculateDistance(referencePoint.latitude, referencePoint.longitude, b.lat, b.lng);
      return distA.compareTo(distB);
    });
    
    final pinned = sortedByDist.where((s) => config.pinnedStationIds.contains(s.id.trim())).toList();
    final normal = sortedByDist.where((s) => !config.pinnedStationIds.contains(s.id.trim())).toList();
    return [...pinned, ...normal];
  }

  String getDistanceLabel(double distance) {
    return distance < 1000 ? "${distance.toStringAsFixed(0)}m" : "${(distance / 1000).toStringAsFixed(1)}km";
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000;
    final double dLat = (lat2 - lat1) * math.pi / 180;
    final double dLon = (lon2 - lon1) * math.pi / 180;
    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) + math.cos(lat1 * math.pi / 180) * math.cos(lat2 * math.pi / 180) * math.sin(dLon / 2) * math.sin(dLon / 2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }
}
