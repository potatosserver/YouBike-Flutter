import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart';
import 'dart:math' as math;
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/station.dart';
import '../services/api_service.dart';

class AppState extends ChangeNotifier {
  // --- Settings & Preferences ---
  String currentRegion = 'kaohsiung';
  String currentLang = 'zh'; 
  bool isDarkMode = false;
  bool useLocation = true;
  
  // --- Loading State ---
  bool isLoading = true;
  int loadingProgress = 0;
  String currentNotice = "";
  bool isOffline = false;
  int countdownRemaining = 60; 
  
  // --- Pinned Stations ---
  Set<String> pinnedStationIds = {};
  
  // --- Location State ---
  LatLng center = const LatLng(22.6273, 120.3014); 
  LatLng? lastKnownLocation; 
  bool isFollowingUser = false;
  bool hasObtainedRealLocation = false;
  
  // --- Data State ---
  List<Station> allStations = [];
  List<Station> searchResults = [];
  List<fm.Marker> stationMarkers = [];
  
  // --- Log System ---
  final List<String> logs = [];
  
  void addLog(String message) {
    final timestamp = DateTime.now().toIso8601String();
    logs.add('[$timestamp] $message');
    if (logs.length > 500) logs.removeAt(0);
    notifyListeners();
  }
  
  AppState() {
    _init();
    _startGlobalCountdown();
  }
  
  void _startGlobalCountdown() {
    Future.delayed(Duration.zero, () async {
      while (true) {
        await Future.delayed(const Duration(seconds: 1));
        countdownRemaining--;
        if (countdownRemaining <= 0) {
          countdownRemaining = 60;
          await refreshStations();
        }
        notifyListeners();
      }
    });
  }
  
  Future<void> _init() async {
    // FIX: Start isLoading immediately to prevent any white screen before the first build
    isLoading = true; 
    loadingProgress = 0;
    
    addLog("Initializing AppState...");
    try {
      await loadSettings();
      
      // Start UI simulations immediately
      _startLoadingSimulation();
      
      // Sequence: Location -> Data
      await initializeLocation();
      await refreshStations();
    } catch (e) {
      addLog("Critical Init Error: $e");
    } finally {
      isLoading = false;
      addLog("Initial UI ready.");
      notifyListeners();
    }
  }

  void _startLoadingSimulation() {
    Future.delayed(Duration.zero, () async {
      final notices = currentLang == 'en' 
        ? ["❌Do not speed or ride in reverse", "❌Do not change lanes arbitrarily on sidewalks", "❌Do not use your phone while riding", "❌Avoid harsh braking while riding", "✔️Remember to adjust the seat to a proper height", "✔️Ensure that both front and rear lights are working", "✔️Remember to get bicycle accident insurance", "✔️Take your belongings from the basket"]
        : ["❌勿超速或逆向騎乘", "❌勿隨意變換車道在行人道上騎乘", "❌勿在車輛行駛中使用手機", "❌騎乘中勿緊急煞車", "✔️記得調整座墊至適宜高度", "✔️確認前後車燈功能正常", "✔️記得投保公共自行車傷害險", "✔️記得帶走置物籃內的隨身物品"];
      
      int progress = 0;
      while (isLoading) {
        if (progress < 85) {
          progress++;
          loadingProgress = progress;
        } else {
          loadingProgress = 85 + math.Random().nextInt(11);
        }
        
        // FIX: Update notice only every few ticks to prevent "crazy jumping"
        if (math.Random().nextInt(20) == 0) {
          currentNotice = notices[math.Random().nextInt(notices.length)];
        }
        
        notifyListeners();
        await Future.delayed(const Duration(milliseconds: 100));
      }
    });
  }
  
  Future<void> loadSettings() async {
    addLog("Loading settings...");
    final prefs = await SharedPreferences.getInstance();
    currentRegion = prefs.getString('currentRegion') ?? 'kaohsiung';
    currentLang = prefs.getString('currentLang') ?? 'zh';
    isDarkMode = prefs.getBool('isDarkMode') ?? false;
    useLocation = prefs.getBool('useLocation') ?? true;
    final pinnedList = prefs.getStringList('pinnedStations') ?? [];
    pinnedStationIds = pinnedList.toSet();
    notifyListeners();
  }
  
  Future<void> saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is String) {
      await prefs.setString(key, value);
    } else if (value is bool) {
      await prefs.setBool(key, value);
    }
    addLog("Setting saved: $key = $value");
  }
  
  Future<bool> requestPermission() async {
    addLog("Requesting location permission...");
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.always || permission == LocationPermission.whileInUse;
  }
  
  Future<Position?> getCurrentPosition() async {
    addLog("Fetching current position...");
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );
    } catch (e) {
      addLog("getCurrentPosition error: $e");
      return null;
    }
  }
  
  Future<void> initializeLocation() async {
    addLog("Initializing location services...");
    if (!useLocation) {
      _useDefaultLocation();
      return;
    }
    try {
      bool hasPermission = await requestPermission();
      if (!hasPermission) {
        addLog("Location permission denied.");
        _useDefaultLocation();
        return;
      }
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );
      center = LatLng(position.latitude, position.longitude);
      lastKnownLocation = center;
      hasObtainedRealLocation = true;
      isFollowingUser = true;
      addLog("Location fixed: ${center.latitude}, ${center.longitude}");
      
      Geolocator.getPositionStream(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 50),
      ).listen((Position pos) => _handleLocationUpdate(pos));
    } catch (e) {
      addLog("Location init error: $e");
      _useDefaultLocation();
    }
  }
  
  void _handleLocationUpdate(Position pos) {
    final newCenter = LatLng(pos.latitude, pos.longitude);
    if (isFollowingUser) {
      center = newCenter;
      notifyListeners();
    }
  }
  
  void _useDefaultLocation() {
    final regions = {
      'taipei': const LatLng(25.0330, 121.5654),
      'newTaipei': const LatLng(25.0333, 121.5654),
      'taoyuan': const LatLng(24.8333, 121.3000),
      'kaohsiung': const LatLng(22.6273, 120.3014),
    };
    center = regions[currentRegion] ?? const LatLng(22.6273, 120.3014);
    lastKnownLocation = center;
    isFollowingUser = false;
    hasObtainedRealLocation = false;
  }
  
  Future<void> refreshStations() async {
    addLog("Refreshing stations for $currentRegion...");
    try {
      final api = ApiService();
      final baseStations = await api.fetchAllStations();
      
      // FIX: Strictly limit real-time data to first 10 stations to mimic web's logic and avoid API failure
      List<String> idsToQuery = baseStations.take(10).map((s) => s.id).toList();
      final realtimeData = await api.fetchRealtimeVehicles(idsToQuery);
      
      allStations = baseStations.map((s) {
        final vehicleInfo = realtimeData[s.id];
        if (vehicleInfo != null && vehicleInfo is Map) {
          s.availableBikes = vehicleInfo['available_2_0'] ?? 0;
          s.availableElectricBikes = vehicleInfo['available_e'] ?? 0;
          s.emptySpaces = vehicleInfo['empty_spaces'] ?? 0;
          s.totalBikes = s.availableBikes + s.emptySpaces;
        } else {
          s.availableBikes = 0;
          s.availableElectricBikes = 0;
          s.emptySpaces = 0;
        }
        return s;
      }).toList();
      
      stationMarkers = _generateVisualMarkers(allStations);
      addLog("Successfully loaded and merged ${allStations.length} stations.");
      notifyListeners();
    } catch (e) {
      addLog("refreshStations Error: $e");
    }
  }
  
  List<fm.Marker> _generateVisualMarkers(List<Station> stations) {
    final Map<String, int> anchors = {};
    final List<fm.Marker> markers = [];
    for (var s in stations) {
      double lat = s.lat;
      double lng = s.lng;
      final key = "${lat.toStringAsFixed(5)},${lng.toStringAsFixed(5)}";
      if (anchors.containsKey(key)) {
        int count = anchors[key]!;
        anchors[key] = count + 1;
        const double angleStep = 2.399; 
        const double baseRadius = 0.00010;
        final angle = count * angleStep;
        final radius = baseRadius + (count * 0.00002);
        lat += radius * (math.cos(angle));
        lng += radius * (math.sin(angle));
      } else {
        anchors[key] = 1;
      }
      markers.add(fm.Marker(
        point: LatLng(lat, lng),
        width: 24, // FIX: Increased size (was 17)
        height: 24,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFFD700),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
          ),
          child: const Center(child: Icon(Icons.directions_bike, color: Colors.white, size: 14)),
        ),
      ));
    }
    return markers;
  }
  
  void searchStations(String query) {
    addLog("Searching for: $query");
    if (query.isEmpty) {
      searchResults = [];
      notifyListeners();
      return;
    }
    searchResults = allStations.where((s) {
      return s.nameTw.contains(query) || s.addressTw.contains(query);
    }).toList();
    addLog("Search found ${searchResults.length} results.");
    notifyListeners();
  }
  
  List<Station> getSortedStations(List<Station> stations, LatLng userPos) {
    if (stations.isEmpty) return [];
    List<Station> sorted = List.from(stations);
    sorted.sort((a, b) {
      bool aPinned = pinnedStationIds.contains(a.id);
      bool bPinned = pinnedStationIds.contains(b.id);
      if (aPinned && !bPinned) return -1;
      if (!aPinned && bPinned) return 1;
      double distA = Geolocator.distanceBetween(userPos.latitude, userPos.longitude, a.lat, a.lng);
      double distB = Geolocator.distanceBetween(userPos.latitude, userPos.longitude, b.lat, b.lng);
      return distA.compareTo(distB);
    });
    return sorted;
  }
  
  void togglePinStation(String stationId) async {
    if (pinnedStationIds.contains(stationId)) {
      pinnedStationIds.remove(stationId);
    } else {
      pinnedStationIds.add(stationId);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('pinnedStations', pinnedStationIds.toList());
    addLog("Toggled pin: $stationId");
    notifyListeners();
  }
  
  void toggleFollowing() {
    isFollowingUser = !isFollowingUser;
    addLog("Following user: $isFollowingUser");
    notifyListeners();
  }
  
  void toggleDarkMode() {
    isDarkMode = !isDarkMode;
    saveSetting('isDarkMode', isDarkMode);
    addLog("Dark mode toggle: $isDarkMode");
    notifyListeners();
  }
  
  void toggleLanguage() {
    currentLang = currentLang == 'zh' ? 'en' : 'zh';
    saveSetting('currentLang', currentLang);
    addLog("Language toggle: $currentLang");
    notifyListeners();
  }
  
  void setRegion(String region) {
    currentRegion = region;
    saveSetting('currentRegion', region);
    _useDefaultLocation();
    refreshStations();
    addLog("Region set to: $region");
    notifyListeners();
  }
  
  String getDistanceLabel(Station s) {
    if (!hasObtainedRealLocation) return "N/A";
    double dist = Geolocator.distanceBetween(
      center.latitude, center.longitude, s.lat, s.lng);
    if (dist < 100) return "${(dist).round()}m";
    if (dist < 1000) return "${(dist / 100).toStringAsFixed(1)}km";
    return "${(dist / 1000).toStringAsFixed(1)}km";
  }
}
