import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../models/station.dart';

class AppState extends ChangeNotifier {
  // --- State Properties ---
  LatLng? center;
  LatLng? lastKnownLocation;
  bool isFollowingUser = false;
  bool isLoading = true;
  double loadingProgress = 0.0;
  String loadingNotice = "正在初始化...";
  String currentLang = 'zh';
  String selectedRegion = 'all';
  bool useLocation = true;
  int countdownRemaining = 60;
  List<Station> allStations = [];
  Set<String> pinnedStationIds = {};
  List<String> logs = [];
  
  final Map<String, Map<String, String>> regions = {
    'all': {'name': '全部區域'},
    'taipei': {'name': '台北市'},
    'newtaipei': {'name': '新北市'},
    'taichung': {'name': '台中市'},
    'tainan': {'name': '台南市'},
    'kaohsiung': {'name': '高雄市'},
  };

  // --- Internal Helpers ---
  late SharedPreferences _prefs;

  // --- Getters ---
  bool get isDarkMode => false; // Simplified for now; can be linked to ThemeProvider if needed

  // --- Core Lifecycle ---
  Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      await _loadPreferences();
      await _loadStations();
      
      if (useLocation) {
        await _updateLocation();
      } else {
        center = getEffectiveLocation();
      }
      
      isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint("[APP-INIT-ERROR] $e");
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadPreferences() async {
    selectedRegion = _prefs.getString('selected_region') ?? 'all';
    useLocation = _prefs.getBool('use_location') ?? true;
    pinnedStationIds = (_prefs.getStringList('pinned_stations') ?? []).toSet();
  }

  Future<void> _loadStations() async {
    loadingNotice = "正在同步場站數據...";
    try {
      await Future.delayed(const Duration(milliseconds: 800));
      
      allStations = [
        Station(id: '1', nameTw: '台北車站', nameEn: 'Taipei Station', lat: 25.047, lng: 121.540, addressTw: '台北市', addressEn: 'Taipei'),
        Station(id: '2', nameTw: '信義區', nameEn: 'Xinyi District', lat: 25.033, lng: 121.565, addressTw: '台北市', addressEn: 'Taipei'),
      ];
      _fullStationList = List.from(allStations);
      
      final cacheData = jsonEncode(_fullStationList.map((s) => s.toJson()).toList());
      await _prefs.setString('cached_stations', cacheData);
      
      loadingProgress = 1.0;
    } catch (e) {
      debugPrint("[STATIONS-LOAD-ERROR] $e");
    }
  }

  // --- Location Logic ---
  Future<void> requestPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
  }

  Future<Position?> getCurrentPosition() async {
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
    } catch (e) {
      debugPrint("[GPS-ERROR] $e");
      return null;
    }
  }

  Future<void> _updateLocation() async {
    try {
      await requestPermission();
      final pos = await getCurrentPosition();
      if (pos != null) {
        lastKnownLocation = LatLng(pos.latitude, pos.longitude);
        center = lastKnownLocation;
      } else {
        center = getEffectiveLocation();
      }
    } catch (e) {
      debugPrint("[LOCATION-UPDATE-ERROR] $e");
      center = getEffectiveLocation();
    }
    notifyListeners();
  }

  LatLng getEffectiveLocation() {
    if (lastKnownLocation != null) return lastKnownLocation!;
    return const LatLng(25.0330, 121.5654); 
  }

  void setFollowing(bool value) {
    isFollowingUser = value;
    notifyListeners();
  }

  // --- Station Logic ---
  void searchStations(String query) {
    if (query.isEmpty) {
      allStations = List.from(_fullStationList);
    } else {
      allStations = _fullStationList.where((s) => 
        s.nameTw.contains(query) || s.nameEn.contains(query)
      ).toList();
    }
    notifyListeners();
  }

  void refreshStations() async {
    loadingNotice = "正在更新場站...";
    isLoading = true;
    notifyListeners();
    try {
      await _loadStations();
      countdownRemaining = 60;
    } catch (e) {
      debugPrint("[REFRESH-ERROR] $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void setRegion(String regionId) async {
    selectedRegion = regionId;
    _filterStationsByRegion();
    try {
      await _prefs.setString('selected_region', regionId);
    } catch (e) {
      debugPrint("[PREF-ERROR] $e");
    }
    notifyListeners();
  }

  void _filterStationsByRegion() {
    if (selectedRegion == 'all') {
      allStations = List.from(_fullStationList);
    } else {
      allStations = _fullStationList.where((s) => 
        s.nameTw.contains(regions[selectedRegion]?['name'] ?? '')
      ).toList();
    }
  }

  void setUseLocation(bool value) async {
    useLocation = value;
    if (value) {
      await _updateLocation();
    }
    try {
      await _prefs.setBool('use_location', value);
    } catch (e) {
      debugPrint("[PREF-ERROR] $e");
    }
    notifyListeners();
  }

  void togglePinStation(String id) async {
    if (pinnedStationIds.contains(id)) {
      pinnedStationIds.remove(id);
    } else {
      pinnedStationIds.add(id);
    }
    try {
      await _prefs.setStringList('pinned_stations', pinnedStationIds.toList());
    } catch (e) {
      debugPrint("[PREF-ERROR] $e");
    }
    notifyListeners();
  }

  String getDistanceLabel(double distance) {
    if (distance < 1000) return "${distance.toInt()}m";
    return "${(distance / 1000).toStringAsFixed(2)}km";
  }

  // --- Timer Logic ---
  void startCountdown() {
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (countdownRemaining > 0) {
        countdownRemaining--;
        notifyListeners();
      } else {
        refreshStations();
        timer.cancel();
      }
    });
  }

  void addLog(String msg, {bool isError = false}) {
    logs.add("${DateTime.now().toString().split('.').first}: ${isError ? '❌' : 'ℹ️'} $msg");
    if (logs.length > 100) logs.removeAt(0);
    notifyListeners();
  }

  List<Station> _fullStationList = [];
}
