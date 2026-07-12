import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/station.dart';
import '../services/api_service.dart';
import 'notification_service.dart';
import 'location_service.dart';

class AppState extends ChangeNotifier {
  LatLng? center;
  LatLng? lastKnownLocation;
  bool isFollowing = false;
  bool isFollowingUser = false;

  List<Station> _fullStationList = []; 
  List<Station> get fullStations => _fullStationList;
  List<Station> allStations = [];
  List<Station> get filteredStations => allStations;
  Set<String> pinnedStationIds = {};

  bool _isLoading = true;
  bool get isLoading => _isLoading;
  set isLoading(bool value) {
    if (value == false && _initStartTime != null) {
      final elapsed = DateTime.now().difference(_initStartTime!).inMilliseconds;
      if (elapsed < 1500) {
        Future.delayed(Duration(milliseconds: 1500 - elapsed), () {
          _isLoading = false;
          notifyListeners();
        });
        return;
      }
    }
    if (_isInitialLoadComplete && value == true) return;
    _isLoading = value;
    notifyListeners();
  }

  bool _isInitialLoadComplete = false;
  DateTime? _initStartTime; 
  int loadingProgress = 0;
  String currentNotice = "init_starting";
  String loadingNotice = "";
  List<String> logs = [];
  bool isUpdating = false; 
  int countdownRemaining = 60;
  bool isOffline = false; 
  String selectedRegion = 'kaohsiung';
  String currentLang = 'zh_TW';
  bool useLocation = true;
  LatLng? initialSnapPoint;
  bool hasObtainedRealLocation = false;
  final ValueNotifier<double> panelHeightNotifier = ValueNotifier(300.0);

  // _log method removed as it was unused


  Future<LocationPermissionStatus> requestPermission() async {
    return await LocationService().requestPermission();
  }

  Future<Position?> getCurrentPosition() async {
    return await LocationService().getCurrentPosition();
  }

  String getDistanceLabel(double distance) {
    return distance < 1000 ? "${distance.toStringAsFixed(0)}m" : "${(distance / 1000).toStringAsFixed(1)}km";
  }

  final Map<String, Map<String, dynamic>> _regions = {
    "taipei": {"name": "region_taipei", "lat": 25.047924, "lng": 121.517081},
    "newTaipei": {"name": "region_new_taipei", "lat": 25.0215339197085, "lng": 121.4568090197085},
    "taoyuan": {"name": "region_taoyuan", "lat": 24.953671, "lng": 121.225783},
    "hsinchuCounty": {"name": "region_hsinchu_county", "lat": 24.826917615712, "lng": 121.01290295049},
    "hsinchuCity": {"name": "region_hsinchu_city", "lat": 24.801815, "lng": 120.971459},
    "sciencePark": {"name": "region_science_park", "lat": 24.781830, "lng": 121.005074},
    "miaoli": {"name": "region_miaoli", "lat": 24.5648599, "lng": 120.8185503},
    "taichung": {"name": "region_taichung", "lat": 24.154712, "lng": 120.664265},
    "chiayi": {"name": "region_chiayi", "lat": 23.4797837, "lng": 120.4397206},
    "tainan": {"name": "region_tainan", "lat": 22.99230083082, "lng": 120.18509419659},
    "kaohsiung": {"name": "region_kaohsiung", "lat": 22.631442, "lng": 120.301890},
    "pingtung": {"name": "region_pingtung", "lat": 22.683036253664, "lng": 120.48790854724},
    "taitung": {"name": "region_taitung", "lat": 22.755711056126138, "lng": 121.15035332587574},
  };
  Map<String, Map<String, dynamic>> get regions => _regions;

  LatLng getEffectiveLocation() {
    if (lastKnownLocation != null) return lastKnownLocation!;
    if (center != null) return center!;
    final region = _regions[selectedRegion] ?? _regions['kaohsiung']!;
    return LatLng(region['lat'] as double, region['lng'] as double);
  }

  List<Station> _applyPrioritySort(List<Station> stations) {
    final referencePoint = lastKnownLocation ?? getEffectiveLocation();
    
    // 1. Sort by distance first
    final sortedByDist = List<Station>.from(stations);
    sortedByDist.sort((a, b) {
      final distA = _calculateDistance(referencePoint.latitude, referencePoint.longitude, a.lat, a.lng);
      final distB = _calculateDistance(referencePoint.latitude, referencePoint.longitude, b.lat, b.lng);
      return distA.compareTo(distB);
    });

    // 2. Separate Pinned vs Normal
    final pinned = sortedByDist.where((s) => pinnedStationIds.contains(s.id.trim())).toList();
    final normal = sortedByDist.where((s) => !pinnedStationIds.contains(s.id.trim())).toList();

    return [...pinned, ...normal];
  }

  void togglePinStation(String stationId) {
    final id = stationId.trim();
    if (pinnedStationIds.contains(id)) {
      pinnedStationIds.remove(id);
    } else {
      pinnedStationIds.add(id);
    }
    _prefs?.setStringList('pinnedStations', pinnedStationIds.toList());
    
    // CRITICAL: Re-sort the current list so the card jumps to the top/bottom immediately
    if (allStations.isNotEmpty) {
      allStations = _applyPrioritySort(allStations);
    }
    
    notifyListeners();
  }

  void startTracking() {
    if (_locationSubscription != null) return;
    stopTracking();
    _locationSubscription = Geolocator.getPositionStream(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10)).listen((pos) {
      lastKnownLocation = LatLng(pos.latitude, pos.longitude);
      center = lastKnownLocation!;
      if (isFollowing) notifyListeners();
      for (var s in allStations) { s.distance = _calculateDistance(center!.latitude, center!.longitude, s.lat, s.lng); }
      notifyListeners();
    });
    NotificationService.instance.show(message: "tracking_enabled", type: NotificationType.success);
  }

  void stopTracking() {
    _locationSubscription?.cancel();
    _locationSubscription = null;
  }

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    currentLang = _prefs?.getString('currentLang') ?? 'zh_TW';
    selectedRegion = _prefs?.getString('selectedRegion') ?? 'kaohsiung';
    useLocation = _prefs?.getBool('useLocation') ?? true;
    final pinnedList = _prefs?.getStringList('pinnedStations') ?? [];
    pinnedStationIds = pinnedList.map((id) => id.trim()).toSet();
    final cachedLat = _prefs?.getDouble('last_lat');
    final cachedLng = _prefs?.getDouble('last_lng');
    if (cachedLat != null && cachedLng != null) { center = LatLng(cachedLat, cachedLng); lastKnownLocation = center; }
    else { center = getEffectiveLocation(); lastKnownLocation = center; }
    final cachedStationsJson = _prefs?.getString('cached_stations');
    if (cachedStationsJson != null) { try { final List<dynamic> decoded = jsonDecode(cachedStationsJson); _fullStationList = decoded.map((item) => Station.fromJson(item as Map<String, dynamic>)).whereType<Station>().toList(); } catch(e) { debugPrint("Cache load error: $e"); } }
    _monitorConnectivity();
    await _runOptimizedInit();
    startAutoRefreshCycle();
    countdownRemaining = 60;
    _startCountdownTimer();
    isLoading = false;
    notifyListeners();
  }
  Future<void> _runOptimizedInit() async {
    _initStartTime = DateTime.now();
    isLoading = true;
    _simulateRandomNotices();
    _simulatePercentage();
    try {
      _initializeLocation().then((_) { refreshStations(isInitial: false, reason: "INIT_GPS"); });
      final cachedStationsJson = _prefs?.getString('cached_stations');
      if (cachedStationsJson != null) {
        try {
          final List<dynamic> decoded = jsonDecode(cachedStationsJson);
          _fullStationList = decoded.map((item) => Station.fromJson(item as Map<String, dynamic>)).whereType<Station>().toList();
          currentNotice = "init_updating"; notifyListeners();
          refreshStations(isInitial: true, reason: "INIT_CACHE");
          isLoading = false; _isInitialLoadComplete = true; loadingProgress = 100; currentNotice = "init_success";
          notifyListeners(); return;
        } catch (e) { debugPrint("Cache load error: $e. Falling back to network."); }
      }
      currentNotice = "init_syncing"; notifyListeners();
      await fetchBaseData();
      currentNotice = "init_updating"; notifyListeners();
      await refreshStations(isInitial: true, reason: "INIT_NETWORK");
    } catch (e) { addLog("init_error $e", isError: true); }
    finally { _isInitialLoadComplete = true; loadingProgress = 100; currentNotice = "init_success"; if (isLoading) isLoading = false; notifyListeners(); }
  }

  Future<void> _initializeLocation() async {
    try {
      final pos = await getCurrentPosition();
      if (pos != null) {
        lastKnownLocation = LatLng(pos.latitude, pos.longitude);
        center = lastKnownLocation!;
        initialSnapPoint = center;
        _prefs?.setDouble('last_lat', lastKnownLocation!.latitude);
        _prefs?.setDouble('last_lng', lastKnownLocation!.longitude);
        hasObtainedRealLocation = true;
      } else if (lastKnownLocation != null) {
        center = lastKnownLocation!;
        initialSnapPoint = center;
      } else {
        final region = _regions[selectedRegion] ?? _regions['kaohsiung']!;
        center = LatLng(region['lat'] as double, region['lng'] as double);
        lastKnownLocation = center;
        initialSnapPoint = center;
      }
    } catch (e) {
      if (lastKnownLocation != null) { center = lastKnownLocation!; initialSnapPoint = center; }
      else { final region = _regions[selectedRegion] ?? _regions['kaohsiung']!; center = LatLng(region['lat'] as double, region['lng'] as double); lastKnownLocation = center; initialSnapPoint = center; }
    }
  }

  Future<void> fetchBaseData() async {
    try {
      final api = ApiService();
      final freshData = await api.fetchAllStations();
      if (freshData.isNotEmpty) {
        _fullStationList = freshData;
        final cacheData = jsonEncode(_fullStationList.map((s) => s.toJson()).toList());
        await _prefs?.setString('cached_stations', cacheData);
      }
    } catch (e) { addLog("基礎數據獲取失敗: $e", isError: true); }
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000;
    final double dLat = (lat2 - lat1) * math.pi / 180;
    final double dLon = (lon2 - lon1) * math.pi / 180;
    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) + math.cos(lat1 * math.pi / 180) * math.cos(lat2 * math.pi / 180) * math.sin(dLon / 2) * math.sin(dLon / 2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  Future<void> refreshStations({bool isInitial = false, String reason = "UNKNOWN"}) async {
    if (_refreshFuture != null) return _refreshFuture;
    if (!isInitial && _lastRefreshTime != null) {
      final diff = DateTime.now().difference(_lastRefreshTime!).inSeconds;
      if (diff < 2) return;
    }
    _refreshFuture = _performRefresh(isInitial, reason);
    try { await _refreshFuture; } finally { _refreshFuture = null; }
  }

  Future<void> _performRefresh(bool isInitial, String reason) async {
    if (!isInitial) {
      countdownRemaining = 60;
      isUpdating = false; 
      _startCountdownTimer();
      notifyListeners();
    }
    try {
      final api = ApiService();
      if (_fullStationList.isEmpty) _fullStationList = await api.fetchAllStations();
      LatLng referencePoint = lastKnownLocation ?? getEffectiveLocation();
      await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high)).then((pos) {
        lastKnownLocation = LatLng(pos.latitude, pos.longitude);
        hasObtainedRealLocation = true;
        for (var s in allStations) { s.distance = _calculateDistance(lastKnownLocation!.latitude, lastKnownLocation!.longitude, s.lat, s.lng); }
        notifyListeners();
      });
      final sorted = List<Station>.from(_fullStationList);
      sorted.sort((a, b) {
        final distA = _calculateDistance(referencePoint.latitude, referencePoint.longitude, a.lat, a.lng);
        final distB = _calculateDistance(referencePoint.latitude, referencePoint.longitude, b.lat, b.lng);
        return distA.compareTo(distB);
      });
      allStations = _applyPrioritySort(sorted).take(10).toList();
      for (var s in allStations) { s.distance = _calculateDistance(referencePoint.latitude, referencePoint.longitude, s.lat, s.lng); }
      final vehicleData = await api.fetchRealtimeVehicles(allStations.map((s) => s.id).toList());
      for (var s in allStations) { if (vehicleData.containsKey(s.id)) { final data = vehicleData[s.id] as Map<String, dynamic>; s.availableBikes = data['available_2_0'] ?? 0; s.availableElectricBikes = data['available_e'] ?? 0; s.emptySpaces = data['empty_spaces'] ?? 0; } }
      _lastRefreshTime = DateTime.now();
    } catch (e) { addLog("refresh_error $e", isError: true); }
    finally { if (!isInitial) { isUpdating = false; notifyListeners(); } }
  }

  void addLog(String message, {bool isError = false}) {
    logs.add("${_getTimestamp()} ${isError ? '[ERROR] ' : '[INFO] '} $message");
    if (logs.length > 100) logs.removeAt(0);
    notifyListeners();
  }

  String _getTimestamp() {
    final now = DateTime.now();
    return "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}.${now.millisecond.toString().padLeft(3, '0')}";
  }

  void _monitorConnectivity() {
    Connectivity().onConnectivityChanged.listen((event) {
      isOffline = (event.contains(ConnectivityResult.none));
      notifyListeners();
    });
  }

  void _simulateRandomNotices() {
    final notices = ['init_checking_api', 'init_verifying_cache', 'init_loading_stations', 'init_syncing_gps'];
    Timer.periodic(const Duration(milliseconds: 300), (timer) {
      if (_isInitialLoadComplete) { timer.cancel(); return; }
      currentNotice = notices[math.Random().nextInt(notices.length)];
      notifyListeners();
    });
  }

  void _simulatePercentage() {
    Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_isInitialLoadComplete) { timer.cancel(); return; }
      loadingProgress += 5;
      if (loadingProgress > 95) loadingProgress = 95;
      notifyListeners();
    });
  }

  void setLanguage(String lang) { currentLang = lang; _prefs?.setString('currentLang', lang); notifyListeners(); }
  void setRegion(String region) { selectedRegion = region; _prefs?.setString('selectedRegion', region); notifyListeners(); }
  void setUseLocation(bool use) { useLocation = use; _prefs?.setBool('useLocation', use); notifyListeners(); }
  void searchStations(String query) {
    if (query.isEmpty) { 
      allStations = _applyPrioritySort(_fullStationList).take(10).toList(); 
      notifyListeners(); 
      return; 
    }
    final filtered = _fullStationList.where((s) => s.nameTw.contains(query) || s.nameEn.contains(query)).toList();
    allStations = _applyPrioritySort(filtered).take(10).toList();
    notifyListeners();
  }

  void _startCountdownTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (countdownRemaining > 0) {
        countdownRemaining--;
        notifyListeners();
      } else {
        timer.cancel();
      }
    });
  }

  void startAutoRefreshCycle() {
    Timer.periodic(const Duration(minutes: 1), (timer) {
      refreshStations(isInitial: false, reason: "AUTO_REFRESH");
    });
  }

  Timer? _countdownTimer;
  Future<void>? _refreshFuture; 
  DateTime? _lastRefreshTime;
  StreamSubscription<Position>? _locationSubscription;
  SharedPreferences? _prefs;
}
