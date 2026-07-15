import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' hide DistanceCalculator;
import 'package:youbike_android/core/services/card_refresh_coordinator.dart';
import 'package:youbike_android/core/services/distance_calculator.dart';
import 'package:youbike_android/core/services/map_move_trigger.dart';
import 'package:youbike_android/data/models/station.dart';
import 'package:youbike_android/data/services/api_service.dart';
import 'package:youbike_android/data/services/app_config_service.dart';
import 'package:youbike_android/providers/map_view_model.dart';
import 'package:youbike_android/providers/localized_view_model.dart';
import 'package:youbike_android/providers/loading_view_model.dart';

class StationViewModel extends LocalizedViewModel {
  AppConfigService config;
  MapViewModel? mapVm;
  final CardRefreshCoordinator _coordinator;
  final DistanceCalculator _calc = const DistanceCalculator();

  StationViewModel(this.config, this.mapVm,
      {CardRefreshCoordinator? coordinator, MapMoveTrigger? mapTrigger})
      : _coordinator = coordinator ??
            CardRefreshCoordinator(mapMoveTrigger: mapTrigger ?? MapMoveTrigger()) {
    _startCountdown();
  }

  List<Station> _fullStationList = [];
  List<Station> get fullStations => _fullStationList;
  List<Station> allStations = [];
  bool isUpdating = false;

  int countdownRemaining = 60;
  Timer? _countdownTimer;

  /// Exposed so HomeScreen can attach its MapController.
  MapMoveTrigger get mapTrigger => _coordinator.mapTrigger;

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
        refreshCards();
      }
    });
  }

  // ── base data (unchanged) ──

  Future<void> fetchBaseData(LoadingViewModel? loadingVm) async {
    try {
      final api = ApiService();
      final freshData = await api.fetchAllStations();
      if (freshData.isNotEmpty) {
        loadingVm?.updateStatus('init_syncing_stations',
            value: freshData.length, progress: 82);
        _fullStationList = freshData;
        await config.prefs?.setString(
          'cached_stations',
          jsonEncode(_fullStationList.map((s) => s.toJson()).toList()),
        );
      }
    } catch (e) {
      debugPrint('Base data fetch error: $e');
    }
  }

  // ── single entry point for everything ──

  /// Re-sorts, fetches realtime data, and optionally moves the map.
  /// Called by: countdown expiry, manual update button, search.
  Future<void> refreshCards({LatLng? moveTo}) async {
    if (_fullStationList.isEmpty) await fetchBaseData(null);
    if (_fullStationList.isEmpty) return;

    isUpdating = true;
    countdownRemaining = 60;
    notifyListeners();

    try {
      allStations = await _coordinator.execute(
        fullStations: _fullStationList,
        pinnedIds: config.pinnedStationIds,
        mapVm: mapVm!,
        limit: 10,
        moveTo: moveTo,
      );
    } catch (e) {
      debugPrint('refreshCards error: $e');
    } finally {
      isUpdating = false;
      notifyListeners();
    }
  }

  /// Search filters station names, then delegates to refreshCards.
  void searchStations(String query) async {
    try {
      if (query.isEmpty) {
        await refreshCards();
        return;
      }
      final filtered = _fullStationList
          .where((s) => s.nameTw.contains(query) || s.nameEn.contains(query))
          .toList();
      if (filtered.isEmpty) {
        allStations = [];
        notifyListeners();
        return;
      }
      // Use coordinator directly with the filtered subset
      isUpdating = true;
      countdownRemaining = 60;
      notifyListeners();
      allStations = await _coordinator.execute(
        fullStations: filtered,
        pinnedIds: config.pinnedStationIds,
        mapVm: mapVm!,
        limit: 10,
        moveTo: null,
      );
    } catch (e) {
      debugPrint('Search error: $e');
    } finally {
      isUpdating = false;
      notifyListeners();
    }
  }

  String getDistanceLabel(double distance) => _calc.format(distance);

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }
}