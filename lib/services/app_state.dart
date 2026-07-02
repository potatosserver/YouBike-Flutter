import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
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
  
  // --- Pinned Stations ---
  Set<String> pinnedStationIds = {};

  // --- Location State ---
  LatLng center = const LatLng(22.6273, 120.3014); 
  bool isFollowingUser = false;
  bool hasObtainedRealLocation = false;
  bool isLoading = true;
  
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
  }

  Future<void> _init() async {
    addLog("Initializing AppState...");
    try {
      await loadSettings();
      initializeLocation(); 
      refreshStations();
    } catch (e) {
      addLog("Critical Init Error: $e");
    } finally {
      isLoading = false;
      addLog("Initial UI ready.");
      notifyListeners();
    }
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
    if (value is String) await prefs.setString(key, value);
    else if (value is bool) await prefs.setBool(key, value);
    addLog("Setting saved: $key = $value");
  }

  // --- Location Methods ---

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
    isFollowingUser = false;
    hasObtainedRealLocation = false;
  }

  // --- Station Logic (DEEP MERGE IMPLEMENTATION) ---
  
  Future<void> refreshStations() async {
    addLog("Refreshing stations for $currentRegion...");
    try {
      final api = ApiService();
      
      // 1. Fetch Base Station Data (Name, Address, Lat/Lng)
      final baseStations = await api.fetchAllStations();
      
      // 2. Fetch Real-time Vehicle Data (Bike counts)
      final realtimeData = await api.fetchRealtimeVehicles();
      
      // 3. MERGE DATA (Mirrors web apiYoubike.js)
      allStations = baseStations.map((s) {
        final vehicleInfo = realtimeData[s.id];
        if (vehicleInfo != null && vehicleInfo is Map) {
          s.availableBikes = int.tryParse(vehicleInfo['available']?.toString() ?? '0') ?? 0;
          s.availableElectricBikes = int.tryParse(vehicleInfo['available_e']?.toString() ?? '0') ?? 0;
          s.emptySpaces = int.tryParse(vehicleInfo['empty']?.toString() ?? '0') ?? 0;
          s.totalBikes = s.availableBikes + s.emptySpaces;
        }
        return s;
      }).toList();
      
      // 4. Generate Markers (Now with guaranteed data)
      stationMarkers = allStations.map((s) => fm.Marker(
        point: LatLng(s.lat, s.lng),
        width: 30,
        height: 30,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.red,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
          ),
          child: const Center(child: Icon(Icons.location_on, color: Colors.white, size: 20)),
        ),
      )).toList();
      
      addLog("Successfully loaded and merged ${allStations.length} stations.");
      notifyListeners();
    } catch (e) {
      addLog("refreshStations Error: $e");
    }
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
  }
}
