import 'dart:async';
import 'package:flutter/material.dart';

import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/station.dart';
import '../services/api_service.dart';

import '../widgets/app_theme.dart';

class AppState extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  // --- Config 翻譯 (來自 config.js) ---
  static const Map<String, LatLng> regionCoordinates = {
    'taipei': LatLng(25.047924, 121.517081),
    'newTaipei': LatLng(25.0215339197085, 121.4568090197085),
    'taoyuan': LatLng(24.953671, 121.225783),
    'hsinchuCounty': LatLng(24.826917615712, 121.01290295049),
    'hsinchuCity': LatLng(24.801815, 120.971459),
    'sciencePark': LatLng(24.781830, 121.005074),
    'miaoli': LatLng(24.5648599, 120.8185503),
    'taichung': LatLng(24.154712, 120.664265),
    'chiayi': LatLng(23.4797837, 120.4397206),
    'tainan': LatLng(22.99230083082, 120.18509419659),
    'kaohsiung': LatLng(22.631442, 120.301890),
    'pingtung': LatLng(22.683036253664, 120.48790854724),
    'taitung': LatLng(22.755711056126138, 121.15035332587574),
  };

  // --- State 翻譯 (來自 config.js / main.js) ---
  String _currentRegion = 'kaohsiung';
  String _currentLang = 'zh';
  bool _isDarkMode = false;
  bool _isFollowingUser = false;
  LatLng? _customCenter;
  
  List<Station> _allStations = [];
  List<Station> _searchResults = [];
  List<Marker> _stationMarkers = [];
  
  int _countdown = 60;
  Timer? _refreshTimer;
  bool _isLoading = true;

  // Getters
  String get currentRegion => _currentRegion;
  String get currentLang => _currentLang;
  bool get isDarkMode => _isDarkMode;
  bool get isFollowingUser => _isFollowingUser;
  List<Station> get searchResults => _searchResults;
  List<Marker> get stationMarkers => _stationMarkers;
  int get countdown => _countdown;
  bool get isLoading => _isLoading;
  LatLng get center => _currentRegion == 'custom' 
      ? (_customCenter ?? regionCoordinates['kaohsiung']!) 
      : (regionCoordinates[_currentRegion] ?? regionCoordinates['kaohsiung']!);

  AppState() {
    _initSettings();
    _startRefreshCycle();
  }

  Future<void> _initSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _currentLang = prefs.getString('lang') ?? 'zh';
    _isDarkMode = prefs.getBool('darkMode') ?? false;
    await loadBaseStations();
    notifyListeners();
  }

  // 翻譯自 main.js: initializeApp -> fetchBaseStationData
  Future<void> loadBaseStations() async {
    _isLoading = true;
    notifyListeners();
    try {
      _allStations = await _apiService.fetchAllStations();
      await updateRealtimeData();
      _generateMarkers();
    } catch (e) {
      debugPrint("Error loading stations: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 翻譯自 apiYoubike.js: queryVehicleData
  Future<void> updateRealtimeData() async {
    try {
      final data = await _apiService.fetchRealtimeVehicles();
      for (var station in _allStations) {
        if (data.containsKey(station.id)) {
          station.updateRealtimeData(data[station.id]);
        }
      }
      _generateMarkers();
      notifyListeners();
    } catch (e) {
      debugPrint("Error updating vehicle data: $e");
    }
  }

  // 翻譯自 mapService.js: renderMarkers
  void _generateMarkers() {
    _stationMarkers = _allStations.map((s) {
      return Marker(
        point: LatLng(s.lat, s.lng),
        width: 30,
        height: 30,
        child: const Icon(
          Icons.directions_bike, 
          color: AppColors.primary, 
          size: 30,
          shadows: [Shadow(blurRadius: 2, color: Colors.black26)],
        ),
      );
    }).toList();
  }

  // 翻譯自 main.js: 搜尋邏輯
  void searchStations(String query) {
    if (query.trim().isEmpty) {
      _searchResults = [];
    } else {
      _searchResults = _allStations.where((s) {
        final q = query.toLowerCase();
        return s.nameTw.contains(q) || 
               s.addressTw.contains(q) || 
               s.nameEn.toLowerCase().contains(q) || 
               s.addressEn.toLowerCase().contains(q);
      }).toList();
    }
    notifyListeners();
  }

  void focusStation(Station station) {
    // In a real app, you'd use a MapController to move the camera.
    // For now, we'll just update the center to the station's position.
    _currentRegion = 'custom'; // mark as custom center
    // Note: For actual map moving, we'd need a MapController reference.
    notifyListeners();
  }

  Future<void> updateUserLocation() async {
    // Mocking the location update as LocationService is defined but not integrated into AppState yet
    // In full implementation, we'd inject LocationService here.
    debugPrint("Updating user location...");
    _isFollowingUser = true;
    notifyListeners();
  }

  // Settings Updates
  void _startRefreshCycle() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      _countdown--;
      if (_countdown <= 0) {
        _countdown = 60;
        await updateRealtimeData();
      }
      notifyListeners();
    });
  }

  // Settings Updates
  void setRegion(String region) {
    _currentRegion = region;
    notifyListeners();
  }

  void setLanguage(String lang) async {
    _currentLang = lang;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lang', lang);
    notifyListeners();
  }

  void toggleDarkMode(bool value) async {
    _isDarkMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', value);
    notifyListeners();
  }

  void setFollowingUser(bool value) {
    _isFollowingUser = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}
