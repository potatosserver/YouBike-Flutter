import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';

import '../models/station.dart';
import '../services/api_service.dart';
import '../services/language_service.dart';
import '../services/location_service.dart';
import '../widgets/app_theme.dart';

class AppState extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final LocationService _locationService = LocationService();
  
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
    'custom': LatLng(22.631442, 120.301890),
  };

  String _currentRegion = 'kaohsiung';
  String _currentLang = 'zh';
  bool _isDarkMode = false;
  bool _isFollowingUser = false;
  LatLng? _customCenter;
  
  List<Station> _allStations = [];
  List<Station> _searchResults = [];
  List<Marker> _stationMarkers = [];
  bool _showOnlyAvailable = false; // 翻譯自 JS 的過濾邏輯
  
  int _countdown = 60;
  Timer? _refreshTimer;
  bool _isLoading = true;
  StreamSubscription<Position>? _locationSubscription;

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

  bool get showOnlyAvailable => _showOnlyAvailable;

  void toggleAvailableOnly(bool value) {
    _showOnlyAvailable = value;
    _generateMarkers();
    notifyListeners();
  }

  void _generateMarkers() {
    _stationMarkers = _allStations.where((s) {
      if (_showOnlyAvailable) {
        return (s.availableBikes + s.availableElectricBikes) > 0;
      }
      return true;
    }).map((s) {
      return Marker(
        point: LatLng(s.lat, s.lng),
        width: 36,
        height: 36,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            Icons.directions_bike, 
            color: Colors.white, 
            size: 20,
          ),
        ),
      );
    }).toList();
  }

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
    _currentRegion = 'custom';
    _customCenter = LatLng(station.lat, station.lng);
    notifyListeners();
  }

  // 模仿 locationTracker.js: 實作即時追蹤
  Future<void> toggleUserTracking(bool enable) async {
    _isFollowingUser = enable;
    if (enable) {
      try {
        final status = await _locationService.requestPermission();
        if (status == LocationPermissionStatus.granted) {
          // 開始監聽位置流
          _locationSubscription?.cancel();
          _locationSubscription = _locationService.getPositionStream().listen((position) {
            _currentRegion = 'custom';
            _customCenter = LatLng(position.latitude, position.longitude);
            notifyListeners();
          });
        } else {
          _isFollowingUser = false;
          // 這裡會在 UI 層觸發 PermissionModal
        }
      } catch (e) {
        _isFollowingUser = false;
        debugPrint("Location error: $e");
      }
    } else {
      _locationSubscription?.cancel();
    }
    notifyListeners();
  }

  // 保留此方法以兼容舊版 UI 呼叫，但內部導向 toggleUserTracking
  Future<void> updateUserLocation() async {
    await toggleUserTracking(true);
  }

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

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _locationSubscription?.cancel();
    super.dispose();
  }
}
